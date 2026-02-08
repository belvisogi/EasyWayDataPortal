<#
.SYNOPSIS
Butterfly Effect Analysis - simulates cascade impacts of changes

.DESCRIPTION
Given a change (e.g., "modify RLS policy"), analyzes the knowledge graph
to determine all affected components and cascade depth.
This is the "soul" of Agent Cartographer.

.PARAMETER Change
The description of the change to analyze.

.PARAMETER MaxDepth
Maximum recursion depth for the impact analysis (default: 5).

.PARAMETER GraphPath
Path to the knowledge-graph.json file.

.EXAMPLE
& ./Invoke-ImpactAnalysis.ps1 -Change "Modify RLS policy in dbo.Users" -MaxDepth 3
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Change,
    
    [int]$MaxDepth = 5,
    
    [string]$GraphPath = "c:/old/EasyWayDataPortal/agents/kb/knowledge-graph.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $GraphPath)) {
    throw "Knowledge Graph not found at $GraphPath. Run build-knowledge-graph.ps1 first."
}

# Load graph
$graph = Get-Content $GraphPath -Raw | ConvertFrom-Json

# Heuristic Mapping: Match change description to node IDs
# In a real scenario, this would be an LLM task, but here we use the logic
# to find a starting node for the graph traversal.
$affectedNodeId = $null

# 1. Direct Agent Matching
if ($Change -match "agent_(\w+)") {
    $potentialId = "agent_$($Matches[1])"
    $node = $graph.nodes | Where-Object { $_.id -eq $potentialId }
    if ($node) { $affectedNodeId = $potentialId }
}

# 2. Skill Matching
if (-not $affectedNodeId -and $Change -match "skill_(\w+)") {
    $potentialId = "skill_$($Matches[1])"
    $node = $graph.nodes | Where-Object { $_.id -eq $potentialId }
    if ($node) { $affectedNodeId = $potentialId }
}

# 3. Keyword Matching (Heuristic)
if (-not $affectedNodeId) {
    if ($Change -match "RLS|policy|database|SQL|table") {
        $affectedNodeId = "db_sqlserver"
    }
    elseif ($Change -match "RAG|search|vector|Qdrant") {
        $affectedNodeId = "db_qdrant"
    }
    elseif ($Change -match "Docker|container") {
        $affectedNodeId = "infra_docker"
    }
    elseif ($Change -match "Wiki|documentation") {
        # Default to a generic doc or infrastructure if not specific
        $affectedNodeId = "infra_n8n" # Orchestration
    }
}

if (-not $affectedNodeId) {
    # If no specific node found, return empty impact or error?
    # For now, let's pick the first node found as a fallback or return error
    return @{
        success = $false
        error = "Could not identify the starting point of the impact for: $Change"
    } | ConvertTo-Json
}

# BFS traversal to find cascade (Impact Analysis)
$visited = @{}
$queue = @()
$queue += ,@{ node = $affectedNodeId; depth = 0 }
$impactedNodes = @()

while ($queue.Count -gt 0) {
    $current = $queue[0]
    $queue = $queue[1..($queue.Count-1)]
    
    if ($visited.ContainsKey($current.node)) { continue }
    $visited[$current.node] = $true
    
    # Enrich node info
    $nodeInfo = $graph.nodes | Where-Object { $_.id -eq $current.node }
    
    $impactedNodes += @{
        id = $current.node
        label = $nodeInfo.label
        type = $nodeInfo.type
        depth = $current.depth
    }
    
    if ($current.depth -ge $MaxDepth) { continue }
    
    # IMPACT DIRECTION: Find who DEPENDS ON the current node
    # In our graph, edges are: Source (User) --uses/depends_on--> Target (Provider)
    # Impact flows from Target back to Source (In-Edges)
    
    $reverseEdges = $graph.edges | Where-Object { $_.target -eq $current.node }
    foreach ($edge in $reverseEdges) {
        $queue += ,@{ node = $edge.source; depth = $current.depth + 1 }
    }
}

# Output result
$result = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    analysis_type = "Butterfly Effect"
    change_intent = $Change
    starting_node = $affectedNodeId
    summary = @{
        total_impacted = $impactedNodes.Count
        max_depth = if ($impactedNodes.Count -gt 0) { ($impactedNodes | Measure-Object -Property depth -Maximum).Maximum } else { 0 }
    }
    impacted_components = $impactedNodes | Sort-Object depth
}

return $result | ConvertTo-Json -Depth 10
