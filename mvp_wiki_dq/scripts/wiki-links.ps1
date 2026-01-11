param(
  [string]$Path = "wiki",
  [string[]]$ExcludePaths = @('logs', 'old', '.attachments'),
  [string]$SummaryOut = "out/links.json",
  [switch]$FailOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-ParentDir([string]$path) {
  $dir = Split-Path -Parent $path
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
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

function Slug([string]$t) {
  if ($null -eq $t) { return '' }
  $s = $t.ToLowerInvariant()
  $s = $s -replace "[`*_~]", ''
  $s = $s -replace "\s+", '-'
  $s = $s -replace "[^a-z0-9\-]", ''
  $s = $s -replace "-+", '-'
  $s = $s -replace "^-|-$", ''
  return $s
}

function Get-HeadingsCache([string]$File) {
  $heads = @{}
  Get-Content -LiteralPath $File -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^(#+)\s+(.+)$') {
      $slug = Slug $Matches[2]
      if ($slug) { $heads[$slug] = $true }
    }
  }
  return $heads
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$issues = New-Object System.Collections.Generic.List[object]
$filesScanned = 0

$rootFull = (Resolve-Path -LiteralPath $Path).Path
$allFiles = Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md | Where-Object { -not (Is-Excluded $_.FullName $excludePrefixes) }
foreach ($f in $allFiles) {
  $filesScanned++
  $dir = Split-Path -Parent $f.FullName
  $rel = (Resolve-Path -LiteralPath $f.FullName).Path.Substring($rootFull.Length).TrimStart('/',[char]92).Replace([char]92,'/')
  $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $matches = [regex]::Matches($content, "\[[^\]]*\]\(([^\)]+)\)")
  if ($matches.Count -eq 0) { continue }
  $fileHeadings = $null
  foreach ($m in $matches) {
    $raw = $m.Groups[1].Value.Trim()
    if (-not $raw) { continue }
    if ($raw -match '^(https?:|mailto:|data:)') { continue }
    if ($raw.StartsWith('#')) {
      if ($null -eq $fileHeadings) { $fileHeadings = Get-HeadingsCache -File $f.FullName }
      $slug = Slug ($raw.Substring(1))
      if (-not $fileHeadings.ContainsKey($slug)) { $issues.Add([pscustomobject]@{ file=$rel; link=$raw; issue='missing-local-anchor' }) }
      continue
    }
    $target = $raw; $anchor = $null
    if ($target.Contains('#')) { $anchor = $target.Substring($target.IndexOf('#') + 1); $target = $target.Substring(0, $target.IndexOf('#')) }
    $target = [System.Uri]::UnescapeDataString($target)
    $tpath = if ([IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $dir $target }
    try { $tfull = [System.IO.Path]::GetFullPath($tpath) } catch { $tfull = $tpath }
    if (-not (Test-Path -LiteralPath $tfull)) { $issues.Add([pscustomobject]@{ file=$rel; link=$raw; issue='missing-file' }); continue }
    if ($anchor) {
      $heads = Get-HeadingsCache -File $tfull
      $slug = Slug $anchor
      if (-not $heads.ContainsKey($slug)) { $issues.Add([pscustomobject]@{ file=$rel; link=$raw; issue='missing-anchor' }) }
    }
  }
}

$summary = [pscustomobject]@{ ok=($issues.Count -eq 0); path=$Path; files=$filesScanned; issues=$issues.Count; results=@($issues.ToArray()) }
Ensure-ParentDir $SummaryOut
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }

