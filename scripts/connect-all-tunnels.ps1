#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Connects to EasyWay Remote Server and forwards all necessary ports.
.DESCRIPTION
    Forwards:
    - 80   -> 80   (Traefik HTTP EntryPoint - portal.local, api.portal.local)
    - 8080 -> 8080 (Traefik Dashboard / Alternative)
    - 5678 -> 5678 (n8n Direct Access)
    - 3000 -> 3000 (API Direct Access - Debug)
#>

Write-Host "🌍 Connecting to EasyWay Remote Server..." -ForegroundColor Cyan
Write-Host "   Forwarding Ports:"
Write-Host "   - 80   (HTTP Routing)" -ForegroundColor Green
Write-Host "   - 8080 (Dashboard)" -ForegroundColor Green
Write-Host "   - 5678 (n8n)" -ForegroundColor Green
Write-Host "   - 3000 (API Direct)" -ForegroundColor Green

$keyPath = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"
$remoteHost = "ubuntu@80.225.86.168"

# SSH Tunnel Command
# -L local_port:remote_host:remote_port
ssh -i $keyPath -o StrictHostKeyChecking=no `
    -L 80:127.0.0.1:80 `
    -L 8080:127.0.0.1:8080 `
    -L 5678:127.0.0.1:5678 `
    -L 3000:127.0.0.1:3000 `
    $remoteHost -N

Write-Host "❌ Tunnel closed." -ForegroundColor Red
Read-Host "Press Enter to exit"
