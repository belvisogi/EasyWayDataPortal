#Requires -Version 5.1
<#
.SYNOPSIS
    Agent_Backlog_Planner L2 Runner — WhatIf and Apply actions.
.DESCRIPTION
    L2 Router that wraps platform-plan.ps1 (WhatIf) and platform-apply.ps1 (Apply)
    into a formal agent interface with telemetry, validation, and state tracking.

    Actions:
      backlog:whatif  — Dry-run decomposition (L3 planner)
      backlog:apply   — Execute plan (L1 executor)

    See: agents/agent_backlog_planner/PROMPTS.md
    See: docs/wiki/Work-Item-Field-Spec.md
.NOTES
    Part of Phase 9 — Agent Formalization.
    Level: L2 (Router — orchestrates L3 planner + L1 executor)
#>

Param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('whatif', 'apply')]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

# ── Resolve paths ─────────────────────────────────────────────────────────────
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$scriptsDir = Join-Path $repoRoot 'scripts' 'pwsh'
$coreDir = Join-Path $scriptsDir 'core'

# ── Import skills ─────────────────────────────────────────────────────────────
Import-Module (Join-Path $coreDir 'TelemetryLogger.psm1') -Force

Initialize-TelemetryLogger -TraceId "backlog-$(Get-Date -Format 'yyyyMMdd-HHmm')"

Write-Host "════════════════════════════════════════════════════════"
Write-Host "  Agent_Backlog_Planner (L2) — Action: $Action"
Write-Host "════════════════════════════════════════════════════════"

# ── Action: WhatIf (L3 Planner) ─────────────────────────────────────────────
if ($Action -eq 'whatif') {
    if (-not $OutputPath) { $OutputPath = 'out/execution_plan.json' }

    $null = Measure-AgentAction -AgentId 'agent_backlog_planner' -AgentLevel 'L2' -Action 'backlog:whatif' -ScriptBlock {

        $planArgs = @{
            BacklogPath = $InputPath
            OutputPath  = $OutputPath
        }
        if ($ConfigPath) { $planArgs.ConfigPath = $ConfigPath }

        Write-Host "[L2] Delegating to L3 Planner (platform-plan.ps1)..."
        & (Join-Path $scriptsDir 'platform-plan.ps1') @planArgs

        # Read plan and report
        $plan = Get-Content $OutputPath -Raw | ConvertFrom-Json
        Write-Host ""
        Write-Host "  ┌─────────────────────────────────────────┐"
        Write-Host "  │  WhatIf Summary                         │"
        Write-Host "  ├─────────────────────────────────────────┤"
        Write-Host "  │  Items to create:  $($plan.itemsToCreate)"
        Write-Host "  │  Items existing:   $(($plan.plan | Where-Object action -eq 'EXISTING').Count)"
        Write-Host "  │  Platform:         $($plan.platform)"
        Write-Host "  │  PRD ID:           $($plan.prdId)"
        Write-Host "  │  Plan saved to:    $OutputPath"
        Write-Host "  └─────────────────────────────────────────┘"
        Write-Host ""

        if ($plan.itemsToCreate -eq 0) {
            Write-Host "[L2] Nothing to create — all items already exist."
        }
        else {
            Write-Host "[L2] ⚠️  Review the plan before running: backlog:apply"
            Write-Host "[L2] Command: backlog-run.ps1 -Action apply -InputPath $OutputPath"
        }
    }
}

# ── Action: Apply (L1 Executor) ──────────────────────────────────────────────
if ($Action -eq 'apply') {

    # Verify plan exists and was reviewed
    if (-not (Test-Path $InputPath)) {
        throw "[L2] Execution plan not found: $InputPath. Run backlog:whatif first."
    }

    $plan = Get-Content $InputPath -Raw | ConvertFrom-Json
    if ($plan.itemsToCreate -eq 0) {
        Write-Host "[L2] Nothing to create — plan has 0 items. Skipping."
        Write-TelemetryEvent -AgentId 'agent_backlog_planner' -AgentLevel 'L2' -Action 'backlog:apply-skipped' -Outcome 'skipped'
        return
    }

    Write-Host "[L2] ⚡ Executing plan: $($plan.itemsToCreate) items to create on $($plan.platform)"

    $null = Measure-AgentAction -AgentId 'agent_backlog_planner' -AgentLevel 'L2' -Action 'backlog:apply' -ScriptBlock {

        $applyArgs = @{
            ExecutionPlanPath = $InputPath
        }
        if ($ConfigPath) { $applyArgs.ConfigPath = $ConfigPath }

        Write-Host "[L2] Delegating to L1 Executor (platform-apply.ps1)..."
        & (Join-Path $scriptsDir 'platform-apply.ps1') @applyArgs
    }

    Write-Host ""
    Write-Host "[L2] ✅ Apply complete."
}

Write-Host "[Agent_Backlog_Planner] Done."
