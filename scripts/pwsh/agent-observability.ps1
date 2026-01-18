Param(
  [ValidateSet('obs:healthcheck')]
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
  'obs:healthcheck' {
    $paths = @()
    if ($p.paths) { $paths = @($p.paths) } else { $paths = @('agents/logs/events.jsonl', 'Wiki/EasyWayData.wiki/chunks_master.jsonl') }
    $checks = @()
    foreach ($pp in $paths) {
      $exists = Test-Path $pp
      $checks += [ordered]@{ path=$pp; exists=[bool]$exists }
    }
    $result = [ordered]@{
      action=$Action; ok=$true; whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive;
      correlationId=($intent?.correlationId ?? $p?.correlationId); startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ checks=$checks; hint='Healthcheck locale file-based; per runtime aggiungere endpoint/metrics.' }
    }
    $result.contractId='action-result'; $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-observability'; govApproved=$false }) }
    Out-Result $result
  }
}

