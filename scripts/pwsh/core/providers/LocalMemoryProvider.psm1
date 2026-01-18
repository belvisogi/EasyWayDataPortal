
<#
.SYNOPSIS
    Local Memory Provider (Framework Edition).
    Uses JSON files and (optionally) local Vector DB.
#>

function Initialize-LocalMemory {
    param([string]$AgentName, [string]$AgentsDir)
    $memDir = Join-Path $AgentsDir "$AgentName/memory"
    if (-not (Test-Path $memDir)) { New-Item -ItemType Directory -Path $memDir -Force | Out-Null }
    
    $ctxFile = Join-Path $memDir "context.json"
    if (-not (Test-Path $ctxFile)) {
        @{
            created = (Get-Date).ToString("o")
            provider = "Local"
            stats = @{ runs = 0; errors = 0 }
        } | ConvertTo-Json | Set-Content -Path $ctxFile
    }
}

function Get-LocalContext {
    param([string]$AgentName, [string]$AgentsDir)
    $path = Join-Path $AgentsDir "$AgentName/memory/context.json"
    if (Test-Path $path) { return (Get-Content -Raw $path | ConvertFrom-Json) }
    return $null
}

function Set-LocalContext {
    param([string]$AgentName, [PSCustomObject]$Context, [string]$AgentsDir)
    $path = Join-Path $AgentsDir "$AgentName/memory/context.json"
    $Context | ConvertTo-Json -Depth 5 | Set-Content -Path $path
}

function Search-LocalMemoryVector {
    param([string]$Query, [int]$Limit=3)
    $bridgeScript = Join-Path $PSScriptRoot "../../python/chroma_bridge.py"
    
    if (-not (Test-Path $bridgeScript)) { return @() }
    
    $payload = @{ query = $Query; n = $Limit } | ConvertTo-Json -Compress
    try {
        $resultsJson = $payload | python $bridgeScript "query" 
        return ($resultsJson | ConvertFrom-Json)
    } catch {
        Write-Warning "Vector Search Failed: $_"
        return @()
    }
}

export-modulemember -function Initialize-LocalMemory, Get-LocalContext, Set-LocalContext, Search-LocalMemoryVector
