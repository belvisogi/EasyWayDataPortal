Param(
  [ValidateSet('infra:terraform-plan')]
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
  'infra:terraform-plan' {
    $wd = if ($p.workdir) { [string]$p.workdir } else { 'infra/terraform' }
    $executed = $false
    $errorMsg = $null
    if (-not (Test-Path $wd)) { $errorMsg = "Terraform dir not found: $wd" }
    if (-not $errorMsg -and -not $WhatIf) {
      if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) { $errorMsg = 'terraform not found in PATH' }
      else {
        try {
          Push-Location $wd
          terraform init -input=false | Out-Host
          terraform validate | Out-Host
          terraform plan -input=false | Out-Host
          $executed = $true
        } catch { $errorMsg = $_.Exception.Message }
        finally { Pop-Location }
      }
    }
    $result = [ordered]@{
      action=$Action; ok=($errorMsg -eq $null); whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive;
      correlationId=($intent?.correlationId ?? $p?.correlationId); startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ workdir=$wd; executed=$executed; hint='Apply non implementato qui: usare pipeline con approvazioni.' }
      error=$errorMsg
    }
    $result.contractId='action-result'; $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-infra'; govApproved=$false }) }
    Out-Result $result
  }
}

