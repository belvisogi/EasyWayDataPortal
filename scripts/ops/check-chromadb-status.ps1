$ErrorActionPreference = "Stop"

$IP = "80.225.86.168"
$Key = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"

Write-Host "🔍 Checking ChromaDB Status on Oracle Server..." -ForegroundColor Cyan
Write-Host "="*60
Write-Host ""

# Test 1: Is ChromaDB container running?
Write-Host "[1] Container Status:" -ForegroundColor Yellow
$containerStatus = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker ps --filter 'name=chromadb' --format '{{.Names}}\t{{.Status}}'"
if ($containerStatus) {
    Write-Host "   ✅ $containerStatus" -ForegroundColor Green
}
else {
    Write-Host "   ❌ ChromaDB container NOT running!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Is ChromaDB API responding?
Write-Host "[2] API Health Check:" -ForegroundColor Yellow
$healthCheck = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "curl -s http://localhost:8000/api/v1/heartbeat 2>&1"
if ($healthCheck -match "heartbeat") {
    Write-Host "   ✅ API is responding: $healthCheck" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️  API response: $healthCheck" -ForegroundColor Yellow
}

Write-Host ""

# Test 3: List Collections (are there any?)
Write-Host "[3] Collections in ChromaDB:" -ForegroundColor Yellow
$collections = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "curl -s http://localhost:8000/api/v1/collections 2>&1"
Write-Host "   Raw response: $collections"

# Try to parse collections
if ($collections -match '\[\]' -or $collections -eq '[]') {
    Write-Host ""
    Write-Host "   ❌ NO COLLECTIONS FOUND - ChromaDB is EMPTY!" -ForegroundColor Red
    Write-Host "   📝 Vector database exists but has NO DATA inside." -ForegroundColor Yellow
}
elseif ($collections -match '"name"') {
    Write-Host ""
    Write-Host "   ✅ Collections found!" -ForegroundColor Green
    Write-Host "   📊 Data in ChromaDB" -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "   ⚠️  Unable to determine collections status" -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Check persistent volume
Write-Host "[4] Persistent Data Volume:" -ForegroundColor Yellow
$volumeSize = ssh -i $Key -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker exec chromadb du -sh /chroma/chroma 2>&1 || echo 'Cannot access volume'"
Write-Host "   Volume size: $volumeSize"

if ($volumeSize -match "^\s*\d+K" -or $volumeSize -match "^\s*0") {
    Write-Host "   ⚠️  Volume is very small - likely empty or minimal data" -ForegroundColor Yellow
}
elseif ($volumeSize -match "M|G") {
    Write-Host "   ✅ Volume has significant data" -ForegroundColor Green
}

Write-Host ""
Write-Host "="*60
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "   If collections = [], you need to run the vectorization script!"
Write-Host "   Check: scripts/pwsh/vectorize-knowledge.ps1" -ForegroundColor Gray
