#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Apre un tunnel sicuro verso n8n (Oracle Cloud)
.DESCRIPTION
    Non esponiamo n8n su internet. Usiamo questo tunnel per accedere in sicurezza.
    Mappa la porta locale 5678 alla porta remota 5678.
    Una volta avviato, apri: http://localhost:5678
#>

param(
    [Parameter(Mandatory = $false)] [string]$TargetIP = $env:ORACLE_IP,
    [Parameter(Mandatory = $false)] [string]$KeyPath = $env:ORACLE_KEY
)

$ErrorActionPreference = "Stop"

if (-not $TargetIP) { Write-Error "Hostname/IP is required. Set ORACLE_IP env var or pass -TargetIP." }
if (-not $KeyPath) { Write-Error "SSH Key path is required. Set ORACLE_KEY env var or pass -KeyPath." }

Write-Host "🚇 Apertura Tunnel Sicuro verso easyway-orchestrator ($TargetIP)..." -ForegroundColor Cyan
Write-Host "   Local:  http://localhost:5678" -ForegroundColor Green
Write-Host "   Remote: Ubuntu@$TargetIP:5678" -ForegroundColor Gray
Write-Host ""
Write-Host "ℹ️  Lascia questa finestra aperta finché vuoi usare n8n." -ForegroundColor Yellow
Write-Host "   (Premi Ctrl+C per chiudere)" -ForegroundColor Gray
Write-Host ""

$remoteHost = "ubuntu@$TargetIP"

# SSH Tunnel Command
ssh -i $KeyPath -o StrictHostKeyChecking=no -L 5678:127.0.0.1:5678 $remoteHost -N

Write-Host ""
Write-Host "⚠️  Il tunnel si è chiuso (o non è partito)." -ForegroundColor Red
Write-Host "   Controlla se ci sono errori qui sopra (es. 'Permission denied', 'Address in use')." -ForegroundColor Gray
Read-Host "Premi Invio per uscire"
