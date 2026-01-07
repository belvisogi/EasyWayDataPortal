Param(
  [ValidateSet('runtime:bundle')]
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
  'runtime:bundle' {
    $outZip = if ($p.outZip) { [string]$p.outZip } else { 'out/runtime/easyway-runtime-bundle.zip' }
    $errorMsg = $null
    $executed = $false

    if (-not $WhatIf) {
      try {
        $dir = Split-Path -Parent $outZip
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        if (Test-Path $outZip) { Remove-Item -Force $outZip }

        $includes = @('scripts','agents','docs/agentic/templates','Wiki/EasyWayData.wiki','ai/vettorializza.yaml')
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('ew-runtime-' + [Guid]::NewGuid().ToString('n'))
        New-Item -ItemType Directory -Force -Path $temp | Out-Null
        foreach ($i in $includes) {
          if (Test-Path $i) {
            $dest = Join-Path $temp $i
            $destDir = Split-Path -Parent $dest
            if ($destDir -and -not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
            Copy-Item -Recurse -Force -Path $i -Destination $dest
          }
        }
        # Exclude obvious sensitive/runtime
        Get-ChildItem -Recurse -Force -Path $temp -Filter ".env*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        if (Test-Path (Join-Path $temp 'out')) { Remove-Item -Recurse -Force (Join-Path $temp 'out') }
        if (Test-Path (Join-Path $temp 'scripts/variables')) { Remove-Item -Recurse -Force (Join-Path $temp 'scripts/variables') }

        Compress-Archive -Path (Join-Path $temp '*') -DestinationPath $outZip -Force
        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
        $executed = $true
      } catch { $errorMsg = $_.Exception.Message }
    }

    $result = [ordered]@{
      action=$Action; ok=($errorMsg -eq $null); whatIf=[bool]$WhatIf; nonInteractive=[bool]$NonInteractive;
      correlationId=($intent?.correlationId ?? $p?.correlationId); startedAt=$now; finishedAt=(Get-Date).ToUniversalTime().ToString('o');
      output=[ordered]@{ outZip=$outZip; executed=$executed; hint='Bundle per runner segregato: contiene solo subset (no segreti).'; }
      error=$errorMsg
    }
    $result.contractId='action-result'; $result.contractVersion='1.0'
    if ($LogEvent) { $null = Write-Event ($result + @{ event='agent-release'; govApproved=$false }) }
    Out-Result $result
  }
}

