Param(
  [ValidateSet('ps','ts')]
  [string]$Engine = 'ps',
  [string]$Intent,
  [switch]$All,
  [switch]$Wiki,
  [switch]$Checklist,
  [switch]$DbDrift,
  [switch]$KbConsistency,
  [switch]$TerraformPlan,
  [switch]$GenAppSettings,
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

function Show-Help {
  @"
ewctl - EasyWay Control CLI (agent orchestrator wrapper)

Usage:
  pwsh scripts/ewctl.ps1 [--engine ps|ts] [--intent <id>] [--all] [--wiki] [--checklist] [--dbdrift] [--kbconsistency] [--terraformplan] [--genappsettings] [--noninteractive] [--whatif]

Examples:
  # Docs review (PS engine)
  pwsh scripts/ewctl.ps1 --engine ps --intent wiki-normalize-review

  # Governance gates (PS engine)
  pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive

  # Orchestrator (TS engine, plan only)
  pwsh scripts/ewctl.ps1 --engine ts --intent wiki-normalize-review
"@ | Write-Host
}

function Run-PSDocsReview {
  param([switch]$Interactive)
  $argsList = @()
  if ($WhatIf) { $argsList += '-WhatIf' }
  if (-not $Interactive) { $argsList += '-Interactive:$false' }
  if ($All) { $argsList += '-All' }
  if ($Wiki) { $argsList += '-Wiki' } else { if (-not $All) { $argsList += '-Wiki' } }
  if ($KbConsistency) { $argsList += '-KbConsistency' }
  if ($LogEvent) { $argsList += '-LogEvent' }
  pwsh scripts/agent-docs-review.ps1 @argsList
}

function Run-PSGovernance {
  param([switch]$Interactive)
  $argsList = @()
  if ($WhatIf) { $argsList += '-WhatIf' }
  if (-not $Interactive) { $argsList += '-Interactive:$false' }
  if ($All) { $argsList += '-All' }
  if ($Checklist) { $argsList += '-Checklist' }
  if ($DbDrift) { $argsList += '-DbDrift' }
  if ($KbConsistency) { $argsList += '-KbConsistency' }
  if ($TerraformPlan) { $argsList += '-TerraformPlan' }
  if ($GenAppSettings) { $argsList += '-GenAppSettings' }
  if ($LogEvent) { $argsList += '-LogEvent' }
  pwsh scripts/agent-governance.ps1 @argsList
}

function Dispatch-Intent-PS($intent) {
  switch -Regex ($intent) {
    '^(wiki|docs)' {
      return Run-PSDocsReview -Interactive:(!$NonInteractive)
    }
    '^(gov|governance|predeploy|gates)' {
      $script:Checklist = $true; $script:DbDrift = $true; $script:KbConsistency = $true
      return Run-PSGovernance -Interactive:(!$NonInteractive)
    }
    '^(infra|terraform)' {
      $script:TerraformPlan = $true
      return Run-PSGovernance -Interactive:(!$NonInteractive)
    }
    default {
      Write-Warning "Intent sconosciuto: $intent. Uso PS governance interattivo."; return Run-PSGovernance -Interactive:(!$NonInteractive)
    }
  }
}

if ($Engine -eq 'ps') {
  if ($PSBoundParameters.ContainsKey('Intent') -and $Intent) {
    Dispatch-Intent-PS $Intent
    exit $LASTEXITCODE
  }
  if ($All -or $Wiki) {
    Run-PSDocsReview -Interactive:(!$NonInteractive); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  if ($All -or $Checklist -or $DbDrift -or $KbConsistency -or $TerraformPlan -or $GenAppSettings) {
    Run-PSGovernance -Interactive:(!$NonInteractive); exit $LASTEXITCODE
  }
  Show-Help; exit 0
}

# TS engine (Node orchestrator)
if ($Engine -eq 'ts') {
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Error 'Node non trovato. Usa --engine ps'; exit 1 }
  $argv = @()
  if ($Intent) { $argv += @('--intent', $Intent) }
  if ($All) { $argv += '--all' }
  if ($Wiki) { $argv += '--wiki' }
  if ($Checklist) { $argv += '--checklist' }
  if ($DbDrift) { $argv += '--dbdrift' }
  if ($KbConsistency) { $argv += '--kbconsistency' }
  if ($TerraformPlan) { $argv += '--terraformplan' }
  if ($GenAppSettings) { $argv += '--genappsettings' }
  if ($NonInteractive) { $argv += '--noninteractive' }
  if ($WhatIf) { $argv += '--whatif' }
  node "agents/core/orchestrator.js" @argv
  exit $LASTEXITCODE
}
