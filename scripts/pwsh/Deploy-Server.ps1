<#
  Deploy-Server.ps1

  SSH deploy on-demand sul server OCI: git fetch+reset + docker compose up.
  Usabile manualmente o da agenti (agent_infra, agent_scrummaster).

  Il deploy automatico su merge main e' gestito dal stage DeployMain in azure-pipelines.yml.
  Questo script serve per deploy mirati (es. solo agent-runner) o deploy d'emergenza
  fuori pipeline.

  Uso:
    pwsh scripts/pwsh/Deploy-Server.ps1 -WhatIf                      # dry-run
    pwsh scripts/pwsh/Deploy-Server.ps1 -Service agent-runner        # solo runner
    pwsh scripts/pwsh/Deploy-Server.ps1                              # full stack
    pwsh scripts/pwsh/Deploy-Server.ps1 -Branch develop             # deploy develop
    pwsh scripts/pwsh/Deploy-Server.ps1 -Json                       # output JSON
#>

param(
    [string] $Branch  = "main",
    [string] $Service = "",                   # vuoto = tutti i service; es. "agent-runner"
    [string] $SshKey  = "C:\old\Virtual-machine\ssh-key-2026-01-25.key",
    [string] $SshHost = "ubuntu@80.225.86.168",
    [switch] $WhatIf,
    [switch] $Json
)

$ErrorActionPreference = 'Stop'

$sshExe = "/c/Windows/System32/OpenSSH/ssh.exe"
if (-not (Test-Path $SshKey)) {
    Write-Error "SSH key non trovata: $SshKey"
    exit 1
}

# ── Costruisce il comando remoto ───────────────────────────────────────────────
$serviceArg = if ($Service) { " $Service" } else { "" }
$remoteCmd = @"
set -e
cd ~/EasyWayDataPortal
git fetch origin $Branch
git reset --hard origin/$Branch
source /opt/easyway/.env.secrets
OPENAI_API_KEY=placeholder ANTHROPIC_API_KEY=placeholder \
  docker compose -p easyway-dev \
    -f docker-compose.yml \
    up -d --build$serviceArg
echo "DEPLOY_OK `$(git rev-parse --short HEAD)"
"@

# ── WhatIf mode ───────────────────────────────────────────────────────────────
if ($WhatIf) {
    if ($Json) {
        @{
            whatIf   = $true
            branch   = $Branch
            service  = $Service
            sshHost  = $SshHost
            command  = $remoteCmd
        } | ConvertTo-Json
    } else {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  [WhatIf] Nessun deploy eseguito — anteprima:" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Host   : $SshHost" -ForegroundColor Yellow
        Write-Host "  Branch : $Branch" -ForegroundColor Yellow
        Write-Host "  Service: $(if ($Service) { $Service } else { '(tutti)' })" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Comando remoto:" -ForegroundColor Yellow
        $remoteCmd -split "`n" | ForEach-Object { Write-Host "    $_" }
        Write-Host ""
    }
    exit 0
}

# ── Esegui SSH ────────────────────────────────────────────────────────────────
Write-Host "Connecting to $SshHost ..." -ForegroundColor Cyan
$output = & $sshExe -i $SshKey -o StrictHostKeyChecking=no $SshHost $remoteCmd 2>&1
$exitCode = $LASTEXITCODE

# ── Valida output ─────────────────────────────────────────────────────────────
$sha = ""
$success = $false
foreach ($line in $output) {
    if ($line -match 'DEPLOY_OK\s+([a-f0-9]+)') {
        $sha = $Matches[1]
        $success = $true
    }
}

if ($exitCode -ne 0 -and -not $success) {
    Write-Host ($output -join "`n") -ForegroundColor Red
    Write-Error "Deploy fallito (exit $exitCode)"
    exit 1
}

# ── Output ────────────────────────────────────────────────────────────────────
if ($Json) {
    @{
        success = $success
        sha     = $sha
        branch  = $Branch
        service = $Service
        host    = $SshHost
    } | ConvertTo-Json
} else {
    $svcLabel = if ($Service) { $Service } else { 'full stack' }
    Write-Host ""
    Write-Host "Deploy OK — $svcLabel @ $sha ($Branch)" -ForegroundColor Green
    Write-Host ""
    # Mostra output SSH rilevante (ultime righe utili)
    $output | Where-Object { $_ -match 'Started|Recreated|Built|Running|DEPLOY_OK|error' } | ForEach-Object {
        $color = if ($_ -match 'error') { 'Red' } else { 'DarkGray' }
        Write-Host "  $_" -ForegroundColor $color
    }
    Write-Host ""
}
