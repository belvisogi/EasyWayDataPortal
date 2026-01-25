$ErrorActionPreference = "Stop"

$IP = "80.225.86.168"
$Key = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"

Write-Host "🔍 Checking ACTUAL Oracle Server State..." -ForegroundColor Cyan
Write-Host ""

# 1. Check running containers
Write-Host "[1] Docker Containers Running:" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'"

Write-Host ""

# 2. Check if docker-compose.yml exists
Write-Host "[2] Docker Compose File:" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "ls -lh ~/EasyWayDataPortal/docker-compose.yml 2>&1 || echo 'NOT FOUND'"

Write-Host ""

# 3. Check listening ports
Write-Host "[3] Open Ports:" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo ss -tulpn | grep LISTEN | grep -E ':(8000|8080|1433|5678)'"

Write-Host ""
Write-Host "✅ Check complete" -ForegroundColor Green
