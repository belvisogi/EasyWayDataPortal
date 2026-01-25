$ErrorActionPreference = "Stop"

$IP = "80.225.86.168"
$Key = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"

Write-Host "🔍 ChromaDB Deep Diagnostic..." -ForegroundColor Red
Write-Host "="*60
Write-Host ""

# 1. Check ALL containers (running AND stopped)
Write-Host "[1] All Docker Containers:" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"

Write-Host ""

# 2. Check last 20 lines of chromadb logs (if container exists)
Write-Host "[2] ChromaDB Container Logs (last 20 lines):" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker logs --tail 20 chromadb 2>&1 || echo 'Container does not exist or has no logs'"

Write-Host ""

# 3. Check if docker-compose.yml exists and what it contains
Write-Host "[3] Docker Compose File Status:" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "cd ~/EasyWayDataPortal && ls -lh docker-compose.yml && grep -A 3 'chromadb:' docker-compose.yml 2>&1 || echo 'File not found'"

Write-Host ""

# 4. Try to start ChromaDB
Write-Host "[4] Attempting to Start ChromaDB..." -ForegroundColor Yellow
Write-Host "   (This will try: docker compose up -d chromadb)" -ForegroundColor Gray
$startResult = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "cd ~/EasyWayDataPortal && sudo docker compose up -d chromadb 2>&1"
Write-Host "   Result: $startResult"

Write-Host ""

# 5. Final status check
Write-Host "[5] Final Status:" -ForegroundColor Yellow
ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker ps --filter 'name=chromadb' --format 'table {{.Names}}\t{{.Status}}'"

Write-Host ""
Write-Host "="*60
