<#
.SYNOPSIS
  ADO-specific L3 Planner (backward compatibility wrapper).
.DESCRIPTION
  Delegates to the generic platform-plan.ps1 with the default ADO configuration.
  Preserved for backward compatibility — existing automation calling this script
  will continue to work unchanged.

  For new projects, use platform-plan.ps1 directly with a custom config.
.NOTES
  See: scripts/pwsh/platform-plan.ps1 (the generic implementation)
  See: config/platform-config.json (the platform configuration)
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$BacklogPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'out/execution_plan.json',

    [string]$AdoOrgUrl,
    [string]$AdoProject,
    [string]$AreaPath,
    [string]$IterationPath
)

# ── Resolve paths ─────────────────────────────────────────────────────────────
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$configPath = Join-Path $repoRoot 'config' 'platform-config.json'
$platformPlanPs1 = Join-Path $PSScriptRoot 'platform-plan.ps1'

Write-Host "[Backward Compat] Delegating to platform-plan.ps1..."
& $platformPlanPs1 -BacklogPath $BacklogPath -OutputPath $OutputPath -ConfigPath $configPath
