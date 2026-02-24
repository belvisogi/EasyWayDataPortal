#Requires -Version 5.1
<#
.SYNOPSIS
    Agent_Release L2 Runner.
.DESCRIPTION
    Wraps release operations with telemetry and a stable agent interface.
#>

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('promote', 'server-sync')]
    [string]$Action = 'promote',

    [Parameter(Mandatory = $false)]
    [string]$SourceBranch = 'develop',

    [Parameter(Mandatory = $false)]
    [string]$TargetBranch = 'main',

    [Parameter(Mandatory = $false)]
    [ValidateSet('merge', 'squash')]
    [string]$Strategy = 'merge',

    [Parameter(Mandatory = $false)]
    [string]$ServerHost,

    [Parameter(Mandatory = $false)]
    [string]$ServerUser = 'ubuntu',

    [Parameter(Mandatory = $false)]
    [string]$ServerRepoPath = '~/EasyWayDataPortal'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
$scriptPath = Join-Path $repoRoot 'scripts' 'pwsh' 'agent-release.ps1'

Import-Module (Join-Path $coreDir 'TelemetryLogger.psm1') -Force
Initialize-TelemetryLogger -TraceId "release-$(Get-Date -Format 'yyyyMMdd-HHmm')"

$telemetryAction = "release:$Action"
$null = Measure-AgentAction -AgentId 'agent_release' -AgentLevel 'L2' -Action $telemetryAction -ScriptBlock {
    if ($Action -eq 'server-sync') {
        if (-not $ServerHost) {
            throw '[Agent_Release] ServerHost is required for server-sync action.'
        }
        & $scriptPath `
            -Mode 'server-sync' `
            -ServerHost $ServerHost `
            -ServerUser $ServerUser `
            -ServerRepoPath $ServerRepoPath `
            -TargetBranch $TargetBranch `
            -Yes
    }
    else {
        & $scriptPath `
            -Mode 'promote' `
            -SourceBranch $SourceBranch `
            -TargetBranch $TargetBranch `
            -Strategy $Strategy `
            -Yes
    }
}

Write-Host "[Agent_Release] Completed action: $Action"
