param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [switch]$FailOnError,
  [string]$SummaryOut = "wiki-frontmatter-lint.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
  foreach ($l in $lines) {
    $t = $l.Trim()
    if ($t -match '^id\s*:\s*.+') { $req.id = $true }
    elseif ($t -match '^title\s*:\s*.+') { $req.title = $true }
    elseif ($t -match '^summary\s*:\s*.+') { $req.summary = $true }
    elseif ($t -match '^status\s*:\s*.+') { $req.status = $true }
    elseif ($t -match '^owner\s*:\s*.+') { $req.owner = $true }
    elseif ($t -match '^tags\s*:\s*\[') { $req.tags = $true }
    elseif ($t -match '^llm\s*:\s*$') { $script:seenLlm = $true }
    elseif ($t -match '^include\s*:\s*(true|false)$' -and $script:seenLlm) { $req.llm_include = $true }
    elseif ($t -match '^chunk_hint\s*:\s*\d+') { $req.llm_chunk = $true }
  }
  $missing = @()
  foreach ($k in $req.Keys) { if (-not $req[$k]) { $missing += $k } }
  if ($missing.Count -gt 0) {
    return @{ file=$File; ok=$false; missing=$missing }
  }
  return @{ file=$File; ok=$true }
}

$results = @()
Get-ChildItem -LiteralPath $Path -Recurse -Filter *.md | ForEach-Object {
  $results += Test-FrontMatter -File $_.FullName
}

$summary = @{ ok = ($results | Where-Object { -not $_.ok }).Count -eq 0; results = $results }
$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
if ($FailOnError -and -not $summary.ok) { exit 1 }
