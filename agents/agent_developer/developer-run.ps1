#Requires -Version 5.1
<#
.SYNOPSIS
    Agent_Developer L2 Runner.
.DESCRIPTION
    Wraps developer workflow commands with telemetry.
#>

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('start-task', 'commit-work', 'open-pr')]
    [string]$Action = 'start-task',

    [Parameter(Mandatory = $false)]
    [string]$Pbi = 'PBI-000',

    [Parameter(Mandatory = $false)]
    [string]$Desc = 'task',

    [Parameter(Mandatory = $false)]
    [string]$Type = 'feat',

    [Parameter(Mandatory = $false)]
    [string]$Message = 'work update'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
$scriptPath = Join-Path $repoRoot 'scripts' 'pwsh' 'agent-developer.ps1'

Import-Module (Join-Path $coreDir 'TelemetryLogger.psm1') -Force
Initialize-TelemetryLogger -TraceId "dev-$(Get-Date -Format 'yyyyMMdd-HHmm')"

$telemetryAction = "dev:$Action"
$null = Measure-AgentAction -AgentId 'agent_developer' -AgentLevel 'L2' -Action $telemetryAction -ScriptBlock {
    switch ($Action) {
        'start-task' {
            & $scriptPath -Action 'start-task' -PBI $Pbi -Desc $Desc
        }
        'commit-work' {
            & $scriptPath -Action 'commit-work' -Type $Type -Message $Message
        }
        'open-pr' {
            & $scriptPath -Action 'open-pr'
        }
    }
}

Write-Host "[Agent_Developer] Completed action: $Action"
