Param(
  [ValidateSet('agent:scaffold')]
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
  ($obj | ConvertTo-Json -Depth 20 -Compress) | Out-File -FilePath $logPath -Append -Encoding utf8
  return $logPath
}

function Out-Result($obj) {
  $obj | ConvertTo-Json -Depth 20 -Compress | Write-Output
}

function Assert-AgentName($name) {
  if (-not $name) { throw 'params.agentName is required' }
  if ($name -notmatch '^agent_[a-z0-9_\-]+$') {
    throw "Invalid agentName '$name'. Expected: agent_<lowercase> (letters/digits/_/-)"
  }
}

$intent = Read-Intent $IntentPath
$p = if ($null -ne $intent) { $intent.params } else { $null }
$correlationId = $null
if ($null -ne $intent) { $correlationId = $intent.correlationId }
if (-not $correlationId -and $null -ne $p) { $correlationId = $p.correlationId }

$now = (Get-Date).ToUniversalTime().ToString('o')

switch ($Action) {
  'agent:scaffold' {
    $agentName = if ($null -ne $p) { [string]$p.agentName } else { '' }
    Assert-AgentName $agentName

    $baseTemplate = if ($null -ne $p -and $p.baseTemplate) { [string]$p.baseTemplate } else { 'agents/agent_template' }
    if (-not (Test-Path $baseTemplate)) { throw "Base template not found: $baseTemplate" }

    $destDir = Join-Path 'agents' $agentName
    $artifacts = @()
    $errorMsg = $null
    $executed = $false

    if (Test-Path $destDir) { throw "Agent directory already exists: $destDir" }

    if (-not $WhatIf) {
      try {
        Copy-Item -Recurse -Force -Path $baseTemplate -Destination $destDir
        $executed = $true
        $artifacts += (Join-Path $destDir 'manifest.json')
        $artifacts += (Join-Path $destDir 'README.md')
        $artifacts += (Join-Path $destDir 'priority.json')

        # Best-effort: adjust manifest.json (template manifest format) with name/description if present
        $manifestPath = Join-Path $destDir 'manifest.json'
        try {
          $mj = Get-Content -Raw $manifestPath | ConvertFrom-Json
          if ($mj.id) { $mj.id = $agentName }
          if ($mj.name) { $mj.name = $agentName }
          if ($null -ne $p -and $p.description) { $mj.description = [string]$p.description }
          ($mj | ConvertTo-Json -Depth 30) | Set-Content -Encoding UTF8 -Path $manifestPath
        } catch {}

        # Optional: align agents/README.md
        if ($null -ne $p -and $p.updateAgentsReadme -eq $true) {
          try {
            pwsh scripts/agents-readme-sync.ps1 -Mode fix | Out-Host
            $artifacts += 'agents/README.md'
          } catch {}
        }
      } catch {
        $errorMsg = $_.Exception.Message
      }
    }

    $result = [ordered]@{
      action=$Action
      ok=($errorMsg -eq $null)
      whatIf=[bool]$WhatIf
      nonInteractive=[bool]$NonInteractive
      correlationId=$correlationId
      startedAt=$now
      finishedAt=(Get-Date).ToUniversalTime().ToString('o')
      output=[ordered]@{
        agentDir=$destDir
        executed=$executed
        artifacts=$artifacts
      }
      error=$errorMsg
    }

    $result.contractId='action-result'
    $result.contractVersion='1.0'

    if ($LogEvent) {
      $null = Write-Event ($result + @{ event='agent-creator'; govApproved=$false })
    }

    Out-Result $result
  }
}

