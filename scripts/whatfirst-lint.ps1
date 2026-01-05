param(
  [string]$OrchDir = "docs/agentic/templates/orchestrations",
  [string]$IntentsDir = "docs/agentic/templates/intents",
  [string]$PromptsIt = "docs/agentic/templates/orchestrations/ux_prompts.it.json",
  [string]$PromptsEn = "docs/agentic/templates/orchestrations/ux_prompts.en.json",
  [switch]$IncludeFullPath,
  [switch]$FailOnError,
  [string]$SummaryOut = "whatfirst-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Json {
  param([string]$Path)
  try { Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json | Out-Null; return $true } catch { return $false }
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
function Get-RelPath {
  param([string]$Root, [string]$FullName)
  $rootFull = (Resolve-Path -LiteralPath $Root).Path
  $full = (Resolve-Path -LiteralPath $FullName).Path
  $rel = $full.Substring($rootFull.Length).TrimStart('/',[char]92)
  return $rel.Replace([char]92,'/')
}

$results = @()
$ok = $true

if (-not (Test-Path -LiteralPath $PromptsIt)) { $ok = $false; $results += @{ file=$PromptsIt; ok=$false; error='missing' } }
elseif (-not (Test-Json -Path $PromptsIt)) { $ok = $false; $results += @{ file=$PromptsIt; ok=$false; error='invalid_json' } } else { $results += @{ file=$PromptsIt; ok=$true } }

if (-not (Test-Path -LiteralPath $PromptsEn)) { $ok = $false; $results += @{ file=$PromptsEn; ok=$false; error='missing' } }
elseif (-not (Test-Json -Path $PromptsEn)) { $ok = $false; $results += @{ file=$PromptsEn; ok=$false; error='invalid_json' } } else { $results += @{ file=$PromptsEn; ok=$true } }

if (-not (Test-Path -LiteralPath $OrchDir)) { $ok = $false; $results += @{ file=$OrchDir; ok=$false; error='missing_dir' } }
else {
  $manifests = @(Get-ChildItem -LiteralPath $OrchDir -Filter *.manifest.json -File -Recurse)
  if ($manifests.Count -eq 0) { $ok = $false; $results += @{ file=$OrchDir; ok=$false; error='no_manifests' } }
  foreach ($m in $manifests) {
    $rel = Get-RelPath -Root $repoRoot -FullName $m.FullName
    if (-not (Test-Json -Path $m.FullName)) {
      $ok = $false
      $r = @{ file = $rel; ok = $false; error = 'invalid_json' }
      if ($IncludeFullPath) { $r.fullPath = $m.FullName }
      $results += $r
    } else {
      $r = @{ file = $rel; ok = $true }
      if ($IncludeFullPath) { $r.fullPath = $m.FullName }
      $results += $r
    }
  }
}

if (-not (Test-Path -LiteralPath $IntentsDir)) { $ok = $false; $results += @{ file=$IntentsDir; ok=$false; error='missing_dir' } }
else {
  $intents = @(Get-ChildItem -LiteralPath $IntentsDir -Filter *.intent.json -File -Recurse)
  if ($intents.Count -eq 0) { $ok = $false; $results += @{ file=$IntentsDir; ok=$false; error='no_intents' } }
  foreach ($i in $intents) {
    $rel = Get-RelPath -Root $repoRoot -FullName $i.FullName
    if (-not (Test-Json -Path $i.FullName)) {
      $ok = $false
      $r = @{ file = $rel; ok = $false; error = 'invalid_json' }
      if ($IncludeFullPath) { $r.fullPath = $i.FullName }
      $results += $r
    } else {
      $r = @{ file = $rel; ok = $true }
      if ($IncludeFullPath) { $r.fullPath = $i.FullName }
      $results += $r
    }
  }
}

$summary = @{ ok = $ok; includeFullPath = [bool]$IncludeFullPath; results = $results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $ok) { exit 1 }
