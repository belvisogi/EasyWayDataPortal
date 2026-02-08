<#
.SYNOPSIS
Builds the EasyWay Knowledge Graph from manifests, Wiki, and code

.DESCRIPTION
Crawls all data sources and constructs a comprehensive knowledge graph
with nodes (agents, skills, docs) and edges (relationships).
This is the core of agent_cartographer's intelligence.

.EXAMPLE
pwsh scripts/pwsh/build-knowledge-graph.ps1 -OutputPath agents/kb/knowledge-graph.json

.EXAMPLE
pwsh scripts/pwsh/build-knowledge-graph.ps1 -Verbose
#>

param(
    [string]$OutputPath = "agents/kb/knowledge-graph.json",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🗺️ Building EasyWay Knowledge Graph..." -ForegroundColor Cyan

# Initialize graph
$graph = @{
    version      = "1.0.0"
    last_updated = (Get-Date).ToString("o")
    metadata     = @{
        total_nodes = 0
        total_edges = 0
        node_types  = @("agent", "skill", "document", "api", "database", "infrastructure")
        edge_types  = @("uses", "depends_on", "implements", "references", "manages", "monitors")
        description = "EasyWay Knowledge Graph - maps all relationships in the ecosystem"
    }
    nodes        = @()
    edges        = @()
}

$edgeIdCounter = 0

# Helper function to create edge
function New-Edge {
    param($Source, $Target, $Type, $Properties = @{})
    
    $script:edgeIdCounter++
    return @{
        id         = "edge_$edgeIdCounter"
        source     = $Source
        target     = $Target
        type       = $Type
        properties = $Properties
    }
}

# 1. Extract Agent Nodes
Write-Host "  🤖 Extracting agent nodes..." -ForegroundColor Gray
$agentManifests = Get-ChildItem -Path "agents/agent_*/manifest.json" -ErrorAction SilentlyContinue

$agentCount = 0
foreach ($manifest in $agentManifests) {
    try {
        $data = Get-Content $manifest.FullName -Raw | ConvertFrom-Json
        
        $node = @{
            id         = $data.id
            type       = "agent"
            label      = if ($data.name) { $data.name } else { $data.id }
            properties = @{
                classification  = $data.classification
                evolution_level = $data.evolution_level
                owner           = $data.owner
                role            = $data.role
                version         = $data.version
                has_llm         = [bool]$data.llm_config
            }
        }
        
        $graph.nodes += $node
        $agentCount++
        
        # Create edges for skills
        if ($data.skills_required -and $data.skills_required.Count -gt 0) {
            foreach ($skill in $data.skills_required) {
                $skillId = if ($skill -is [string]) { 
                    "skill_$skill" 
                }
                else { 
                    "skill_$($skill.id)" 
                }
                
                $edge = New-Edge -Source $data.id -Target $skillId -Type "uses" -Properties @{ critical = $true }
                $graph.edges += $edge
            }
        }
        
        if ($Verbose) {
            Write-Host "    ✓ $($data.id)" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "Failed to process $($manifest.FullName): $_"
    }
}

Write-Host "    ✅ Extracted $agentCount agent nodes" -ForegroundColor Green

# 2. Extract Skill Nodes
Write-Host "  🛠️ Extracting skill nodes..." -ForegroundColor Gray
$skillsRegistryPath = "agents/skills/registry.json"

if (Test-Path $skillsRegistryPath) {
    try {
        $skillsRegistry = Get-Content $skillsRegistryPath -Raw | ConvertFrom-Json
        
        $skillCount = 0
        foreach ($skill in $skillsRegistry.skills) {
            $node = @{
                id         = "skill_$($skill.id)"
                type       = "skill"
                label      = $skill.name
                properties = @{
                    domain      = $skill.domain
                    version     = $skill.version
                    file        = $skill.file
                    description = $skill.description
                }
            }
            
            $graph.nodes += $node
            $skillCount++
            
            # Create edges for dependencies
            if ($skill.dependencies -and $skill.dependencies.Count -gt 0) {
                foreach ($dep in $skill.dependencies) {
                    # Dependencies are infrastructure nodes
                    $depId = "infra_$dep"
                    
                    # Create infrastructure node if not exists
                    $existingNode = $graph.nodes | Where-Object { $_.id -eq $depId }
                    if (-not $existingNode) {
                        $infraNode = @{
                            id         = $depId
                            type       = "infrastructure"
                            label      = $dep
                            properties = @{ category = "dependency" }
                        }
                        $graph.nodes += $infraNode
                    }
                    
                    $edge = New-Edge -Source "skill_$($skill.id)" -Target $depId -Type "depends_on"
                    $graph.edges += $edge
                }
            }
            
            if ($Verbose) {
                Write-Host "    ✓ $($skill.name)" -ForegroundColor DarkGray
            }
        }
        
        Write-Host "    ✅ Extracted $skillCount skill nodes" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to process skills registry: $_"
    }
}
else {
    Write-Warning "Skills registry not found at $skillsRegistryPath"
}

# 3. Extract Document Nodes (Wiki - top level only)
Write-Host "  📄 Extracting document nodes..." -ForegroundColor Gray
$wikiPath = "Wiki/EasyWayData.wiki"

if (Test-Path $wikiPath) {
    $wikiDocs = Get-ChildItem -Path $wikiPath -Filter "*.md" -File | Select-Object -First 50
    
    $docCount = 0
    foreach ($doc in $wikiDocs) {
        $docId = "doc_$($doc.BaseName -replace '[^a-zA-Z0-9_-]', '_')"
        
        $node = @{
            id         = $docId
            type       = "document"
            label      = $doc.BaseName
            properties = @{
                path      = $doc.FullName.Replace((Get-Location).Path, "").TrimStart('\')
                size      = $doc.Length
                extension = $doc.Extension
            }
        }
        
        $graph.nodes += $node
        $docCount++
        
        if ($Verbose) {
            Write-Host "    ✓ $($doc.BaseName)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "    ✅ Extracted $docCount document nodes" -ForegroundColor Green
}
else {
    Write-Warning "Wiki path not found at $wikiPath"
}

# 4. Extract Database Nodes
Write-Host "  🗄️ Adding database nodes..." -ForegroundColor Gray
$databases = @(
    @{ id = "db_sqlserver"; label = "SQL Server"; category = "relational" }
    @{ id = "db_qdrant"; label = "Qdrant Vector DB"; category = "vector" }
)

foreach ($db in $databases) {
    $node = @{
        id         = $db.id
        type       = "database"
        label      = $db.label
        properties = @{ category = $db.category }
    }
    $graph.nodes += $node
}

Write-Host "    ✅ Added $($databases.Count) database nodes" -ForegroundColor Green

# 5. Extract Infrastructure Nodes
Write-Host "  🏗️ Adding infrastructure nodes..." -ForegroundColor Gray
$infrastructure = @(
    @{ id = "infra_docker"; label = "Docker"; category = "container" }
    @{ id = "infra_caddy"; label = "Caddy"; category = "proxy" }
    @{ id = "infra_n8n"; label = "n8n"; category = "orchestration" }
)

foreach ($infra in $infrastructure) {
    # Check if already exists (from skill dependencies)
    $existing = $graph.nodes | Where-Object { $_.id -eq $infra.id }
    if (-not $existing) {
        $node = @{
            id         = $infra.id
            type       = "infrastructure"
            label      = $infra.label
            properties = @{ category = $infra.category }
        }
        $graph.nodes += $node
    }
}

Write-Host "    ✅ Added infrastructure nodes" -ForegroundColor Green

# 6. Create Agent → Database edges (heuristic)
Write-Host "  🔗 Creating database relationships..." -ForegroundColor Gray
$dbAgents = @("agent_dba", "agent_backend", "agent_infra")
foreach ($agentId in $dbAgents) {
    $agentExists = $graph.nodes | Where-Object { $_.id -eq $agentId }
    if ($agentExists) {
        $edge = New-Edge -Source $agentId -Target "db_sqlserver" -Type "manages"
        $graph.edges += $edge
    }
}

# RAG agents use Qdrant
$ragAgents = @("agent_retrieval", "agent_dba", "agent_docs_sync", "agent_pr_manager", "agent_security")
foreach ($agentId in $ragAgents) {
    $agentExists = $graph.nodes | Where-Object { $_.id -eq $agentId }
    if ($agentExists) {
        $edge = New-Edge -Source $agentId -Target "db_qdrant" -Type "uses"
        $graph.edges += $edge
    }
}

# 7. Update metadata
$graph.metadata.total_nodes = $graph.nodes.Count
$graph.metadata.total_edges = $graph.edges.Count

# 8. Save graph
Write-Host "`n💾 Saving knowledge graph to $OutputPath..." -ForegroundColor Cyan

# Ensure directory exists
$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$graph | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding utf8

Write-Host "✅ Knowledge Graph built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Graph Statistics:" -ForegroundColor Cyan
Write-Host "   Total Nodes: $($graph.metadata.total_nodes)" -ForegroundColor White
Write-Host "   Total Edges: $($graph.metadata.total_edges)" -ForegroundColor White
Write-Host ""
Write-Host "   Node Breakdown:" -ForegroundColor Gray
$nodesByType = $graph.nodes | Group-Object -Property type
foreach ($group in $nodesByType) {
    Write-Host "     - $($group.Name): $($group.Count)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "   Edge Breakdown:" -ForegroundColor Gray
$edgesByType = $graph.edges | Group-Object -Property type
foreach ($group in $edgesByType) {
    Write-Host "     - $($group.Name): $($group.Count)" -ForegroundColor DarkGray
}
