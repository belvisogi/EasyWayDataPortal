<#
.SYNOPSIS
Agent Retrieval with RAG integration

.DESCRIPTION
Runs agent_retrieval with RAG-enhanced prompts for managing the RAG system itself.
Ironically, the RAG manager uses RAG! 🎯

.EXAMPLE
pwsh agents/agent_retrieval/run-with-rag.ps1 -Query "Check Qdrant vector DB health"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [string]$Context = "",
    
    [int]$RAGLimit = 3,
    
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 Agent Retrieval - RAG Manager (RAG-Enhanced)" -ForegroundColor Cyan

# 1. RAG Query Rewriting
Write-Host "  🔄 Optimizing query for RAG..." -ForegroundColor Gray
$rewriteResult = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGQueryRewriter.ps1" -Query $Query -MaxVariants 2

$ragQuery = if ($rewriteResult.optimized_queries) { 
    $rewriteResult.optimized_queries[0] 
}
else { 
    $Query 
}

# 2. RAG Search (meta!)
Write-Host "  🔍 Searching Wiki for RAG context..." -ForegroundColor Gray
$ragResults = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGSearch.ps1" -Query $ragQuery -Limit $RAGLimit

if ($ragResults.chunks) {
    Write-Host "    ✅ Found $($ragResults.chunks.Count) relevant RAG chunks" -ForegroundColor Green
}
else {
    Write-Host "    ⚠️  No RAG results" -ForegroundColor Yellow
}

# 3. Build Enhanced Context
$ragContext = if ($ragResults.chunks) {
    "=== RELEVANT RAG DOCUMENTATION ===`n" + 
    ($ragResults.chunks | ForEach-Object { "- $($_.text)" }) -join "`n"
}
else {
    ""
}

$fullContext = @"
$Context

$ragContext
"@

# 4. Call agent_retrieval
Write-Host "  🧠 Invoking RAG Management..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n📋 DRY RUN - Would manage:" -ForegroundColor Yellow
    Write-Host "  Query: $Query" -ForegroundColor Gray
    Write-Host "  Context: $fullContext" -ForegroundColor Gray
    exit 0
}

# Note: agent-retrieval.ps1 manages Wiki chunk export
$result = & "$PSScriptRoot/../../scripts/pwsh/agent-retrieval.ps1"

Write-Host "`n✅ RAG Management Complete" -ForegroundColor Green
Write-Host "💡 Context: $fullContext" -ForegroundColor Gray
