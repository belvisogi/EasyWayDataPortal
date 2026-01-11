param(
  [string]$Path = "wiki",
  [string[]]$ExcludePaths = @('logs', 'old', '.attachments'),
  [string]$ScopesPath = "config/scopes.json",
  [string]$ScopeName = "",
  [string]$SummaryOut = "out/gap.json",
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Json([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { throw "JSON not found: $p" }
  return (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json)
}

function Resolve-ExcludePrefixes([string]$Root, [string[]]$Exclude) {
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $out = @()
  foreach ($e in $Exclude) {
    if ([string]::IsNullOrWhiteSpace($e)) { continue }
    $candidate = $e
    if (-not [System.IO.Path]::IsPathRooted($candidate)) { $candidate = Join-Path $rootFull $candidate }
    try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
    if (-not $full.EndsWith([System.IO.Path]::DirectorySeparatorChar)) { $full = $full + [System.IO.Path]::DirectorySeparatorChar }
    $out += $full
  }
  return $out
}

function Is-Excluded([string]$FullName, [string[]]$Prefixes) {
  foreach ($p in $Prefixes) { if ($FullName.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true } }
  return $false
}

function Get-RelPath([string]$Root, [string]$FullName) {
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  return $full.Substring($rootFull.Length).TrimStart('/',[char]92).Replace([char]92,'/')
}

function Load-ScopeEntries([string]$ScopesPath, [string]$ScopeName) {
  if ([string]::IsNullOrWhiteSpace($ScopeName)) { return @() }
  $obj = Read-Json $ScopesPath
  $scope = $obj.scopes.$ScopeName
  if ($null -eq $scope) { throw "Scope not found in ${ScopesPath}: $ScopeName" }
  return @($scope)
}

function Is-InScope([string]$RelPath, [string[]]$ScopeEntries) {
  if ($null -eq $ScopeEntries -or $ScopeEntries.Count -eq 0) { return $true }
  foreach ($e in $ScopeEntries) {
    $p = [string]$e
    if (-not $p) { continue }
    $p = $p.Replace('\\','/')
    if ($p.EndsWith('/')) { if ($RelPath.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true } }
    else { if ($RelPath.Equals($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true } }
  }
  return $false
}

function Extract-Fm([string]$Text) {
  $m = [regex]::Match($Text, '^(---\r?\n)(?<fm>.*?)(\r?\n---\r?\n)', 'Singleline')
  if (-not $m.Success) { return $null }
  return $m.Groups['fm'].Value
}

function Get-FmValue([string]$FrontMatter, [string]$Key) {
  if (-not $FrontMatter) { return '' }
  $m = [regex]::Match($FrontMatter, "(?m)^$([regex]::Escape($Key))\s*:\s*(?<v>.*)$")
  if (-not $m.Success) { return '' }
  return ($m.Groups['v'].Value).Trim()
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$scopeEntries = Load-ScopeEntries -ScopesPath $ScopesPath -ScopeName $ScopeName

$results = New-Object System.Collections.Generic.List[object]
$files = Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.md' | Where-Object { -not (Is-Excluded $_.FullName $excludePrefixes) }
foreach ($f in $files) {
  $rel = Get-RelPath -Root $Path -FullName $f.FullName
  if (-not (Is-InScope -RelPath $rel -ScopeEntries $scopeEntries)) { continue }
  $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Extract-Fm $text
  if ($null -eq $fm) { $results.Add([pscustomobject]@{ file=$rel; ok=$false; issues=@('missing_front_matter') }) ; continue }
  $issues = New-Object System.Collections.Generic.List[string]
  if ([string]::IsNullOrWhiteSpace((Get-FmValue $fm 'owner'))) { $issues.Add('missing_owner') }
  if ([string]::IsNullOrWhiteSpace((Get-FmValue $fm 'summary'))) { $issues.Add('missing_summary') }
  $ok = ($issues.Count -eq 0)
  $results.Add([pscustomobject]@{ file=$rel; ok=$ok; issues=@($issues.ToArray()) })
}

$arr = @($results.ToArray())
$fail = @($arr | Where-Object { -not $_.ok })
$summary = [pscustomobject]@{ ok=($fail.Count -eq 0); files=$arr.Count; failures=$fail.Count; results=$arr }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $SummaryOut) | Out-Null
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }

