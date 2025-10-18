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
"path,id,title,summary,owner,tag_groups,tags,llm_include,llm_pii,entities" | Set-Content -LiteralPath $outCsv -Encoding UTF8
"path,level,slug,text" | Set-Content -LiteralPath $outAnch -Encoding UTF8

$tmp = Join-Path $PSScriptRoot '..\\logs\\tmp'
if (!(Test-Path -LiteralPath $tmp)) { New-Item -ItemType Directory -Path $tmp | Out-Null }

$gen = Join-Path $PSScriptRoot 'generate-master-index.ps1'

foreach($root in $Roots){
  $r = Resolve-Path $root
  $csv = Join-Path $tmp (('index_{0}.csv' -f ([IO.Path]::GetFileName($r))))
  $jsonl = Join-Path $tmp (('index_{0}.jsonl' -f ([IO.Path]::GetFileName($r))))
  $anch = Join-Path $tmp (('anchors_{0}.csv' -f ([IO.Path]::GetFileName($r))))
  . $gen -Root $r -Output $csv -JsonlOutput $jsonl -AnchorsCsv $anch | Out-Null
  # append CSV rows skipping header
  $csvLines = Get-Content -LiteralPath $csv -Encoding UTF8
  if ($csvLines.Count -gt 1) {
    foreach($line in ($csvLines | Select-Object -Skip 1)){
      Add-Content -LiteralPath $outCsv -Value $line -Encoding UTF8
    }
  }
  # append JSONL
  if (Test-Path -LiteralPath $jsonl) {
    $jLines = Get-Content -LiteralPath $jsonl -Encoding UTF8
    foreach($j in $jLines){ Add-Content -LiteralPath $outJsonl -Value $j -Encoding UTF8 }
  }
  # append anchors skipping header
  $aLines = Get-Content -LiteralPath $anch -Encoding UTF8
  if ($aLines.Count -gt 1) {
    foreach($line in ($aLines | Select-Object -Skip 1)){
      Add-Content -LiteralPath $outAnch -Value $line -Encoding UTF8
    }
  }
}

Write-Host "Generato: $outCsv"
Write-Host "Generato: $outJsonl"
Write-Host "Generato: $outAnch"
