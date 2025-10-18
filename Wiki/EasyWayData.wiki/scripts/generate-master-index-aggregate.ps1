[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string[]]$Roots,
  [string]$OutputCsv = 'index_master_all.csv',
  [string]$OutputJsonl = 'index_master_all.jsonl',
  [string]$OutputAnchors = 'anchors_master_all.csv'
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$outCsv = Join-Path (Resolve-Path .) $OutputCsv
$outJsonl = Join-Path (Resolve-Path .) $OutputJsonl
$outAnch = Join-Path (Resolve-Path .) $OutputAnchors

if (Test-Path -LiteralPath $outCsv) { Remove-Item -LiteralPath $outCsv -Force }
if (Test-Path -LiteralPath $outJsonl) { Remove-Item -LiteralPath $outJsonl -Force }
if (Test-Path -LiteralPath $outAnch) { Remove-Item -LiteralPath $outAnch -Force }
"path,id,title,summary,owner,tag_groups,tags,llm_include,llm_pii,entities" | Set-Content -LiteralPath $outCsv -Encoding UTF8
"path,level,slug,text" | Set-Content -LiteralPath $outAnch -Encoding UTF8

foreach($root in $Roots){
  $r = Resolve-Path $root
  $csv = Join-Path $r 'index_master.csv'
  $jsonl = Join-Path $r 'index_master.jsonl'
  $anch = Join-Path $r 'anchors_master.csv'
  if (Test-Path -LiteralPath $csv) {
    (Get-Content -LiteralPath $csv -Encoding UTF8 | Select-Object -Skip 1) | ForEach-Object { Add-Content -LiteralPath $outCsv -Value $_ -Encoding UTF8 }
  }
  if (Test-Path -LiteralPath $jsonl) {
    Get-Content -LiteralPath $jsonl -Encoding UTF8 | ForEach-Object { Add-Content -LiteralPath $outJsonl -Value $_ -Encoding UTF8 }
  }
  if (Test-Path -LiteralPath $anch) {
    (Get-Content -LiteralPath $anch -Encoding UTF8 | Select-Object -Skip 1) | ForEach-Object { Add-Content -LiteralPath $outAnch -Value $_ -Encoding UTF8 }
  }
}

Write-Host "Generato: $outCsv"
Write-Host "Generato: $outJsonl"
Write-Host "Generato: $outAnch"

