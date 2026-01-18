param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string[]]$ExcludePaths = @('logs/reports'),
  [int]$ScanLines = 80,
  [switch]$Apply,
  [switch]$IncludeFullPath,
  [string]$SummaryOut = "wiki-frontmatter-termination-fix.json"
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
    if (-not [System.IO.Path]::IsPathRooted($candidate)) { $candidate = Join-Path $rootFull $candidate }
    try { $full = [System.IO.Path]::GetFullPath($candidate) } catch { continue }
    if (-not $full.EndsWith([System.IO.Path]::DirectorySeparatorChar)) { $full = $full + [System.IO.Path]::DirectorySeparatorChar }
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

function Fix-FrontMatter-Termination {
  param([string]$Text)

  $lines = $Text -split "\r?\n"
  if ($lines.Count -lt 3) { return @{ changed=$false; text=$Text } }
  if ($lines[0].Trim() -ne '---') { return @{ changed=$false; text=$Text } }

  $max = [Math]::Min($lines.Count, [Math]::Max(10, $ScanLines))

  for ($i=1; $i -lt $max; $i++) {
    if ($lines[$i].Trim() -eq '---') { return @{ changed=$false; text=$Text } }
  }

  for ($i=1; $i -lt $max; $i++) {
    $line = $lines[$i]
    $trim = $line.TrimEnd()
    if ($trim -ne '---' -and $trim.EndsWith('---') -and $trim.Contains(':')) {
      $fixed = $trim.Substring(0, $trim.Length - 3).TrimEnd()
      $lines[$i] = $fixed
      $before = $lines[0..$i]
      $after = if ($i+1 -le $lines.Count-1) { $lines[($i+1)..($lines.Count-1)] } else { @() }
      $newLines = @($before + '---' + $after)
      return @{ changed=$true; text=($newLines -join "`n") }
    }
  }

  return @{ changed=$false; text=$Text }
}

$excludePrefixes = Resolve-ExcludePrefixes -Root $Path -Exclude $ExcludePaths
$results = @()

Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md |
  Where-Object { -not (Is-Excluded -FullName ($_.FullName) -Prefixes $excludePrefixes) } |
  ForEach-Object {
    $file = $_.FullName
    $text = Get-Content -LiteralPath $file -Raw
    $res = Fix-FrontMatter-Termination -Text $text
    if ($res.changed -and $Apply) {
      Set-Content -LiteralPath $file -Value $res.text -Encoding utf8
    }
    $rel = Get-RelPath -Root $Path -FullName $file
    $r = @{ file = $rel; rel = $rel; changed = [bool]$res.changed }
    if ($IncludeFullPath) { $r.fullPath = $file }
    $results += $r
  }

$changed = @($results | Where-Object { $_.changed })
$summary = @{ applied=[bool]$Apply; excluded=$ExcludePaths; scanLines=$ScanLines; includeFullPath = [bool]$IncludeFullPath; files=$results.Count; changed=$changed.Count; results=$results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
