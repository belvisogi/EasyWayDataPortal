# Invoke-RAGQueryRewriter.ps1
# Purpose: Transform natural language queries into optimized search variants
# Strategy: Pattern-based entity extraction + query expansion (no LLM dependency)

param(
    [Parameter(Mandatory = $true, HelpMessage = "User query to rewrite")]
    [string]$Query,
    
    [Parameter(Mandatory = $false, HelpMessage = "Maximum number of query variants to generate")]
    [int]$MaxVariants = 4
)

# Technical term patterns
$patterns = @{
    # Capitalized technical terms (e.g., "Qdrant", "Docker", "DeepSeek")
    TechnicalTerms = '\b[A-Z][a-z]+(?:[A-Z][a-z]+)*\b'
    
    # Acronyms (e.g., "API", "SQL", "RAG")
    Acronyms       = '\b[A-Z]{2,}\b'
    
    # File extensions and config files (e.g., ".yml", "docker-compose")
    ConfigFiles    = '\b[\w-]+\.(yml|yaml|json|md|ps1|py|ts|js)\b|\bdocker-compose\b|\bCaddyfile\b'
    
    # Technical keywords
    Keywords       = '\b(database|server|container|service|agent|workflow|configuration|deployment|security|authentication)\b'
}

# Question words and filler to remove
$fillerWords = @('what', 'how', 'why', 'when', 'where', 'is', 'are', 'our', 'the', 'a', 'an', 'do', 'does', 'explain', 'describe', 'tell', 'me', 'about', '\?', '!')

try {
    # Step 1: Extract entities
    $entities = @()
    
    foreach ($patternName in $patterns.Keys) {
        $regexMatches = [regex]::Matches($Query, $patterns[$patternName], [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $regexMatches) {
            $entities += $match.Value
        }
    }
    
    # Deduplicate entities
    $entities = $entities | Select-Object -Unique
    
    # Step 2: Generate query variants
    $variants = @()
    
    # Variant 1: Original query (always include)
    $variants += $Query
    
    # Variant 2: Entities only (if any found)
    if ($entities.Count -gt 0) {
        $variants += ($entities -join ' ')
    }
    
    # Variant 3: Query without filler words
    $cleanedQuery = $Query
    foreach ($filler in $fillerWords) {
        $cleanedQuery = $cleanedQuery -replace "\b$filler\b", '' -replace '\s+', ' '
    }
    $cleanedQuery = $cleanedQuery.Trim()
    if ($cleanedQuery -and $cleanedQuery -ne $Query) {
        $variants += $cleanedQuery
    }
    
    # Variant 4: Top 2 entities (if multiple found)
    if ($entities.Count -ge 2) {
        $variants += ($entities | Select-Object -First 2) -join ' '
    }
    
    # Variant 5: Add common technical synonyms
    $synonymMap = @{
        'configuration' = 'config setup settings'
        'setup'         = 'configuration deployment install'
        'database'      = 'db data storage'
        'container'     = 'docker service'
        'workflow'      = 'pipeline automation'
    }
    
    foreach ($key in $synonymMap.Keys) {
        if ($Query -match $key) {
            $synonyms = $synonymMap[$key] -split ' '
            foreach ($synonym in $synonyms) {
                $expandedQuery = $Query -replace $key, $synonym
                if ($expandedQuery -ne $Query) {
                    $variants += $expandedQuery
                    break  # Only add one synonym variant per key
                }
            }
        }
    }
    
    # Step 3: Deduplicate and limit variants
    $variants = $variants | Where-Object { $_ -and $_.Trim() } | Select-Object -Unique | Select-Object -First $MaxVariants
    
    # Step 4: Return structured result
    return @{
        Success       = $true
        OriginalQuery = $Query
        Variants      = $variants
        EntitiesFound = $entities
        VariantCount  = $variants.Count
    }
    
}
catch {
    Write-Error "Query rewriting failed: $_"
    return @{
        Success       = $false
        Error         = $_.Exception.Message
        OriginalQuery = $Query
        Variants      = @($Query)  # Fallback to original
    }
}
