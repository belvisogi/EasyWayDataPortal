#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Connects to EasyWay Remote Server and forwards all necessary ports.
.DESCRIPTION
    Forwards:
    - 80   -> 80   (Traefik HTTP EntryPoint)
    - 8080 -> 8080 (Traefik Dashboard)
    - 5678 -> 5678 (n8n Direct Access)
    - 3000 -> 3000 (API Direct Access - Debug)
#>

param(
    [Parameter(Mandatory = $false)] [string]$TargetIP = $env:ORACLE_IP,
    [Parameter(Mandatory = $false)] [string]$KeyPath = $env:ORACLE_KEY
)

$ErrorActionPreference = "Stop"

if (-not $TargetIP) { Write-Error "Hostname/IP is required. Set ORACLE_IP env var or pass -TargetIP." }
if (-not $KeyPath) { Write-Error "SSH Key path is required. Set ORACLE_KEY env var or pass -KeyPath." }

Write-Host "🌍 Connecting to EasyWay Remote Server ($TargetIP)..." -ForegroundColor Cyan
Write-Host "   Forwarding Ports:"
Write-Host "   - 80   (HTTP Routing)" -ForegroundColor Green
Write-Host "   - 8080 (Dashboard)" -ForegroundColor Green
Write-Host "   - 5678 (n8n)" -ForegroundColor Green
Write-Host "   - 3000 (API Direct)" -ForegroundColor Green
Write-Host "   - 11434 (Ollama AI)" -ForegroundColor Magenta

$remoteHost = "ubuntu@$TargetIP"

# SSH Tunnel Command
ssh -i $KeyPath -o StrictHostKeyChecking=no `
    -L 80:127.0.0.1:80 `
    -L 8080:127.0.0.1:8080 `
    -L 5678:127.0.0.1:5678 `
    -L 3000:127.0.0.1:3000 `
    -L 11434:127.0.0.1:11434 `
    $remoteHost -N

Write-Host "❌ Tunnel closed." -ForegroundColor Red
Read-Host "Press Enter to exit"
