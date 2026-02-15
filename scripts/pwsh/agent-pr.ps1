Param(
  [string]$Title,
  [string]$DescriptionPath = './out/PR_DESC.md',
  [string]$TargetBranch = 'develop',
  [switch]$AutoDetectSource = $true,
  [switch]$WhatIf = $true,
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $DescriptionPath) | Out-Null

function Has-Git { try { $null = git --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false } }
function Has-Az { try { $null = az --version 2>$null; return $LASTEXITCODE -eq 0 } catch { return $false } }

function Detect-SourceBranch {
  if (-not (Has-Git)) { return $null }
  try { return (git rev-parse --abbrev-ref HEAD).Trim() } catch { return $null }
}

function Collect-ChangedFiles {
  if (-not (Has-Git)) { return @() }
  try {
    $base = (git rev-parse HEAD~1 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($base)) {
      return (git ls-files -m -o --exclude-standard)
    }
    return (git diff --name-only $base HEAD)
  }
  catch { return @() }
}

function Build-Description {
  param([string[]]$files, [string]$title)
  
  $fileList = "- (Nessun file rilevato o prima commit)"
  if ($files) {
    $fileList = ($files | ForEach-Object { "- $_" }) -join [Environment]::NewLine
  }

  return @"
# $title

## Scopo
- PR proposta dall'agente per consolidare la piattaforma P2 (Advanced Platform).
- Include: Orchestrazione, Factory Kit, Governance, UX Wizard, Maintenance.

## File cambiati
$fileList

## Esiti e Artifact attesi
- Advanced Platform v1.0 Operational
- Tutti i test di verifica P2 passati
- Documentazione Handoff generata

## Rollback
- Revert del commit di merge.
"@
}

try {
  $src = if ($AutoDetectSource) { Detect-SourceBranch } else { $null }
  if (-not $Title) { $Title = "CI: ewctl gates + Flyway validate/migrate (+prod approvals)" }
  $changed = Collect-ChangedFiles
  $desc = Build-Description -files $changed -title $Title
  $desc | Set-Content -Encoding UTF8 $DescriptionPath
  Write-Host "PR description written to $DescriptionPath" -ForegroundColor Green

  # Pre-Flight Check: Verify Remote Branches
  if ($src) {
    # GOVERNANCE GUARDRAIL: Strict Gitflow Enforcement
    if ($src -like "feature/*" -and $TargetBranch -in "main", "master") {
      Write-Warning "⛔ GOVERNANCE VIOLATION: Stream Crossing Detected."
      Write-Warning "   Policy: 'feature' branches must merge into 'develop' first."
      Write-Warning "   You are trying to merge '$src' directly into '$TargetBranch'. THIS IS FORBIDDEN."
      Write-Error "Action Blocked by Governance Guardrails. Please target 'develop'."
      exit 1
    }

    Write-Host "🔍 Verifying remote branches on 'origin'..." -ForegroundColor DarkGray
    
    $remoteSrc = git ls-remote --heads origin $src
    $remoteTarget = git ls-remote --heads origin $TargetBranch

    if (-not $remoteSrc) {
      Write-Warning "❌ Source Branch 'origin/$src' NOT FOUND. Did you push?"
      Write-Warning "   Run: git push -u origin $src"
      $azCmd = $null
    }
    elseif (-not $remoteTarget) {
      Write-Warning "❌ Target Branch 'origin/$TargetBranch' NOT FOUND."
      $azCmd = $null
    }
    else {
      Write-Host "✅ Remote branches verified." -ForegroundColor Green
      # Fix: Put quotes around the entire argument including the @ symbol to prevent PowerShell here-string parsing error
      $azCmd = "az repos pr create --source-branch `"$src`" --target-branch `"$TargetBranch`" --title `"$Title`" --description `"@$DescriptionPath`" --auto-complete false --squash false"
      Write-Host "Suggested command:" -ForegroundColor Cyan
      Write-Host $azCmd
    }
  }
  else {
    Write-Host "Cannot detect source branch (git not available) — create PR manually using the description above." -ForegroundColor Yellow
  }

  if (-not $WhatIf -and $azCmd -and (Has-Az)) {
    Write-Host "Creating PR via Azure DevOps CLI..." -ForegroundColor Cyan
    iex $azCmd
  }
  else {
    Write-Host "WhatIf or missing az: not creating PR automatically." -ForegroundColor Yellow
  }

  if ($LogEvent) {
    try {
      $artifacts = @($DescriptionPath)
      if (Test-Path 'agents/logs/events.jsonl') { $artifacts += 'agents/logs/events.jsonl' }
      pwsh 'scripts/activity-log.ps1' -Intent 'pr-proposed' -Actor 'agent_pr_manager' -Env ($env:ENVIRONMENT ?? 'local') -Outcome 'success' -Artifacts $artifacts -Notes $Title | Out-Host
    }
    catch { Write-Warning "Activity log failed: $($_.Exception.Message)" }
  }
}
catch {
  Write-Error $_
  exit 1
}

