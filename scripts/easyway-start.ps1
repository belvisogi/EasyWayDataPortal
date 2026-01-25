#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick start script per accendere ambiente EasyWay su Hetzner

.DESCRIPTION
    Accende il server Hetzner, avvia i containers, e mostra lo status.
    Da eseguire dal tuo PC Windows quando vuoi lavorare su EasyWay.

.EXAMPLE
    .\easyway-start.ps1
    .\easyway-start.ps1 -Quick  # Skip git pull
#>

param(
    [switch]$Quick  # Skip updates, vai dritto al lavoro
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Avvio ambiente EasyWay..." -ForegroundColor Green
Write-Host ""

# Configurazione (modifica questi valori dopo setup Hetzner)
$ServerName = "easyway-prod"
$ServerIP = "YOUR_SERVER_IP"  # Sostituisci dopo creazione server

# 1. Verifica se hcloud è installato
if (-not (Get-Command hcloud -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Hetzner CLI non trovato. Installalo con:" -ForegroundColor Yellow
    Write-Host "   winget install hetzner.hcloud" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Per ora uso SSH diretto..." -ForegroundColor Yellow
    $UseSSH = $true
}
else {
    $UseSSH = $false
}

# 2. Accendi server
Write-Host "🔌 Accensione server Hetzner..." -ForegroundColor Cyan
if (-not $UseSSH) {
    hcloud server poweron $ServerName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Server acceso" -ForegroundColor Green
    }
    else {
        Write-Host "   ℹ️  Server già acceso" -ForegroundColor Gray
    }
    Start-Sleep -Seconds 10
}
else {
    Write-Host "   ℹ️  Verifica manualmente che il server sia acceso" -ForegroundColor Gray
}

# 3. Avvia containers
Write-Host ""
Write-Host "🐳 Avvio containers Docker..." -ForegroundColor Cyan
ssh root@$ServerIP "cd /root/easyway && docker compose up -d"

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Containers avviati" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Errore avvio containers" -ForegroundColor Red
    exit 1
}

# 4. Git pull (opzionale)
if (-not $Quick) {
    Write-Host ""
    Write-Host "📥 Aggiornamento codice..." -ForegroundColor Cyan
    ssh root@$ServerIP "cd /root/easyway && git pull"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Codice aggiornato" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  Nessun aggiornamento o errore git" -ForegroundColor Yellow
    }
}

# 5. Status
Write-Host ""
Write-Host "📊 Status containers:" -ForegroundColor Cyan
ssh root@$ServerIP "cd /root/easyway && docker compose ps"

# 6. Info accesso
Write-Host ""
Write-Host "✅ Ambiente pronto!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Servizi disponibili:" -ForegroundColor White
Write-Host "   Ollama:  http://$ServerIP:11434" -ForegroundColor Gray
Write-Host "   n8n:     http://$ServerIP:5678" -ForegroundColor Gray
Write-Host "   ChromaDB: http://$ServerIP:8000" -ForegroundColor Gray
Write-Host ""
Write-Host "🔗 Per connetterti:" -ForegroundColor White
Write-Host "   ssh root@$ServerIP" -ForegroundColor Gray
Write-Host "   code --remote ssh-remote+root@$ServerIP /root/easyway" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Quando hai finito, esegui:" -ForegroundColor White
Write-Host "   .\easyway-stop.ps1" -ForegroundColor Gray
Write-Host ""
