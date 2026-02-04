# DQF AGENT V2 - Quick Test
# ==========================
# Tests the integrated Interpreter + Memory Manager

Write-Host "🧪 Testing DQF Agent V2..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Validate intent
Write-Host "Test 1: Validate Intent" -ForegroundColor Yellow
pwsh c:\old\EasyWayDataPortal\scripts\pwsh\dqf-agent-v2.ps1 "Valida i file nella cartella Wiki/EasyWayData.wiki/agents"
Write-Host ""

# Test 2: Check if memory.db was created
Write-Host "Test 2: Memory Persistence" -ForegroundColor Yellow
if (Test-Path "c:\old\EasyWayDataPortal\packages\dqf-agent\memory.db") {
    Write-Host "✅ Memory database created successfully!" -ForegroundColor Green
    
    # Show database size
    $dbSize = (Get-Item "c:\old\EasyWayDataPortal\packages\dqf-agent\memory.db").Length
    Write-Host "   Database size: $dbSize bytes" -ForegroundColor Gray
}
else {
    Write-Host "❌ Memory database not found!" -ForegroundColor Red
}
Write-Host ""

# Test 3: Analyze intent (shorter path)
Write-Host "Test 3: Analyze Intent" -ForegroundColor Yellow
pwsh c:\old\EasyWayDataPortal\scripts\pwsh\dqf-agent-v2.ps1 "Analizza i primi 2 file"
Write-Host ""

Write-Host "🎉 Tests complete!" -ForegroundColor Green
