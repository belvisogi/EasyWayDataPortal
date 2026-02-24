#Requires -Version 5.1
<#
.SYNOPSIS
    Agent_PR_Manager L2 Runner.
.DESCRIPTION
    Wraps PR lifecycle operations with telemetry.
#>

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('create', 'validate-gates', 'analyze')]
    [string]$Action = 'create',

    [Parameter(Mandatory = $false)]
    [string]$Title = 'PR: merge feature branch',

    [Parameter(Mandatory = $false)]
    [string]$TargetBranch = 'develop',

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
$scriptPath = Join-Path $repoRoot 'scripts' 'pwsh' 'agent-pr.ps1'
$outPath = Join-Path $repoRoot 'out' 'PR_DESC.md'

Import-Module (Join-Path $coreDir 'TelemetryLogger.psm1') -Force
Initialize-TelemetryLogger -TraceId "prmgr-$(Get-Date -Format 'yyyyMMdd-HHmm')"

$telemetryAction = "pr:$Action"
$null = Measure-AgentAction -AgentId 'agent_pr_manager' -AgentLevel 'L2' -Action $telemetryAction -ScriptBlock {
    switch ($Action) {
        'create' {
            & $scriptPath -Title $Title -TargetBranch $TargetBranch -DescriptionPath $outPath -WhatIf:$WhatIf
        }
        'analyze' {
            & $scriptPath -Title $Title -TargetBranch $TargetBranch -DescriptionPath $outPath -WhatIf:$true
        }
        'validate-gates' {
            $currentBranch = (git branch --show-current).Trim()
            if (-not $currentBranch) { throw '[Agent_PR_Manager] Unable to detect current branch.' }
            if ($currentBranch -eq 'main') {
                throw '[Agent_PR_Manager] Gate failed: PR from main branch is not allowed.'
            }
            Write-Host "[Agent_PR_Manager] Gate validation passed for branch: $currentBranch"
        }
    }
}

Write-Host "[Agent_PR_Manager] Completed action: $Action"
