param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [string[]]$DisallowedTitles = @('index','indice','indici'),
  [string[]]$DisallowedSummaryPrefixes = @('Documento su'),
  [switch]$IncludeFullPath,
  [switch]$FailOnError,
  [string]$SummaryOut = "wiki-index-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Read-Json($p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Resolve-ExcludePrefixes {
  param([string]$Root, [string[]]$Exclude)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $out = @()
  foreach ($e in $Exclude) {
    if ([string]::IsNullOrWhiteSpace($e)) { continue }
    $candidate = $e
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
      $candidate = Join-Path $rootFull $candidate
    }
    try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
    if (-not $full.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
      $full = $full + [System.IO.Path]::DirectorySeparatorChar
    }
    $out += $full
  }
  return $out
}

function Is-Excluded {
  param([string]$FullName, [string[]]$Prefixes)
  foreach ($p in $Prefixes) {
    if ($FullName.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

function Get-RelPath {
  param([string]$Root, [string]$FullName)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  $rel = $full.Substring($rootFull.Length).TrimStart('/',[char]92)
  return $rel.Replace([char]92,'/')
}

function Load-ScopeEntries {
  param([string]$ScopesPath, [string]$ScopeName)
  if ([string]::IsNullOrWhiteSpace($ScopeName)) { return @() }
  $obj = Read-Json $ScopesPath
  $scope = $obj.scopes.$ScopeName
  if ($null -eq $scope) { throw "Scope not found in ${ScopesPath}: $ScopeName" }
  if ($scope -is [string]) { return @($scope) }
  return @($scope | ForEach-Object { $_ })
}

function Is-InScope {
  param([string]$RelPath, [string[]]$ScopeEntries)
  if ($null -eq $ScopeEntries -or $ScopeEntries.Count -eq 0) { return $true }
  foreach ($e in $ScopeEntries) {
    $p = [string]$e
    if (-not $p) { continue }
    $p = $p.Replace('\\','/')
    if ($p.EndsWith('/')) {
      if ($RelPath.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    } else {
      if ($RelPath.Equals($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
  }
  return $false
}

function Extract-FrontMatter {
  param([string]$Text)
  $m = [regex]::Match($Text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $m.Success) { return $null }
  return $m.Groups['fm'].Value
}

function Extract-FmValue {
  param([string]$FrontMatter, [string]$Key)
  if (-not $FrontMatter) { return '' }
  $m = [regex]::Match($FrontMatter, "(?m)^${Key}\\s*:\\s*(?<v>.*)$")
  if (-not $m.Success) { return '' }
  $v = ($m.Groups['v'].Value).Trim()
  if (($v.StartsWith("'") -and $v.EndsWith("'")) -or ($v.StartsWith('"') -and $v.EndsWith('"'))) {
    $v = $v.Substring(1, $v.Length - 2)
  }
  return $v.Trim()
}

function Is-DisallowedTitle {
  param([string]$Title, [string[]]$DisallowedTitles)
  if ([string]::IsNullOrWhiteSpace($Title)) { return $true }
  $t = $Title.Trim().ToLowerInvariant()
  foreach ($d in $DisallowedTitles) {
    if (-not $d) { continue }
    if ($t -eq $d.Trim().ToLowerInvariant()) { return $true }
  }
  return $false
}

function Is-KebabCase {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
  return [regex]::IsMatch($Text, '^[a-z0-9]+(?:-[a-z0-9]+)*$')
}

function Is-PlaceholderSummary {
  param([string]$Summary, [string[]]$Prefixes)
  if ([string]::IsNullOrWhiteSpace($Summary)) { return $true }
  $s = $Summary.Trim()
  foreach ($p in $Prefixes) {
    if (-not $p) { continue }
    if ($s.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  }
  return $false
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$results = @()
$files =
  Get-ChildItem -LiteralPath $Path -Recurse -Filter index.md |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) }

foreach ($f in $files) {
  $rel = Get-RelPath -Root $Path -FullName $f.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }

  $text = Get-Content -LiteralPath $f.FullName -Raw
  $fm = Extract-FrontMatter $text
  if ($null -eq $fm) {
    $r = @{ file = $rel; ok = $false; issue = 'missing_front_matter' }
    if ($IncludeFullPath) { $r.fullPath = $f.FullName }
    $results += $r
    continue
  }

  $title = Extract-FmValue -FrontMatter $fm -Key 'title'
  $summary = Extract-FmValue -FrontMatter $fm -Key 'summary'

  $issues = @()
  if (Is-DisallowedTitle -Title $title -DisallowedTitles $DisallowedTitles) { $issues += 'bad_title' }
  if (-not (Is-KebabCase -Text $title)) { $issues += 'title_not_kebab_case' }
  if (Is-PlaceholderSummary -Summary $summary -Prefixes $DisallowedSummaryPrefixes) { $issues += 'placeholder_or_missing_summary' }

  $ok = ($issues.Count -eq 0)
  $r = @{ file = $rel; ok = $ok; title = $title; summary = $summary; issues = $issues }
  if ($IncludeFullPath) { $r.fullPath = $f.FullName }
  $results += $r
}

$failures = @($results | Where-Object { -not $_.ok })
$summaryObj = @{
  ok = ($failures.Count -eq 0)
  path = $Path
  excluded = @($ExcludePaths)
  scopesPath = $ScopesPath
  scopeName = $ScopeName
  disallowedTitles = @($DisallowedTitles)
  disallowedSummaryPrefixes = @($DisallowedSummaryPrefixes)
  includeFullPath = [bool]$IncludeFullPath
  files = $results.Count
  failures = $failures.Count
  results = $results
}

$json = $summaryObj | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summaryObj.ok) { exit 1 }
