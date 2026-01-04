param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports'),
  [switch]$FailOnError,
  [string]$SummaryOut = "wiki-frontmatter-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Test-FrontMatter {
  param([string]$File)
  $text = Get-Content -LiteralPath $File -Raw -ErrorAction Stop
  if (-not $text.StartsWith("---`n") -and -not $text.StartsWith("---`r`n")) {
    return @{ file = $File; ok = $false; error = 'missing_yaml_front_matter' }
  }
  $end = ($text.IndexOf("`n---", 4))
  if ($end -lt 0) { return @{ file = $File; ok = $false; error = 'unterminated_front_matter' } }

  $fm = $text.Substring(4, $end - 4)
  $lines = $fm -split "`r?`n"
  $req = @{ id=$false; title=$false; summary=$false; status=$false; owner=$false; tags=$false; llm_include=$false; llm_chunk=$false }

  $inLlm = $false
  $inTags = $false
  foreach ($l in $lines) {
    $t = $l.TrimEnd()
    $tt = $t.Trim()

    if ($tt -match '^id\s*:\s*\S+') { $req.id = $true; $inTags = $false; continue }
    if ($tt -match '^title\s*:\s*\S+') { $req.title = $true; $inTags = $false; continue }
    # summary can be empty in legacy; treat empty as missing
    if ($tt -match '^summary\s*:\s*\S+') { $req.summary = $true; $inTags = $false; continue }
    if ($tt -match '^status\s*:\s*\S+') { $req.status = $true; $inTags = $false; continue }
    if ($tt -match '^owner\s*:\s*\S+') { $req.owner = $true; $inTags = $false; continue }

    if ($tt -match '^tags\s*:\s*\[') { $req.tags = $true; $inTags = $false; continue }
    if ($tt -match '^tags\s*:\s*$') { $inTags = $true; continue }
    if ($inTags -and $tt -match '^\-\s*\S+') { $req.tags = $true; continue }

    if ($tt -match '^llm\s*:\s*$') { $inLlm = $true; $inTags = $false; continue }
    if ($inLlm -and $tt -match '^include\s*:\s*(true|false)\s*$') { $req.llm_include = $true; continue }
    if ($inLlm -and $tt -match '^chunk_hint\s*:\s*\d+(-\d+)?\s*$') { $req.llm_chunk = $true; continue }

    # Exit llm if we see a new top-level key
    if ($inLlm -and $l -match '^[A-Za-z0-9_-]+\s*:') { $inLlm = $false }
  }

  $missing = @()
  foreach ($k in $req.Keys) { if (-not $req[$k]) { $missing += $k } }
  if ($missing.Count -gt 0) {
    return @{ file=$File; ok=$false; missing=$missing }
  }
  return @{ file=$File; ok=$true }
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths

$results = @()
Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md | Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) } | ForEach-Object {
  $results += Test-FrontMatter -File $_.FullName
}

$failures = @($results | Where-Object { -not $_.ok })
$summary = @{ ok = ($failures.Count -eq 0); excluded = $ExcludePaths; failures = $failures.Count; results = $results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }
