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
function Has-Az  { try { $null = az --version 2>$null;  return $LASTEXITCODE -eq 0 } catch { return $false } }

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
  } catch { return @() }
}

function Build-Description {
  param([string[]]$files,[string]$title)
  $sb = New-Object System.Text.StringBuilder
  $null = $sb.AppendLine("# $title")
  $null = $sb.AppendLine()
  $null = $sb.AppendLine("## Scopo")
  $null = $sb.AppendLine("- PR proposta dall'agente per consolidare gates ewctl e gestione Flyway validate/migrate con approvazioni.")
  $null = $sb.AppendLine()
  $null = $sb.AppendLine("## File cambiati")
  foreach ($f in $files) { $null = $sb.AppendLine("- `$f`") }
  $null = $sb.AppendLine()
  $null = $sb.AppendLine("## Esiti e Artifact attesi")
  $null = $sb.AppendLine("- GovernanceGatesEWCTL: OK e artifact `activity-log`, `gates-report`")
  $null = $sb.AppendLine("- FlywayValidateAny: validate OK su tutte le branch")
  $null = $sb.AppendLine("- FlywayMigrateDevelop: migrate OK su develop")
  $null = $sb.AppendLine("- DBProd (main): validate+migrate con approvazioni environment")
  $null = $sb.AppendLine()
  $null = $sb.AppendLine("## Rollback")
  $null = $sb.AppendLine("- Ripristinare variabili `USE_EWCTL_GATES`/`FLYWAY_ENABLED` o revert dei commit")
  return $sb.ToString()
}

try {
  $src = if ($AutoDetectSource) { Detect-SourceBranch } else { $null }
  if (-not $Title) { $Title = "CI: ewctl gates + Flyway validate/migrate (+prod approvals)" }
  $changed = Collect-ChangedFiles
  $desc = Build-Description -files $changed -title $Title
  $desc | Set-Content -Encoding UTF8 $DescriptionPath
  Write-Host "PR description written to $DescriptionPath" -ForegroundColor Green

  $azCmd = $null
  if ($src) {
    $azCmd = "az repos pr create --source-branch `"$src`" --target-branch `"$TargetBranch`" --title `"$Title`" --description @`"$DescriptionPath`" --auto-complete false --squash false"
    Write-Host "Suggested command:" -ForegroundColor Cyan
    Write-Host $azCmd
  } else {
    Write-Host "Cannot detect source branch (git not available) — create PR manually using the description above." -ForegroundColor Yellow
  }

  if (-not $WhatIf -and $azCmd -and (Has-Az)) {
    Write-Host "Creating PR via Azure DevOps CLI..." -ForegroundColor Cyan
    iex $azCmd
  } else {
    Write-Host "WhatIf or missing az: not creating PR automatically." -ForegroundColor Yellow
  }

  if ($LogEvent) {
    try {
      $artifacts = @($DescriptionPath)
      if (Test-Path 'agents/logs/events.jsonl') { $artifacts += 'agents/logs/events.jsonl' }
      pwsh 'scripts/activity-log.ps1' -Intent 'pr-proposed' -Actor 'agent_pr_manager' -Env ($env:ENVIRONMENT ?? 'local') -Outcome 'success' -Artifacts $artifacts -Notes $Title | Out-Host
    } catch { Write-Warning "Activity log failed: $($_.Exception.Message)" }
  }
} catch {
  Write-Error $_
  exit 1
}

