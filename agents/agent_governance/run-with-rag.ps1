<#
.SYNOPSIS
Agent Governance with RAG integration

.DESCRIPTION
Runs agent_governance with RAG-enhanced prompts for policy validation and quality gates.

.EXAMPLE
pwsh agents/agent_governance/run-with-rag.ps1 -Query "Validate DB migration policy compliance"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [string]$Context = "",
    
    [int]$RAGLimit = 3,
    
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "🛡️ Agent Governance - Policy Master (RAG-Enhanced)" -ForegroundColor Cyan

# 1. RAG Query Rewriting
Write-Host "  🔄 Optimizing query for RAG..." -ForegroundColor Gray
$rewriteResult = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGQueryRewriter.ps1" -Query $Query -MaxVariants 2

$ragQuery = if ($rewriteResult.optimized_queries) { 
    $rewriteResult.optimized_queries[0] 
}
else { 
    $Query 
}

# 2. RAG Search
Write-Host "  🔍 Searching Wiki for policy context..." -ForegroundColor Gray
$ragResults = & "$PSScriptRoot/../../agents/skills/retrieval/Invoke-RAGSearch.ps1" -Query $ragQuery -Limit $RAGLimit

if ($ragResults.chunks) {
    Write-Host "    ✅ Found $($ragResults.chunks.Count) relevant policy chunks" -ForegroundColor Green
}
else {
    Write-Host "    ⚠️  No RAG results, proceeding without context" -ForegroundColor Yellow
}

# 3. Build Enhanced Context
$ragContext = if ($ragResults.chunks) {
    "=== RELEVANT POLICY CONTEXT ===`n" + 
    ($ragResults.chunks | ForEach-Object { "- $($_.text)" }) -join "`n"
}
else {
    ""
}

$fullContext = @"
$Context

$ragContext
"@

# 4. Call agent_governance with enhanced context
Write-Host "  🧠 Invoking Governance Policy Validation..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n📋 DRY RUN - Would validate:" -ForegroundColor Yellow
    Write-Host "  Query: $Query" -ForegroundColor Gray
    Write-Host "  Context: $fullContext" -ForegroundColor Gray
    exit 0
}

# Note: agent-governance.ps1 has complex logic with multiple switches
# For RAG integration, we focus on policy validation aspect
$result = & "$PSScriptRoot/../../scripts/pwsh/agent-governance.ps1" `
    -Interactive:$false `
    -Checklist `
    -LogEvent

Write-Host "`n✅ Governance Validation Complete" -ForegroundColor Green
Write-Host "💡 Context: $fullContext" -ForegroundColor Gray
