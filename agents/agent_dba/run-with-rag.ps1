# run-with-rag.ps1
# RAG-enhanced execution wrapper for agent_dba
# Usage: pwsh run-with-rag.ps1 -Query "Explain Qdrant configuration"

param(
    [Parameter(Mandatory = $true, HelpMessage = "User query for the DBA agent")]
    [string]$Query,
    
    [Parameter(Mandatory = $false, HelpMessage = "Number of RAG chunks to retrieve")]
    [int]$TopK = 5,
    
    [Parameter(Mandatory = $false, HelpMessage = "DeepSeek API key (defaults to env var)")]
    [string]$ApiKey = $env:DEEPSEEK_API_KEY
)

# Load system prompt from PROMPTS.md
$promptsFile = Join-Path $PSScriptRoot "PROMPTS.md"
if (-not (Test-Path $promptsFile)) {
    Write-Error "PROMPTS.md not found at: $promptsFile"
    exit 1
}

$systemPrompt = Get-Content $promptsFile -Raw

# Step 1: Enhance query with RAG context
Write-Host "[1/3] Querying RAG for context..." -ForegroundColor Cyan
$ragHelper = Join-Path $PSScriptRoot "../skills/retrieval/Invoke-RAGEnhancedPrompt.ps1"
$ragResult = & $ragHelper -Query $Query -TopK $TopK -SystemPrompt $systemPrompt

if (-not $ragResult.Success) {
    Write-Error "RAG enhancement failed: $($ragResult.Error)"
    exit 1
}

Write-Host "  Retrieved $($ragResult.RAGResultCount) relevant chunks" -ForegroundColor Gray

# Step 2: Call DeepSeek with enhanced prompt
Write-Host "[2/3] Calling DeepSeek LLM..." -ForegroundColor Cyan

if (-not $ApiKey) {
    Write-Error "DEEPSEEK_API_KEY not set. Please provide via -ApiKey or environment variable."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-Type"  = "application/json"
}

$body = @{
    model       = "deepseek-chat"
    messages    = @(
        @{
            role    = "user"
            content = $ragResult.EnhancedPrompt
        }
    )
    temperature = 0.1
    max_tokens  = 1000
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "https://api.deepseek.com/v1/chat/completions" `
        -Method Post `
        -Headers $headers `
        -Body $body
    
    $answer = $response.choices[0].message.content
    
}
catch {
    Write-Error "DeepSeek API call failed: $_"
    exit 1
}

# Step 3: Format and return response
Write-Host "[3/3] Formatting response..." -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Agent DBA Response (RAG-Enhanced)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host $answer
Write-Host ""

if ($ragResult.Sources.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Gray
    Write-Host " Sources" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Gray
    foreach ($source in $ragResult.Sources) {
        Write-Host "  [$($source.Index)] $($source.File) (Score: $($source.Score))" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Return structured result for programmatic use
return @{
    Query     = $Query
    Answer    = $answer
    Sources   = $ragResult.Sources
    RAGChunks = $ragResult.RAGResultCount
}
