$ErrorActionPreference = "Stop"

param(
    [string]$ConfigPath = "C:\\old\\EasyWayDataPortal\\scripts\\infra\\remote\\remote.config.ps1",
    [string]$IP,
    [string]$Key,
    [switch]$WhatIf
)

# Config
if (Test-Path $ConfigPath) { . $ConfigPath }
if (-not $IP -and $RemoteConfig) { $IP = $RemoteConfig.IP }
if (-not $Key -and $RemoteConfig) { $Key = $RemoteConfig.Key }
if (-not $IP) { throw "IP non configurato (parametro -IP o remote.config.ps1)" }
if (-not $Key) { throw "Key non configurata (parametro -Key o remote.config.ps1)" }

# Preflight
if (-not (Test-Path $Key)) { throw "SSH key non trovata: $Key" }
if (-not $WhatIf) {
    ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "echo ok" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "SSH non raggiungibile: $IP" }
    ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "test -d EasyWayDataPortal" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Repo non trovata sul server. Esegui prima deploy_easyway.ps1" }
}

Write-Host "🚀 EasyWay Agent: Launching Build & Deploy on $IP (Fixed V6 - Cleanup)..."

$RemoteScript = @'
set -e
echo "📂 Entering Workspace..."
cd EasyWayDataPortal

echo "⬇️ [0/2] Pulling Latest Code..."
git pull

echo "🔄 [1/2] Deploying to /opt..."
sudo ./scripts/ci/deploy-local.sh

echo "🧹 [1.5/2] Cleaning Old Containers..."
# Force remove old conflicting containers to allow clean start with Project Name
sudo docker rm -f easyway-runner easyway-cortex easyway-db easyway-storage easyway-portal || true

echo "🏗️ [2/2] Building & Starting Docker Containers..."
cd /opt/easyway/current
export ENV_FILE="/opt/easyway/config/.env"

# USE -p easyway
sudo docker compose -p easyway --env-file "$ENV_FILE" up -d --build
'@

# SAFETY FIX: Remove CR characters
$RemoteScript = $RemoteScript -replace "`r", ""

# Encoding
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($RemoteScript)
$Encoded = [Convert]::ToBase64String($Bytes)
$Command = "echo '$Encoded' | base64 -d | bash"

if ($WhatIf) {
    Write-Host "WHATIF: ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP <base64-bash>" -ForegroundColor Yellow
    Write-Host "WHATIF: would deploy + docker compose build/up" -ForegroundColor Yellow
    return
}

ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP $Command
