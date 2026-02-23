<#
.SYNOPSIS
  ADO-specific L1 Executor (backward compatibility wrapper).
.DESCRIPTION
  Delegates to the generic platform-apply.ps1 with the default ADO configuration.
  Preserved for backward compatibility — existing automation calling this script
  will continue to work unchanged.

  For new projects, use platform-apply.ps1 directly with a custom config.
.NOTES
  See: scripts/pwsh/platform-apply.ps1 (the generic implementation)
  See: config/platform-config.json (the platform configuration)
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPlanPath
)

# ── Resolve paths ─────────────────────────────────────────────────────────────
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }

$configPath = Join-Path $repoRoot 'config' 'platform-config.json'
$platformApplyPs1 = Join-Path $PSScriptRoot 'platform-apply.ps1'

Write-Host "[Backward Compat] Delegating to platform-apply.ps1..."
& $platformApplyPs1 -ExecutionPlanPath $ExecutionPlanPath -ConfigPath $configPath
