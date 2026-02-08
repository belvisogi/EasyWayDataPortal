<#
.SYNOPSIS
Index agent manifests in Qdrant for semantic search

.DESCRIPTION
Reads all agent manifest.json files, generates embeddings, and indexes them
in Qdrant collection 'agent_metadata' for semantic search capabilities.

.EXAMPLE
pwsh scripts/index-agent-metadata.ps1
#>

param(
    [string]$AgentsDir = "agents",
    [string]$QdrantUrl = "http://localhost:6333",
    [string]$Collection = "agent_metadata",
    [switch]$Recreate
)

$ErrorActionPreference = "Stop"

Write-Host "🧠 Agent Metadata Indexer" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Find all manifest.json files
$manifests = Get-ChildItem -Path $AgentsDir -Filter "manifest.json" -Recurse -File |
Where-Object { $_.Directory.Name -match '^agent_' }

Write-Host "Found $($manifests.Count) agent manifests" -ForegroundColor Green

# Check if collection exists
Write-Host "`n📦 Checking Qdrant collection..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection" -Method Get -ErrorAction SilentlyContinue
    $collectionExists = $true
    Write-Host "  ✅ Collection '$Collection' exists" -ForegroundColor Green
    
    if ($Recreate) {
        Write-Host "  🗑️  Deleting collection (recreate mode)..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection" -Method Delete | Out-Null
        $collectionExists = $false
    }
}
catch {
    $collectionExists = $false
    Write-Host "  ℹ️  Collection '$Collection' does not exist" -ForegroundColor Gray
}

# Create collection if needed
if (-not $collectionExists) {
    Write-Host "  🔨 Creating collection '$Collection'..." -ForegroundColor Cyan
    
    $collectionConfig = @{
        vectors = @{
            size     = 1536  # text-embedding-3-small
            distance = "Cosine"
        }
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection" `
        -Method Put `
        -Body $collectionConfig `
        -ContentType "application/json" | Out-Null
    
    Write-Host "  ✅ Collection created" -ForegroundColor Green
}

# Index each manifest
Write-Host "`n📝 Indexing manifests..." -ForegroundColor Cyan
$indexed = 0
$errors = 0

foreach ($manifestFile in $manifests) {
    try {
        $manifest = Get-Content $manifestFile.FullName | ConvertFrom-Json
        $agentId = $manifest.id
        
        Write-Host "  Processing: $agentId" -ForegroundColor Gray
        
        # Build searchable text (description + actions + skills)
        $searchText = @(
            $manifest.description
            ($manifest.actions | ForEach-Object { "$($_.name): $($_.description)" }) -join " "
            ($manifest.skills_required -join " ")
            ($manifest.skills_optional -join " ")
        ) -join " "
        
        # Generate embedding using Python script
        $embeddingScript = @"
import sys
import json
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('all-MiniLM-L6-v2')
text = sys.stdin.read()
embedding = model.encode(text).tolist()
print(json.dumps(embedding))
"@
        
        $embedding = $searchText | python -c $embeddingScript | ConvertFrom-Json
        
        # Prepare payload
        $payload = @{
            id              = $agentId
            name            = $manifest.name
            role            = $manifest.role
            classification  = $manifest.classification
            evolution_level = $manifest.evolution_level
            description     = $manifest.description
            owner           = $manifest.owner
            version         = $manifest.version
            actions         = $manifest.actions | ForEach-Object { @{ name = $_.name; description = $_.description } }
            skills_required = $manifest.skills_required
            skills_optional = $manifest.skills_optional
            llm_provider    = $manifest.llm_config.provider
            llm_model       = $manifest.llm_config.model
        }
        
        # Upsert to Qdrant
        $point = @{
            points = @(
                @{
                    id      = $agentId
                    vector  = $embedding
                    payload = $payload
                }
            )
        } | ConvertTo-Json -Depth 10
        
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection/points?wait=true" `
            -Method Put `
            -Body $point `
            -ContentType "application/json" | Out-Null
        
        $indexed++
        Write-Host "    ✅ Indexed" -ForegroundColor Green
        
    }
    catch {
        $errors++
        Write-Host "    ❌ Error: $_" -ForegroundColor Red
    }
}

Write-Host "`n📊 Indexing Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Total manifests: $($manifests.Count)" -ForegroundColor White
Write-Host "  Successfully indexed: $indexed" -ForegroundColor Green
Write-Host "  Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "`n✅ Done!" -ForegroundColor Green
