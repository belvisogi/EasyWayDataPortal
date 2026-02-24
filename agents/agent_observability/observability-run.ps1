#Requires -Version 5.1
<#
.SYNOPSIS
    Agent_Observability L2 Runner.
.DESCRIPTION
    Wraps observability operations with standard telemetry.
#>

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('healthcheck', 'check-logs')]
    [string]$Action = 'healthcheck',

    [Parameter(Mandatory = $false)]
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
$scriptPath = Join-Path $repoRoot 'scripts' 'pwsh' 'agent-observability.ps1'

Import-Module (Join-Path $coreDir 'TelemetryLogger.psm1') -Force
Initialize-TelemetryLogger -TraceId "obs-$(Get-Date -Format 'yyyyMMdd-HHmm')"

$innerAction = if ($Action -eq 'check-logs') { 'obs:check-logs' } else { 'obs:healthcheck' }

$null = Measure-AgentAction -AgentId 'agent_observability' -AgentLevel 'L2' -Action "obs:$Action" -ScriptBlock {
    if ($InputPath) {
        if (-not (Test-Path $InputPath)) {
            throw "[Agent_Observability] Input file not found: $InputPath"
        }
        & $scriptPath -Action $innerAction -IntentPath $InputPath -NonInteractive
    }
    else {
        & $scriptPath -Action $innerAction -NonInteractive
    }
}

Write-Host "[Agent_Observability] Completed action: $Action"
