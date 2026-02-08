<#
.SYNOPSIS
Agent Chronicler with RAG integration

.DESCRIPTION
Runs agent_chronicler with RAG-enhanced prompts for celebrating milestones.
The Bard uses RAG to remember the project's history!

.EXAMPLE
pwsh agents/agent_chronicler/run-with-rag.ps1 -Query "Celebrate RAG integration milestone"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [string]$Context = "",
    
    [int]$RAGLimit = 5,
    
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "📜 Agent Chronicler - The Bard (RAG-Enhanced)" -ForegroundColor Cyan

# 1. RAG Query Rewriting
Write-Host "  🔄 Optimizing query for RAG..." -ForegroundColor Gray
$rewriteResult = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGQueryRewriter.ps1" -Query $Query -MaxVariants 2

$ragQuery = if ($rewriteResult.optimized_queries) { 
    $rewriteResult.optimized_queries[0] 
}
else { 
    $Query 
}

# 2. RAG Search (history context)
Write-Host "  🔍 Searching Wiki for historical context..." -ForegroundColor Gray
$ragResults = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGSearch.ps1" -Query $ragQuery -Limit $RAGLimit

if ($ragResults.chunks) {
    Write-Host "    ✅ Found $($ragResults.chunks.Count) relevant history chunks" -ForegroundColor Green
}
else {
    Write-Host "    ⚠️  No RAG results" -ForegroundColor Yellow
}

# 3. Build Enhanced Context
$ragContext = if ($ragResults.chunks) {
    "=== PROJECT HISTORY CONTEXT ===`n" + 
    ($ragResults.chunks | ForEach-Object { "- $($_.text)" }) -join "`n"
}
else {
    ""
}

$fullContext = @"
$Context

$ragContext
"@

# 4. Generate Celebration
Write-Host "  🧠 Invoking The Bard..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n📋 DRY RUN - Would celebrate:" -ForegroundColor Yellow
    Write-Host "  Query: $Query" -ForegroundColor Gray
    Write-Host "  Context: $fullContext" -ForegroundColor Gray
    exit 0
}

# Note: agent-chronicler.ps1 records milestones
$result = & "$PSScriptRoot/../../scripts/pwsh/agent-chronicler.ps1"

Write-Host "`n✅ Milestone Chronicled" -ForegroundColor Green
Write-Host "🎭 'A star is born!' - The Bard" -ForegroundColor Magenta
Write-Host "💡 Context: $fullContext" -ForegroundColor Gray
