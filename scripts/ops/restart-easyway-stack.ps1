param(
    [Parameter(Mandatory = $false)] [string]$TargetIP = $env:ORACLE_IP,
    [Parameter(Mandatory = $false)] [string]$KeyPath = $env:ORACLE_KEY
)

$ErrorActionPreference = "Stop"

if (-not $TargetIP) { Write-Error "Hostname/IP is required. Set ORACLE_IP env var or pass -TargetIP." }
if (-not $KeyPath) { Write-Error "SSH Key path is required. Set ORACLE_KEY env var or pass -KeyPath." }

Write-Host "🧹 EasyWay Stack Restart on $TargetIP..." -ForegroundColor Cyan
Write-Host "="*60
Write-Host ""

Write-Host "[1] Stopping and removing dead containers..." -ForegroundColor Yellow
ssh -i $KeyPath -o StrictHostKeyChecking=no ubuntu@$TargetIP "cd ~/EasyWayDataPortal && sudo docker compose down && echo '✅ Cleanup done'"

Write-Host ""

Write-Host "[2] Starting full EasyWay stack..." -ForegroundColor Yellow
ssh -i $KeyPath -o StrictHostKeyChecking=no ubuntu@$TargetIP "cd ~/EasyWayDataPortal && sudo docker compose up -d && echo '✅ Stack started'"

Write-Host ""

Write-Host "[3] Checking status..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
ssh -i $KeyPath -o StrictHostKeyChecking=no ubuntu@$TargetIP "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

Write-Host ""
Write-Host "="*60
Write-Host "✅ Done! Check if all containers are now running." -ForegroundColor Green
