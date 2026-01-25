$ErrorActionPreference = "Stop"

$IP = "80.225.86.168"
$Key = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"

Write-Host "🧹 ChromaDB Cleanup & Restart..." -ForegroundColor Cyan
Write-Host "="*60
Write-Host ""

Write-Host "[1] Stopping and removing dead containers..." -ForegroundColor Yellow
$cleanup = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP @"
cd ~/EasyWayDataPortal
sudo docker compose down
echo '✅ Cleanup done'
"@
Write-Host $cleanup

Write-Host ""

Write-Host "[2] Starting full EasyWay stack..." -ForegroundColor Yellow
$start = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP @"
cd ~/EasyWayDataPortal
sudo docker compose up -d
echo '✅ Stack started'
"@
Write-Host $start

Write-Host ""

Write-Host "[3] Checking status..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
$status = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
Write-Host $status

Write-Host ""
Write-Host "="*60
Write-Host "✅ Done! Check if all containers are now running." -ForegroundColor Green
