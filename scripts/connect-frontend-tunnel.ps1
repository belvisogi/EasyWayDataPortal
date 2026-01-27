#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Apre un tunnel sicuro verso EasyWay Portal (Oracle Cloud)
.DESCRIPTION
    Il portale è esposto internamente. Usiamo questo tunnel per accedere in sicurezza.
    Mappa la porta locale 8080 alla porta remota 8080.
    Una volta avviato, apri: http://localhost:8080
#>

Write-Host "🚇 Apertura Tunnel Sicuro verso EasyWay Portal (Oracle)..." -ForegroundColor Cyan
Write-Host "   Local:  http://localhost:8080" -ForegroundColor Green
Write-Host "   Remote: Ubuntu@80.225.86.168:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "ℹ️  Lascia questa finestra aperta finché vuoi usare il Portale." -ForegroundColor Yellow
Write-Host "   (Premi Ctrl+C per chiudere)" -ForegroundColor Gray
Write-Host ""

# Nota: -o StrictHostKeyChecking=no aggiunto per evitare blocchi interattivi
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" -o StrictHostKeyChecking=no -L 8080:127.0.0.1:8080 ubuntu@80.225.86.168 -N

Write-Host ""
Write-Host "⚠️  Il tunnel si è chiuso (o non è partito)." -ForegroundColor Red
Write-Host "   Controlla se ci sono errori qui sopra (es. 'Permission denied', 'Address in use')." -ForegroundColor Gray
Read-Host "Premi Invio per uscire"
