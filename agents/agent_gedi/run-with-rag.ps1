<#
.SYNOPSIS
Agent GEDI with RAG integration

.DESCRIPTION
Runs agent_gedi with RAG-enhanced prompts from EasyWay Wiki.
Validates decisions against EasyWay principles using DeepSeek LLM + RAG context.

.EXAMPLE
pwsh agents/agent_gedi/run-with-rag.ps1 -Query "Should we rush this feature in 3 days?"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [string]$Context = "",
    
    [int]$RAGLimit = 3,
    
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🥋 Agent GEDI - Philosophy Guardian (RAG-Enhanced)" -ForegroundColor Cyan

# 1. RAG Query Rewriting
Write-Host "  🔄 Optimizing query for RAG..." -ForegroundColor Gray
$rewriteResult = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGQueryRewriter.ps1" -Query $Query -MaxVariants 2

$ragQuery = if ($rewriteResult.optimized_queries) { 
    $rewriteResult.optimized_queries[0] 
}
else { 
    $Query 
}

Write-Host "    Original: $Query" -ForegroundColor DarkGray
Write-Host "    Optimized: $ragQuery" -ForegroundColor DarkGray

# 2. RAG Search
Write-Host "  🔍 Searching Wiki for context..." -ForegroundColor Gray
$ragResults = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGSearch.ps1" -Query $ragQuery -Limit $RAGLimit

if ($ragResults.chunks) {
    Write-Host "    ✅ Found $($ragResults.chunks.Count) relevant chunks" -ForegroundColor Green
}
else {
    Write-Host "    ⚠️  No RAG results, proceeding without context" -ForegroundColor Yellow
}

# 3. Build Enhanced Prompt
$ragContext = if ($ragResults.chunks) {
    "=== RELEVANT EASYWAY WIKI CONTEXT ===`n" + 
    ($ragResults.chunks | ForEach-Object { "- $($_.text)" }) -join "`n"
}
else {
    ""
}

$fullContext = @"
$Context

$ragContext
"@

# 4. Call agent_gedi with enhanced context
Write-Host "  🧠 Invoking GEDI OODA Loop..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n📋 DRY RUN - Would call:" -ForegroundColor Yellow
    Write-Host "  Query: $Query" -ForegroundColor Gray
    Write-Host "  Context: $fullContext" -ForegroundColor Gray
    exit 0
}

$result = & "$PSScriptRoot/../../scripts/pwsh/agent-gedi.ps1" `
    -Query $Query `
    -Context $fullContext `
    -Provider "DeepSeek" `
    -Model "deepseek-chat" `
    -ApiKey $env:EASYWAY_LLM_KEY `
    -ApiEndpoint "https://api.deepseek.com/chat/completions" `
    -JsonOutput

# 5. Output
Write-Host "`n✅ GEDI Response:" -ForegroundColor Green
$result | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host

Write-Host "`n💙 Remember: GEDI non giudica. GEDI ricorda." -ForegroundColor Cyan
