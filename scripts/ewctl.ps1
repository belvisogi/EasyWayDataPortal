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
  [switch]$PR,
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
  try {
    pwsh scripts/enforcer.ps1 -Agent agent_docs_review -GitDiff -Quiet
    if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_docs_review'; exit 2 }
  } catch { Write-Warning "Enforcer preflight (docs) non applicabile: $($_.Exception.Message)" }
  $argsList = @()
  if ($WhatIf) { $argsList += '-WhatIf' }
  if (-not $Interactive) { $argsList += '-Interactive:$false' }
  if ($All) { $argsList += '-All' }
  if ($Wiki) { $argsList += '-Wiki' } else { if (-not $All) { $argsList += '-Wiki' } }
  if ($KbConsistency) { $argsList += '-KbConsistency' }
  $argsList += '-SyncAgentsReadme'
  if ($LogEvent) { $argsList += '-LogEvent' }
  pwsh scripts/agent-docs-review.ps1 @argsList
}

function Run-PSGovernance {
  param([switch]$Interactive)
  try {
    pwsh scripts/enforcer.ps1 -Agent agent_governance -GitDiff -Quiet
    if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_governance'; exit 2 }
  } catch { Write-Warning "Enforcer preflight (governance) non applicabile: $($_.Exception.Message)" }
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

function Run-PSPrManager {
  try {
    pwsh scripts/enforcer.ps1 -Agent agent_pr_manager -GitDiff -Quiet
    if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_pr_manager'; exit 2 }
  } catch { Write-Warning "Enforcer preflight (pr) non applicabile: $($_.Exception.Message)" }
  $argsList = @()
  if ($WhatIf) { $argsList += '-WhatIf' } else { $argsList += '-WhatIf:$false' }
  if ($LogEvent) { $argsList += '-LogEvent' }
  pwsh scripts/agent-pr.ps1 @argsList
}

function Run-PSTemplateAgent {
  param([string]$IntentPath, [switch]$Interactive)
  try {
    pwsh scripts/enforcer.ps1 -Agent agent_template -GitDiff -Quiet
    if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_template'; exit 2 }
  } catch { Write-Warning "Enforcer preflight (template) non applicabile: $($_.Exception.Message)" }
  $argsList = @('-Action','sample:echo')
  if ($IntentPath) { $argsList += @('-IntentPath', $IntentPath) }
  if ($WhatIf) { $argsList += '-WhatIf' }
  if ($LogEvent) { $argsList += '-LogEvent' }
  if (-not $Interactive) { $argsList += '-NonInteractive' }
  $json = pwsh scripts/agent-template.ps1 @argsList
  if ($null -ne $json) { try { $val = pwsh scripts/validate-action-output.ps1 -InputJson $json | ConvertFrom-Json; if (-not $val.ok) { Write-Warning ("Output contract issues: " + ($val.missing -join ", ")) } } catch {}; Write-Output $json }
}

function Run-PSDBA {
  param([string]$IntentPath, [switch]$Interactive)
  try {
    pwsh scripts/enforcer.ps1 -Agent agent_dba -GitDiff -Quiet
    if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_dba'; exit 2 }
  } catch { Write-Warning "Enforcer preflight (dba) non applicabile: $($_.Exception.Message)" }
  $argsList = @('-Action','db-user:create')
  if ($IntentPath) { $argsList += @('-IntentPath', $IntentPath) }
  if ($WhatIf) { $argsList += '-WhatIf' }
  if ($LogEvent) { $argsList += '-LogEvent' }
  if (-not $Interactive) { $argsList += '-NonInteractive' }
  $json = pwsh scripts/agent-dba.ps1 @argsList
  if ($null -ne $json) { try { $val = pwsh scripts/validate-action-output.ps1 -InputJson $json | ConvertFrom-Json; if (-not $val.ok) { Write-Warning ("Output contract issues: " + ($val.missing -join ", ")) } } catch {}; Write-Output $json }
}

function Run-PSDatalake {
  param([string]$Action, [string]$IntentPath, [switch]$Interactive)
  try {
    pwsh scripts/enforcer.ps1 -Agent agent_datalake -GitDiff -Quiet
    if ($LASTEXITCODE -eq 2) { Write-Error 'Enforcer: violazioni allowed_paths per agent_datalake'; exit 2 }
  } catch { Write-Warning "Enforcer preflight (datalake) non applicabile: $($_.Exception.Message)" }
  $argsList = @()
  if ($Action -eq 'dlk-ensure-structure') { $argsList += '-Naming' }
  elseif ($Action -eq 'dlk-apply-acl') { $argsList += '-ACL' }
  elseif ($Action -eq 'dlk-set-retention') { $argsList += '-Retention' }
  elseif ($Action -eq 'dlk-export-log') { $argsList += '-ExportLog' }
  if ($IntentPath) { $argsList += @('-IntentPath', $IntentPath) }
  if ($WhatIf) { $argsList += '-WhatIf' }
  if ($LogEvent) { $argsList += '-LogEvent' }
  if (-not $Interactive) { $argsList += '-NonInteractive' }
  $json = pwsh scripts/agent-datalake.ps1 @argsList
  if ($null -ne $json) { try { $val = pwsh scripts/validate-action-output.ps1 -InputJson $json | ConvertFrom-Json; if (-not $val.ok) { Write-Warning ("Output contract issues: " + ($val.missing -join ", ")) } } catch {}; Write-Output $json }
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
    '^(sample|template|echo)' {
      $defaultIntent = 'agents/agent_template/templates/intent.sample.json'
      return Run-PSTemplateAgent -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(db-user-create|dbuser|dba)$' {
      $defaultIntent = 'agents/agent_dba/templates/intent.db-user-create.sample.json'
      return Run-PSDBA -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(db-user-rotate)$' {
      $defaultIntent = 'agents/agent_dba/templates/intent.db-user-rotate.sample.json'
      $json = (pwsh scripts/agent-dba.ps1 -Action 'db-user:rotate' -IntentPath $defaultIntent -NonInteractive:($NonInteractive) -WhatIf:($WhatIf) -LogEvent:($LogEvent))
      if ($null -ne $json) { try { $val = pwsh scripts/validate-action-output.ps1 -InputJson $json | ConvertFrom-Json; if (-not $val.ok) { Write-Warning ("Output contract issues: " + ($val.missing -join ', ')) } } catch {}; Write-Output $json }
      return
    }
    '^(db-user-revoke)$' {
      $defaultIntent = 'agents/agent_dba/templates/intent.db-user-revoke.sample.json'
      $json = (pwsh scripts/agent-dba.ps1 -Action 'db-user:revoke' -IntentPath $defaultIntent -NonInteractive:($NonInteractive) -WhatIf:($WhatIf) -LogEvent:($LogEvent))
      if ($null -ne $json) { try { $val = pwsh scripts/validate-action-output.ps1 -InputJson $json | ConvertFrom-Json; if (-not $val.ok) { Write-Warning ("Output contract issues: " + ($val.missing -join ', ')) } } catch {}; Write-Output $json }
      return
    }
    '^(dlk-ensure-structure)$' {
      $defaultIntent = 'agents/agent_datalake/templates/intent.dlk-ensure-structure.sample.json'
      return Run-PSDatalake -Action 'dlk-ensure-structure' -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(dlk-apply-acl)$' {
      $defaultIntent = 'agents/agent_datalake/templates/intent.dlk-apply-acl.sample.json'
      return Run-PSDatalake -Action 'dlk-apply-acl' -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(dlk-set-retention)$' {
      $defaultIntent = 'agents/agent_datalake/templates/intent.dlk-set-retention.sample.json'
      return Run-PSDatalake -Action 'dlk-set-retention' -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(dlk-export-log)$' {
      $defaultIntent = 'agents/agent_datalake/templates/intent.dlk-export-log.sample.json'
      return Run-PSDatalake -Action 'dlk-export-log' -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(etl-slo-validate)$' {
      $defaultIntent = 'agents/agent_datalake/templates/intent.etl-slo-validate.sample.json'
      return Run-PSDatalake -Action 'etl-slo:validate' -IntentPath $defaultIntent -Interactive:(!$NonInteractive)
    }
    '^(doc-alignment|docs-gate)$' {
      $json = (pwsh scripts/doc-alignment-check.ps1)
      Write-Output $json; return
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
  if ($PR) {
    Run-PSPrManager; exit $LASTEXITCODE
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



