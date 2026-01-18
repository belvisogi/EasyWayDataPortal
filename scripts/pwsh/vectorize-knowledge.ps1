<#
.SYNOPSIS
    Ingests Wiki and Manifests into the Vector Database.
    Part of the "Vectorization" phase.
#>

param(
    [string]$WikiRoot = "Wiki/EasyWayData.wiki",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$bridgeScript = Join-Path $PSScriptRoot "../python/chroma_bridge.py"

Write-Host "🧠 Starting Vectorization Process..." -ForegroundColor Cyan

# 1. Scan and Chunk Wiki
$files = Get-ChildItem -Path $WikiRoot -Recurse -Filter "*.md"
$documents = @()
$metadatas = @()
$ids = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    # Simple chunking by header (naive)
    $chunks = $content -split "(?m)^## "
    
    $i = 0
    foreach ($chunk in $chunks) {
        if ([string]::IsNullOrWhiteSpace($chunk)) { continue }
        
        # Clean up
        $text = "## " + $chunk.Trim()
        $id = "$($file.BaseName)_$i"
        
        $documents += $text
        $metadatas += @{ source = $file.Name; path = $file.FullName }
        $ids += $id
        $i++
    }
}

Write-Host "  > Found $($ids.Count) knowledge chunks." -ForegroundColor Gray

# 2. Call Python Bridge
$payload = @{
    documents = $documents
    metadatas = $metadatas
    ids = $ids
}

$jsonPayload = $payload | ConvertTo-Json -Depth 5 -Compress

# In a real container, we call python3. locally we check python availability
try {
    # Check if we can reach the bridge
    if (-not (Test-Path $bridgeScript)) { throw "Bridge script not found at $bridgeScript" }
    
    # We pipe json to python to avoid command line limits
    $jsonPayload | python $bridgeScript "upsert" | Out-Null
    Write-Host "✅ Ingestion Complete. Knowledge stored in Cortex." -ForegroundColor Green
} catch {
    Write-Warning "Failed to ingest vectors. Is Python/Chroma installed? (Runs best in Container)"
    Write-Warning $_
}
