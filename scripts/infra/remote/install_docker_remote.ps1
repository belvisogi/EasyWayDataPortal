$ErrorActionPreference = "Stop"

param(
    [string]$ConfigPath = "C:\\old\\EasyWayDataPortal\\scripts\\infra\\remote\\remote.config.ps1",
    [string]$IP,
    [string]$Key,
    [string]$PatPath,
    [switch]$WhatIf
)

# Config
if (Test-Path $ConfigPath) { . $ConfigPath }
if (-not $IP -and $RemoteConfig) { $IP = $RemoteConfig.IP }
if (-not $Key -and $RemoteConfig) { $Key = $RemoteConfig.Key }
if (-not $PatPath -and $RemoteConfig) { $PatPath = $RemoteConfig.PatPath }
if (-not $IP) { throw "IP non configurato (parametro -IP o remote.config.ps1)" }
if (-not $Key) { throw "Key non configurata (parametro -Key o remote.config.ps1)" }
if (-not $PatPath) { throw "PatPath non configurato (parametro -PatPath o remote.config.ps1)" }
$PAT = (Get-Content $PatPath).Trim()

# Preflight
if (-not (Test-Path $PatPath)) { throw "azure_pat.txt non trovato: $PatPath" }
if ([string]::IsNullOrWhiteSpace($PAT)) { throw "PAT vuoto" }
if (-not (Test-Path $Key)) { throw "SSH key non trovata: $Key" }
if (-not $WhatIf) {
    ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "echo ok" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "SSH non raggiungibile: $IP" }
    ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "test -d EasyWayDataPortal" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Repo non trovata sul server. Esegui prima deploy_easyway.ps1" }
}

Write-Host "🐳 Avvio Setup Docker su $IP..."

# Script Bash da eseguire
$BashScript = @"
#!/bin/bash
set -e

echo "📥 [1/3] Pull Ultimo Codice..."
cd EasyWayDataPortal
git pull

echo "🔧 [2/3] Fix Permessi Exec..."
chmod +x scripts/infra/install-docker.sh

echo "🐳 [3/3] Installazione Docker..."
sudo ./scripts/infra/install-docker.sh
"@

# RIMUOVI CARRIAGE RETURN (CRLF -> LF)
$BashScript = $BashScript -replace "`r", ""

# Codifica in Base64
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($BashScript)
$Encoded = [Convert]::ToBase64String($Bytes)

$Command = "echo '$Encoded' | base64 -d | bash"

if ($WhatIf) {
    Write-Host "WHATIF: ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP <base64-bash>" -ForegroundColor Yellow
    Write-Host "WHATIF: would run install-docker.sh in repo" -ForegroundColor Yellow
    return
}

# Esegui via SSH
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP $Command

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ DOCKER SETUP COMPLETATO!" -ForegroundColor Green
}
else {
    Write-Host "`n❌ ERRORE DOCKER SETUP" -ForegroundColor Red
}
