<#
.SYNOPSIS
  Generic L1 Executor: reads execution_plan.json + platform-config.json, creates work items.
.DESCRIPTION
  Platform-agnostic replacement for ado-apply.ps1.
  Acts as L1 Executor: 100% deterministic. Takes a certified plan (from L3)
  and executes it via the platform adapter. No interpretation, no intelligence.

  See: EASYWAY_AGENTIC_SDLC_MASTER.md §11 (Platform Adapter Pattern)
  See: docs/AGENTIC_ARCHITECTURE_ENTERPRISE_PRD.md §8 (Safe Execution Flow)
.NOTES
  Part of Phase 9 Feature 17 — Platform Adapter SDK.
  Replaces: ado-apply.ps1 (which now delegates here).
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPlanPath,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

# ── Resolve paths ─────────────────────────────────────────────────────────────
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $repoRoot 'config' 'platform-config.json'
}

# ── Import core modules ──────────────────────────────────────────────────────
$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
$adapterDir = Join-Path $coreDir 'adapters'

Import-Module (Join-Path $coreDir 'PlatformCommon.psm1') -Force
Import-Module (Join-Path $adapterDir 'IPlatformAdapter.psm1') -Force

# ── Load config ───────────────────────────────────────────────────────────────
$config = Read-PlatformConfig -ConfigPath $ConfigPath
Write-Host "L1 Executor: Platform = $($config.platform) ($($config.displayName))"

# ── Resolve token ─────────────────────────────────────────────────────────────
$token = Resolve-PlatformToken -Config $config -AgentId 'agent_executor' -RepoRoot $repoRoot
if (-not $token) {
    throw "CRITICAL L1 ERROR: Platform token not granted by Sovereign Gatekeeper (RBAC_DENY). Action Blocked."
}
$headers = Get-AuthHeader -Config $config -Token $token

# ── Load adapter ──────────────────────────────────────────────────────────────
$adapter = New-PlatformAdapter -Config $config -Headers $headers

# NOTE: Build-AdoJsonPatch is exported from IPlatformAdapter.psm1 (consolidated module).

# ── Load execution plan ──────────────────────────────────────────────────────
Write-Host "L1 Executor: Engaging System..."
$planDoc = Read-BacklogFile -Path $ExecutionPlanPath

# ── Execute plan ──────────────────────────────────────────────────────────────
# ID Map: tempId (e.g. -1, -2) → RealId (assigned by platform).
# Required to link children to parents created in this same run.
$idMap = @{}

foreach ($task in $planDoc.plan) {
    if ($task.action -eq 'EXISTING') {
        Write-Host "  > SKIP: ($($task.type)) '$($task.title)' already exists as ID $($task.id)."
        continue
    }

    if ($task.action -eq 'CREATE') {
        Write-Host "  > EXECUTE: Create ($($task.type)) '$($task.title)'..."

        # Build platform-specific patch
        $patch = switch ($config.platform) {
            'ado' {
                Build-AdoJsonPatch `
                    -Title              $task.title `
                    -Description        $task.description `
                    -AcceptanceCriteria  $task.acceptanceCriteria `
                    -AreaPath            $task.areaPath `
                    -IterationPath       $task.iterationPath `
                    -Tags                $task.tags `
                    -Effort              ([int]$task.effort) `
                    -Priority            ([int]$task.priority) `
                    -BusinessValue       $task.businessValue `
                    -TargetDate          $task.targetDate
            }
            default {
                # Generic: just pass title/description as key-value patch
                @(
                    @{ op = 'add'; path = 'title'; value = $task.title }
                    @{ op = 'add'; path = 'description'; value = $task.description }
                )
            }
        }

        $resp = $adapter.CreateWorkItem($task.type, $patch)
        $realId = [int]$resp.id
        $idMap["$($task.tempId)"] = $realId

        Write-Host "             Created ID: $realId"

        if ($task.parentId) {
            $realParentId = $idMap["$($task.parentId)"]
            if (-not $realParentId) {
                # parentId is a real ID (not created in this run)
                $realParentId = [int]$task.parentId
            }
            Write-Host "             > Linking child $realId to parent $realParentId..."
            $adapter.LinkParentChild($realId, $realParentId)
        }
    }
}

Write-Host "L1 Execution Complete."
