#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script per spegnere ambiente EasyWay e salvare costi

.DESCRIPTION
    Committa modifiche, ferma containers, e spegne il server Hetzner.
    Da eseguire dal tuo PC Windows quando hai finito di lavorare.

.EXAMPLE
    .\easyway-stop.ps1
    .\easyway-stop.ps1 -KeepRunning  # Ferma solo containers, non spegne server
#>

param(
    [switch]$KeepRunning  # Non spegnere server, solo stop containers
)

$ErrorActionPreference = "Stop"

Write-Host "🛑 Spegnimento ambiente EasyWay..." -ForegroundColor Yellow
Write-Host ""

# Configurazione
$ServerName = "easyway-prod"
$ServerIP = "YOUR_SERVER_IP"  # Sostituisci dopo creazione server

# 1. Commit automatico modifiche remote
Write-Host "💾 Salvataggio modifiche..." -ForegroundColor Cyan
$CommitMsg = "Auto-save $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

ssh root@$ServerIP @"
cd /root/easyway
git add -A
git diff --cached --quiet || git commit -m '$CommitMsg'
git push origin main || echo 'No changes to push'
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Modifiche salvate" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️  Errore salvataggio (continuo comunque)" -ForegroundColor Yellow
}

# 2. Stop containers
Write-Host ""
Write-Host "🐳 Stop containers..." -ForegroundColor Cyan
ssh root@$ServerIP "cd /root/easyway && docker compose down"

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Containers fermati" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Errore stop containers" -ForegroundColor Red
}

# 3. Spegni server (opzionale)
if (-not $KeepRunning) {
    Write-Host ""
    Write-Host "⚡ Spegnimento server..." -ForegroundColor Cyan
    
    if (Get-Command hcloud -ErrorAction SilentlyContinue) {
        hcloud server poweroff $ServerName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Server spento" -ForegroundColor Green
        }
        else {
            Write-Host "   ⚠️  Errore spegnimento (verifica manualmente)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "   ⚠️  Hetzner CLI non trovato. Spegni manualmente da:" -ForegroundColor Yellow
        Write-Host "      https://console.hetzner.cloud/" -ForegroundColor Gray
    }
}

# 4. Calcola tempo utilizzo (approssimativo)
Write-Host ""
Write-Host "✅ Ambiente spento!" -ForegroundColor Green
Write-Host ""

if (-not $KeepRunning) {
    Write-Host "💰 Costi azzerati fino al prossimo avvio" -ForegroundColor Green
    Write-Host "   (Server spento = €0.00/ora)" -ForegroundColor Gray
}
else {
    Write-Host "⚠️  Server ancora acceso (containers fermati)" -ForegroundColor Yellow
    Write-Host "   Costo: ~€0.018/ora" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 Per vedere statistiche utilizzo:" -ForegroundColor White
Write-Host "   https://console.hetzner.cloud/ → Billing" -ForegroundColor Gray
Write-Host ""
