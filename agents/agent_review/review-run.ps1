#Requires -Version 5.1
<#
.SYNOPSIS
    Agent_Review L2 Runner.
.DESCRIPTION
    Wraps the existing review engine with standard L2 telemetry.
#>

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('audit-pr', 'static-check')]
    [string]$Action = 'audit-pr',

    [Parameter(Mandatory = $true)]
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
$runnerPath = Join-Path $repoRoot 'agents' 'agent_review' 'Invoke-AgentReview.ps1'

Import-Module (Join-Path $coreDir 'TelemetryLogger.psm1') -Force
Initialize-TelemetryLogger -TraceId "review-$(Get-Date -Format 'yyyyMMdd-HHmm')"

if (-not (Test-Path $InputPath)) {
    throw "[Agent_Review] Input file not found: $InputPath"
}

$query = Get-Content $InputPath -Raw -Encoding UTF8
$innerAction = if ($Action -eq 'static-check') { 'review:static' } else { 'review:docs-impact' }

$null = Measure-AgentAction -AgentId 'agent_review' -AgentLevel 'L2' -Action "review:$Action" -ScriptBlock {
    & $runnerPath -Action $innerAction -Query $query | Out-Null
}

Write-Host "[Agent_Review] Completed action: $Action"
