param(
    [string]$ConfigPath = "C:\\old\\EasyWayDataPortal\\scripts\\infra\\remote\\remote.config.ps1",
    [string]$IP,
    [string]$Key,
    [string]$PatPath,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

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
}

Write-Host "🚀 Avvio Deployment su $IP (Safe Mode V2)..."

# Script Bash da eseguire
$BashScript = @"
#!/bin/bash
set -e

echo "🔄 [1/5] Aggiornamento pacchetti..."
sudo apt-get update -qq > /dev/null
sudo apt-get install -y git dos2unix -qq > /dev/null

echo "🧹 [2/5] Pulizia vecchia repo..."
rm -rf EasyWayDataPortal

echo "📥 [3/5] Clonazione Repository..."
git clone https://Tokens:${PAT}@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal

echo "🔧 [4/5] Normalizzazione Line Endings..."
# Fix CRLF issues if any
cd EasyWayDataPortal
find . -type f -name "*.sh" -exec dos2unix {} \;

echo "🛠️ [5/5] Esecuzione Infrastructure Agent..."
chmod +x scripts/infra/setup-easyway-server.sh
sudo ./scripts/infra/setup-easyway-server.sh
"@

# RIMUOVI CARRIAGE RETURN (CRLF -> LF) PRIMA DI ENCODING
# Questo è il fix fondamentale per farlo andare su Linux
$BashScript = $BashScript -replace "`r", ""

# Codifica in Base64
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($BashScript)
$Encoded = [Convert]::ToBase64String($Bytes)

# Comando che decodifica ed esegue
$Command = "echo '$Encoded' | base64 -d | bash"

if ($WhatIf) {
    Write-Host "WHATIF: ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP <base64-bash>" -ForegroundColor Yellow
    Write-Host "WHATIF: would clone repo and run setup-easyway-server.sh" -ForegroundColor Yellow
    return
}

# Esegui via SSH
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP $Command

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ DEPLOYMENT COMPLETATO CON SUCCESSO!" -ForegroundColor Green
}
else {
    Write-Host "`n❌ ERRORE DURANTE IL DEPLOYMENT" -ForegroundColor Red
}
