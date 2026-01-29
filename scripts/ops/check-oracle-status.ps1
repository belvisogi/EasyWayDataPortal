param(
    [Parameter(Mandatory = $false)] [string]$TargetIP = $env:ORACLE_IP,
    [Parameter(Mandatory = $false)] [string]$KeyPath = $env:ORACLE_KEY
)

$ErrorActionPreference = "Stop"

if (-not $TargetIP) { Write-Error "Hostname/IP is required. Set ORACLE_IP env var or pass -TargetIP." }
if (-not $KeyPath) { Write-Error "SSH Key path is required. Set ORACLE_KEY env var or pass -KeyPath." }

Write-Host "🔍 Checking ACTUAL Oracle Server State on $TargetIP..." -ForegroundColor Cyan
Write-Host ""

# 1. Check running containers
Write-Host "[1] Docker Containers Running:" -ForegroundColor Yellow
ssh -i $KeyPath -o StrictHostKeyChecking=no ubuntu@$TargetIP "sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'"

Write-Host ""

# 2. Check if docker-compose.yml exists
Write-Host "[2] Docker Compose File:" -ForegroundColor Yellow
ssh -i $KeyPath -o StrictHostKeyChecking=no ubuntu@$TargetIP "ls -lh ~/EasyWayDataPortal/docker-compose.yml 2>&1 || echo 'NOT FOUND'"

Write-Host ""

# 3. Check listening ports
Write-Host "[3] Open Ports:" -ForegroundColor Yellow
ssh -i $KeyPath -o StrictHostKeyChecking=no ubuntu@$TargetIP "sudo ss -tulpn | grep LISTEN | grep -E ':(8000|8080|1433|5678)'"

Write-Host ""
Write-Host "✅ Check complete" -ForegroundColor Green
