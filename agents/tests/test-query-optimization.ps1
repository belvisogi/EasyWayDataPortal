# test-query-optimization.ps1
# Validation test suite for RAG query optimization
# Measures hit rate improvement with query rewriting

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RAG Query Optimization Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testQueries = @(
    @{ Query = "Docker"; Expected = "Should find Docker Compose docs" },
    @{ Query = "What is our Qdrant configuration?"; Expected = "Should find Qdrant setup docs" },
    @{ Query = "n8n workflow automation"; Expected = "Should find n8n workflow files" },
    @{ Query = "database migration strategy"; Expected = "Should find DB migration docs" },
    @{ Query = "How do we deploy the API?"; Expected = "Should find deployment guides" },
    @{ Query = "security policies"; Expected = "Should find security docs" }
)

$results = @()

foreach ($test in $testQueries) {
    Write-Host "[Testing] $($test.Query)" -ForegroundColor Yellow
    
    # Test query rewriter
    $rewriteResult = & /app/agents/skills/retrieval/Invoke-RAGQueryRewriter.ps1 -Query $test.Query
    
    if ($rewriteResult.Success) {
        Write-Host "  Variants: $($rewriteResult.VariantCount)" -ForegroundColor Gray
        Write-Host "  Entities: $($rewriteResult.EntitiesFound -join ', ')" -ForegroundColor Gray
        
        # Test RAG search with enhanced prompt
        $ragResult = & /app/agents/skills/retrieval/Invoke-RAGEnhancedPrompt.ps1 -Query $test.Query -TopK 3
        
        $hitRate = if ($ragResult.RAGResultCount -gt 0) { "HIT" } else { "MISS" }
        $color = if ($hitRate -eq "HIT") { "Green" } else { "Red" }
        
        Write-Host "  Result: $hitRate ($($ragResult.RAGResultCount) chunks)" -ForegroundColor $color
        
        $results += @{
            Query    = $test.Query
            Variants = $rewriteResult.VariantCount
            Chunks   = $ragResult.RAGResultCount
            Hit      = ($ragResult.RAGResultCount -gt 0)
        }
    }
    else {
        Write-Host "  ERROR: $($rewriteResult.Error)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$totalTests = $results.Count
$hits = ($results | Where-Object { $_.Hit }).Count
$hitRate = [math]::Round(($hits / $totalTests) * 100, 1)

Write-Host "Total Queries: $totalTests" -ForegroundColor White
Write-Host "Hits: $hits" -ForegroundColor Green
Write-Host "Misses: $($totalTests - $hits)" -ForegroundColor Red
Write-Host "Hit Rate: $hitRate%" -ForegroundColor Cyan
Write-Host ""

if ($hitRate -ge 80) {
    Write-Host "✓ Target achieved! (>80%)" -ForegroundColor Green
}
elseif ($hitRate -ge 50) {
    Write-Host "⚠ Partial success (50-80%)" -ForegroundColor Yellow
}
else {
    Write-Host "✗ Below target (<50%)" -ForegroundColor Red
}
