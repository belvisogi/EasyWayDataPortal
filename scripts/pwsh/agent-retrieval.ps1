Param(
  [ValidateSet('rag:export-wiki-chunks')]
  [string]$Action,
  [string]$IntentPath,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

function Read-Intent($path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Write-Event($obj) {
  $logDir = Join-Path 'agents' 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'events.jsonl'
  ($obj | ConvertTo-Json -Depth 10) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Out-Result($obj) { $obj | ConvertTo-Json -Depth 10 | Write-Output }

$intent = Read-Intent $IntentPath
$p = $intent?.params
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'rag:export-wiki-chunks' {
    $wikiRoot = if ($p.wikiRoot) { [string]$p.wikiRoot } else { 'Wiki/EasyWayData.wiki' }
    $outDir = if ($p.outDir) { [string]$p.outDir } else { $wikiRoot }
    $artifacts = @()
    $errorMsg = $null
    $executed = $false

    if (-not (Test-Path $wikiRoot)) { $errorMsg = "Wiki root not found: $wikiRoot" }
    if (-not $errorMsg -and -not $WhatIf) {
      try {
        $scriptsDir = Join-Path $wikiRoot 'scripts'
        if (Test-Path (Join-Path $scriptsDir 'generate-master-index.ps1')) {
          pwsh (Join-Path $scriptsDir 'generate-master-index.ps1') -Root $wikiRoot | Out-Host
          $artifacts += (Join-Path $wikiRoot 'index_master.jsonl')
        }
        if (Test-Path (Join-Path $scriptsDir 'export-chunks-jsonl.ps1')) {
          pwsh (Join-Path $scriptsDir 'export-chunks-jsonl.ps1') -Root $wikiRoot | Out-Host
          $artifacts += (Join-Path $wikiRoot 'chunks_master.jsonl')
        }
        $executed = $true
      } catch { $errorMsg = $_.Exception.Message }
    }

    $result = [ordered]@{
      action=$Action; ok=($errorMsg -eq $null); whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive;
      correlationId=($intent?.correlationId ?? $p?.correlationId); startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ wikiRoot=$wikiRoot; executed=$executed; artifacts=$artifacts; hint='Upload verso vector DB e'' step separato (runtime)'; }
      error=$errorMsg
    }
    $result.contractId='action-result'; $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-retrieval'; govApproved=$false }) }
    Out-Result $result
  }
}

