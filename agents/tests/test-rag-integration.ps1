# test-rag-integration.ps1
# Test script for RAG integration with Level 2 agents
# Usage: pwsh test-rag-integration.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RAG Integration Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Test 1: RAG Helper Basic Functionality
Write-Host "[Test 1] RAG Helper - Basic Query" -ForegroundColor Yellow
try {
    $result = & /app/agents/skills/retrieval/Invoke-RAGEnhancedPrompt.ps1 -Query "Qdrant" -TopK 3
    
    if ($result.Success -and $result.RAGResultCount -gt 0) {
        Write-Host "  ✓ PASS: Retrieved $($result.RAGResultCount) chunks" -ForegroundColor Green
        Write-Host "  Sources: $($result.Sources.Count) unique files" -ForegroundColor Gray
        $testsPassed++
    }
    else {
        Write-Host "  ✗ FAIL: No results returned" -ForegroundColor Red
        $testsFailed++
    }
}
catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 2: RAG Helper - Fallback on No Results
Write-Host "[Test 2] RAG Helper - Graceful Fallback" -ForegroundColor Yellow
try {
    $result = & /app/agents/skills/retrieval/Invoke-RAGEnhancedPrompt.ps1 -Query "xyzabc123nonexistent" -TopK 3
    
    if ($result.Success -and $result.RAGResultCount -eq 0) {
        Write-Host "  ✓ PASS: Graceful fallback on no results" -ForegroundColor Green
        $testsPassed++
    }
    else {
        Write-Host "  ✗ FAIL: Unexpected behavior" -ForegroundColor Red
        $testsFailed++
    }
}
catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 3: RAG Helper - Enhanced Prompt Structure
Write-Host "[Test 3] RAG Helper - Prompt Structure" -ForegroundColor Yellow
try {
    $result = & /app/agents/skills/retrieval/Invoke-RAGEnhancedPrompt.ps1 -Query "Docker" -TopK 2
    
    if ($result.EnhancedPrompt -match "Context from Knowledge Base" -and 
        $result.EnhancedPrompt -match "User Query") {
        Write-Host "  ✓ PASS: Prompt structure is correct" -ForegroundColor Green
        $testsPassed++
    }
    else {
        Write-Host "  ✗ FAIL: Prompt structure invalid" -ForegroundColor Red
        $testsFailed++
    }
}
catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 4: Performance Benchmark
Write-Host "[Test 4] RAG Helper - Performance (<500ms)" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & /app/agents/skills/retrieval/Invoke-RAGEnhancedPrompt.ps1 -Query "Azure" -TopK 5
    $stopwatch.Stop()
    
    $elapsed = $stopwatch.ElapsedMilliseconds
    if ($elapsed -lt 500) {
        Write-Host "  ✓ PASS: Completed in ${elapsed}ms" -ForegroundColor Green
        $testsPassed++
    }
    else {
        Write-Host "  ✗ FAIL: Took ${elapsed}ms (target: <500ms)" -ForegroundColor Red
        $testsFailed++
    }
}
catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
    $testsFailed++
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✓ All tests passed! RAG integration is ready." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "✗ Some tests failed. Review output above." -ForegroundColor Red
    exit 1
}
