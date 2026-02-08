<#
.SYNOPSIS
Search agent metadata using semantic search

.DESCRIPTION
Queries Qdrant collection 'agent_metadata' for agents matching the search query.
Returns ranked results with agent details.

.EXAMPLE
pwsh agents/skills/retrieval/Invoke-AgentMetadataSearch.ps1 -Query "database agents"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [int]$Limit = 5,
    
    [string]$Classification,  # Filter: "brain" or "arm"
    
    [int]$EvolutionLevel,     # Filter: 0, 1, or 2
    
    [string]$Owner,           # Filter by owner team
    
    [string]$QdrantUrl = "http://localhost:6333",
    
    [string]$Collection = "agent_metadata"
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 Searching agent metadata..." -ForegroundColor Cyan
Write-Host "Query: $Query" -ForegroundColor Gray

# Generate query embedding using Python
$embeddingScript = @"
import sys
import json
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('all-MiniLM-L6-v2')
text = sys.stdin.read()
embedding = model.encode(text).tolist()
print(json.dumps(embedding))
"@

$queryEmbedding = $Query | python -c $embeddingScript | ConvertFrom-Json

# Build filter
$filter = @{}
if ($Classification) {
    $filter.classification = @{ match = @{ value = $Classification } }
}
if ($EvolutionLevel) {
    $filter.evolution_level = @{ match = @{ value = $EvolutionLevel } }
}
if ($Owner) {
    $filter.owner = @{ match = @{ value = $Owner } }
}

# Search Qdrant
$searchBody = @{
    vector       = $queryEmbedding
    limit        = $Limit
    with_payload = $true
} | ConvertTo-Json -Depth 10

if ($filter.Count -gt 0) {
    $searchBody = @{
        vector       = $queryEmbedding
        limit        = $Limit
        filter       = $filter
        with_payload = $true
    } | ConvertTo-Json -Depth 10
}

$response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection/points/search" `
    -Method Post `
    -Body $searchBody `
    -ContentType "application/json"

# Format results
Write-Host "`n📋 Results:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$results = @()
foreach ($result in $response.result) {
    $agent = $result.payload
    $score = [math]::Round($result.score, 3)
    
    Write-Host "`n🤖 $($agent.name) (Score: $score)" -ForegroundColor Green
    Write-Host "   Role: $($agent.role)" -ForegroundColor Gray
    Write-Host "   Type: $($agent.classification) | Level: $($agent.evolution_level)" -ForegroundColor Gray
    Write-Host "   Description: $($agent.description)" -ForegroundColor Gray
    Write-Host "   Actions: $($agent.actions.Count)" -ForegroundColor Gray
    
    $results += [PSCustomObject]@{
        id              = $agent.id
        name            = $agent.name
        role            = $agent.role
        classification  = $agent.classification
        evolution_level = $agent.evolution_level
        score           = $score
        description     = $agent.description
        actions_count   = $agent.actions.Count
        skills_count    = ($agent.skills_required + $agent.skills_optional).Count
    }
}

Write-Host "`n✅ Found $($results.Count) agents" -ForegroundColor Green

return $results
