Param(
  [ValidateSet('api:openapi-validate')]
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
  'api:openapi-validate' {
    $apiPath = if ($p.apiPath) { [string]$p.apiPath } else { 'EasyWay-DataPortal/easyway-portal-api' }
    $openapi = Join-Path $apiPath 'openapi/openapi.yaml'
    $ok = Test-Path $openapi
    $result = [ordered]@{
      action=$Action; ok=[bool]$ok; whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive;
      correlationId=($intent?.correlationId ?? $p?.correlationId); startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ apiPath=$apiPath; openapiPath=$openapi; exists=[bool]$ok; hint='Per validazione completa integrare openapi-cli in pipeline.' }
      error= if ($ok) { $null } else { 'openapi.yaml missing' }
    }
    $result.contractId='action-result'; $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-backend'; govApproved=$false }) }
    Out-Result $result
  }
}

