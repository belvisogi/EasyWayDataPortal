Param(
  [string]$Title,
  [string]$DescriptionPath,
  [string]$TargetBranch = 'develop',
  [switch]$AutoDetectSource = $true,
  [switch]$WhatIf = $true,
  [switch]$InitializeAzSession = $true,
  [string]$InitializeScriptPath = '',
  [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $PSCommandPath
$RepoRoot = Resolve-Path (Join-Path $ScriptRoot '..\..')
if (-not $DescriptionPath) {
  $DescriptionPath = Join-Path $RepoRoot 'out/PR_DESC.md'
}
if (-not $InitializeScriptPath) {
  $InitializeScriptPath = Join-Path $ScriptRoot 'Initialize-AzSession.ps1'
}

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
- PR proposta dall'agente per il merge del feature branch.

## File cambiati
$fileList

## Rollback
- Revert del commit di merge.
"@
}

function Initialize-AzDevOpsSession {
  param([string]$InitScript)
  if (-not (Test-Path $InitScript)) {
    throw "Initialize script not found: $InitScript"
  }
  Write-Host "Initializing Azure DevOps session..." -ForegroundColor DarkGray
  & $InitScript
}

try {
  $src = if ($AutoDetectSource) { Detect-SourceBranch } else { $null }
  if (-not $Title) { $Title = "PR: merge feature branch" }
  $changed = Collect-ChangedFiles
  $desc = Build-Description -files $changed -title $Title
  $desc | Set-Content -Encoding UTF8 $DescriptionPath
  Write-Host "PR description written to $DescriptionPath" -ForegroundColor Green

  # Pre-Flight Check: Verify Remote Branches
  if ($src) {
    # GOVERNANCE GUARDRAIL: Strict Gitflow Enforcement
    if ($src -match "^(feature|feat)/" -and $TargetBranch -in "main", "master") {
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
      $azCmd = @(
        "repos", "pr", "create",
        "--source-branch", $src,
        "--target-branch", $TargetBranch,
        "--title", $Title,
        "--description", (Get-Content $DescriptionPath -Raw),
        "--auto-complete", "false",
        "--squash", "false"
      )
      Write-Host "Prepared az repos pr create command with description from: $DescriptionPath" -ForegroundColor Cyan
    }
  }
  else {
    Write-Host "Cannot detect source branch (git not available) — create PR manually using the description above." -ForegroundColor Yellow
  }

  if (-not $WhatIf -and $azCmd -and (Has-Az)) {
    if ($InitializeAzSession) {
      Initialize-AzDevOpsSession -InitScript $InitializeScriptPath
    }
    Write-Host "Creating PR via Azure DevOps CLI..." -ForegroundColor Cyan
    az @azCmd
  }
  else {
    Write-Host "WhatIf or missing az: not creating PR automatically." -ForegroundColor Yellow
  }

  if ($LogEvent) {
    try {
      $artifacts = @($DescriptionPath)
      $eventsFile = Join-Path $RepoRoot 'agents/logs/events.jsonl'
      if (Test-Path $eventsFile) { $artifacts += $eventsFile }
      $activityLogScript = Join-Path $RepoRoot 'scripts/activity-log.ps1'
      pwsh $activityLogScript -Intent 'pr-proposed' -Actor 'agent_pr_manager' -Env ($env:ENVIRONMENT ?? 'local') -Outcome 'success' -Artifacts $artifacts -Notes $Title | Out-Host
    }
    catch { Write-Warning "Activity log failed: $($_.Exception.Message)" }
  }
}
catch {
  Write-Error $_
  exit 1
}

