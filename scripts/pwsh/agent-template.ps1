Param(
  [Parameter(Mandatory=$true)] [string]$Action,
  [string]$IntentPath,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

function Read-Intent($path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  $txt = Get-Content -Path $path -Raw
  return $txt | ConvertFrom-Json
}

function Write-Event($obj) {
  $logDir = Join-Path 'agents' 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $logPath = Join-Path $logDir 'events.jsonl'
  ($obj | ConvertTo-Json -Depth 6) | Out-File -FilePath $logPath -Append -Encoding utf8
}

function Out-Result($result) {
  $json = $result | ConvertTo-Json -Depth 8
  Write-Output $json
}

$intent = Read-Intent $IntentPath
$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'sample:echo' {
    $message = $intent?.params?.message
    if (-not $message) { $message = 'echo from agent-template' }
    $workdir = $intent?.params?.workdir
    if ($workdir) { Set-Location $workdir }

    $result = [ordered]@{
      action = $Action
      ok = $true
      whatIf = [bool]$WhatIf
      nonInteractive = [bool]$NonInteractive
      correlationId = $intent?.correlationId
      startedAt = $now
      finishedAt = (Get-Date).ToUniversalTime().ToString('o')
      output = [ordered]@{
        message = $message
        cwd = (Get-Location).Path
        filesCount = (Get-ChildItem -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
      }
    }

    if ($LogEvent) {
      $evt = $result + @{ event='agent-template'; govApproved=$false }
      Write-Event $evt
    }
    Out-Result $result
  }
  default {
    throw "Unsupported action: $Action"
  }
}

