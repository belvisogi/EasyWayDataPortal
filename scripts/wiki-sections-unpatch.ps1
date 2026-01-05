param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports', 'old', '.attachments'),
  [string]$ScopesPath = "docs/agentic/templates/docs/tag-taxonomy.scopes.json",
  [string]$ScopeName = "",
  [switch]$Apply,
  [string]$SummaryOut = "wiki-sections-unpatch.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExcludePaths.Count -eq 1 -and $ExcludePaths[0] -match ',') {
  $ExcludePaths = @($ExcludePaths[0].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Read-Json([string]$p) {
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
  return @($scope)
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

function Remove-ManagedBlock {
  param([string]$Text)

  $pattern = '(?im)^##\s+Domande a cui risponde\s*$'
  $matches = [regex]::Matches($Text, $pattern)
  if ($matches.Count -eq 0) { return @{ changed = $false; text = $Text; reason = 'no_domande' } }

  $last = $matches[$matches.Count - 1]
  $startIndex = $last.Index

  $after = $Text.Substring($startIndex)
  $lines = $after -split "\r?\n", 5
  if ($lines.Count -lt 2) { return @{ changed = $false; text = $Text; reason = 'domande_no_body' } }

  $secondLine = ($lines[1]).Trim()
  if (-not ($secondLine -like '- Qual*')) { return @{ changed = $false; text = $Text; reason = 'domande_not_managed' } }

  $newText = $Text.Substring(0, $startIndex).TrimEnd() + "`n"
  return @{ changed = $true; text = $newText; reason = 'removed_managed_tail' }
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$results = @()

$files = Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.md' |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) }

foreach ($f in $files) {
  $rel = Get-RelPath -Root $Path -FullName $f.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }

  $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $res = Remove-ManagedBlock -Text $text

  if ($Apply -and $res.changed) {
    Set-Content -LiteralPath $f.FullName -Value $res.text -Encoding utf8
  }

  $results += [pscustomobject]@{
    file = $rel
    changed = [bool]$res.changed
    applied = [bool]($Apply -and $res.changed)
    reason = $res.reason
  }
}

$summary = [pscustomobject]@{
  applied = [bool]$Apply
  path = $Path
  excluded = @($ExcludePaths)
  scopesPath = $ScopesPath
  scopeName = $ScopeName
  files = $results.Count
  changed = (@($results | Where-Object { $_.changed })).Count
  results = $results
}

$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json

