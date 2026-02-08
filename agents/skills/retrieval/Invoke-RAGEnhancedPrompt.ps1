# Invoke-RAGEnhancedPrompt.ps1
# Purpose: Wrapper that combines RAG search + LLM prompt construction
# Usage: Invoke-RAGEnhancedPrompt -Query "What is Qdrant?" -TopK 5

param(
    [Parameter(Mandatory = $true, HelpMessage = "User query to enhance with RAG context")]
    [string]$Query,
    
    [Parameter(Mandatory = $false, HelpMessage = "Number of top chunks to retrieve from RAG")]
    [int]$TopK = 5,
    
    [Parameter(Mandatory = $false, HelpMessage = "System prompt for the LLM")]
    [string]$SystemPrompt = "You are a helpful assistant with access to the EasyWay project knowledge base."
)

# Import RAG search skill
$ragSearchScript = Join-Path $PSScriptRoot "Invoke-RAGSearch.ps1"
if (-not (Test-Path $ragSearchScript)) {
    Write-Error "RAG search skill not found at: $ragSearchScript"
    return @{
        Success        = $false
        Error          = "RAG search skill not available"
        EnhancedPrompt = $null
        Sources        = @()
    }
}

# Import query rewriter
$queryRewriterScript = Join-Path $PSScriptRoot "Invoke-RAGQueryRewriter.ps1"
$useQueryRewriting = Test-Path $queryRewriterScript

try {
    # Step 1: Rewrite query for better matching (if available)
    $queriesToSearch = @($Query)  # Default: original query only
    
    if ($useQueryRewriting) {
        Write-Verbose "Rewriting query for optimization..."
        $rewriteResult = & $queryRewriterScript -Query $Query -MaxVariants 3
        
        if ($rewriteResult.Success -and $rewriteResult.Variants.Count -gt 0) {
            $queriesToSearch = $rewriteResult.Variants
            Write-Verbose "Generated $($queriesToSearch.Count) query variants"
        }
    }
    
    # Step 2: Query RAG with all variants
    Write-Verbose "Querying RAG with $($queriesToSearch.Count) variants (TopK: $TopK each)"
    $allResults = @()
    
    foreach ($q in $queriesToSearch) {
        $ragResults = & $ragSearchScript -Query $q -Limit $TopK
        if ($ragResults) {
            $allResults += $ragResults
        }
    }
    
    # Step 3: Deduplicate and rank by score
    if ($allResults.Count -eq 0) {
        Write-Warning "No RAG results found for query: $Query"
        # Fallback: return original query without context
        return @{
            Success        = $true
            EnhancedPrompt = @"
System: $SystemPrompt

User Query: $Query

Note: No relevant context found in knowledge base.
"@
            Sources        = @()
            RAGResultCount = 0
        }
    }
    
    # Parse and deduplicate results
    $uniqueResults = @{}
    foreach ($resultJson in $allResults) {
        $ragData = $resultJson | ConvertFrom-Json
        if ($ragData.results) {
            foreach ($result in $ragData.results) {
                # Create a unique key based on file and a snippet of text to identify duplicate chunks
                $key = "$($result.metadata.file):$($result.text.Substring(0, [Math]::Min(50, $result.text.Length)))"
                # Add or update if new result has a higher score
                if (-not $uniqueResults.ContainsKey($key) -or $result.score -gt $uniqueResults[$key].score) {
                    $uniqueResults[$key] = $result
                }
            }
        }
    }
    
    # Sort by score and take top-K
    $topResults = $uniqueResults.Values | Sort-Object -Property score -Descending | Select-Object -First $TopK
    
    if ($topResults.Count -eq 0) {
        Write-Warning "RAG returned empty results after deduplication"
        return @{
            Success        = $true
            EnhancedPrompt = @"
System: $SystemPrompt

User Query: $Query

Note: No relevant context found in knowledge base.
"@
            Sources        = @()
            RAGResultCount = 0
        }
    }
    
    # Build context section from top chunks
    $contextBuilder = [System.Text.StringBuilder]::new()
    [void]$contextBuilder.AppendLine("Context from Knowledge Base:")
    [void]$contextBuilder.AppendLine("")
    
    $sources = @()
    $chunkIndex = 1
    
    foreach ($result in $topResults) {
        $text = $result.text
        $file = $result.metadata.file
        $score = [math]::Round($result.score, 3)
        
        # Add chunk to context
        [void]$contextBuilder.AppendLine("[$chunkIndex] (Relevance: $score)")
        [void]$contextBuilder.AppendLine($text)
        [void]$contextBuilder.AppendLine("Source: $file")
        [void]$contextBuilder.AppendLine("")
        
        # Track sources for attribution
        $sources += @{
            Index = $chunkIndex
            File  = $file
            Score = $score
            Text  = $text.Substring(0, [Math]::Min(100, $text.Length)) + "..."
        }
        
        $chunkIndex++
    }
    
    # Step 4: Construct enhanced prompt
    $enhancedPrompt = @"
System: $SystemPrompt

$($contextBuilder.ToString())

User Query: $Query

Instructions:
- Use the context from the knowledge base to provide accurate, project-specific answers.
- If the context is relevant, cite the source numbers (e.g., [1], [2]) in your response.
- If the context doesn't fully answer the query, acknowledge this and provide your best answer.
"@
    
    # Step 5: Return structured result
    return @{
        Success        = $true
        EnhancedPrompt = $enhancedPrompt
        Sources        = $sources
        RAGResultCount = $topResults.Count
        Query          = $Query
        TopK           = $TopK
    }
    
}
catch {
    Write-Error "Failed to enhance prompt with RAG: $_"
    return @{
        Success        = $false
        Error          = $_.Exception.Message
        EnhancedPrompt = $null
        Sources        = @()
    }
}
