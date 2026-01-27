#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Apre un tunnel sicuro verso n8n (Oracle Cloud)
.DESCRIPTION
    Non esponiamo n8n su internet. Usiamo questo tunnel per accedere in sicurezza.
    Mappa la porta locale 5678 alla porta remota 5678.
    Una volta avviato, apri: http://localhost:5678
#>

Write-Host "🚇 Apertura Tunnel Sicuro verso easyway-orchestrator (Oracle)..." -ForegroundColor Cyan
Write-Host "   Local:  http://localhost:5678" -ForegroundColor Green
Write-Host "   Remote: Ubuntu@80.225.86.168:5678" -ForegroundColor Gray
Write-Host ""
Write-Host "ℹ️  Lascia questa finestra aperta finché vuoi usare n8n." -ForegroundColor Yellow
Write-Host "   (Premi Ctrl+C per chiudere)" -ForegroundColor Gray
Write-Host ""

ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" -L 5678:127.0.0.1:5678 ubuntu@80.225.86.168 -N

Write-Host ""
Write-Host "⚠️  Il tunnel si è chiuso (o non è partito)." -ForegroundColor Red
Write-Host "   Controlla se ci sono errori qui sopra (es. 'Permission denied', 'Address in use')." -ForegroundColor Gray
Read-Host "Premi Invio per uscire"
