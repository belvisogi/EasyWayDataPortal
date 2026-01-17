# generate-roster-json.ps1
# Aggregates all Agent Manifests into a single JSON file for the PWA Frontend.

$ErrorActionPreference = 'Stop'

$agentsDir = Join-Path $PSScriptRoot '../agents'
$frontendDir = Join-Path $PSScriptRoot '../agents/agent_frontend/data'
if (-not (Test-Path $frontendDir)) { New-Item -ItemType Directory -Force -Path $frontendDir | Out-Null }

$outFile = Join-Path $frontendDir 'roster.json'

$rosterData = @{
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    agents = @()
    stats = @{
        brains = 0
        arms = 0
        total = 0
    }
}

$agents = Get-ChildItem $agentsDir -Directory | Sort-Object Name
foreach ($agent in $agents) {
    if ($agent.Name -eq 'agent_frontend') { continue } # Skip self? Maybe keep. Let's keep.
    
    $manifestPath = Join-Path $agent.FullName 'manifest.json'
    if (Test-Path $manifestPath) {
        try {
            $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
            
            # Normalization Logic
            $class = ($m.classification ?? "arm").ToLower()
            $model = "Default"
            $tools = @()
            $osTools = @()
            
            if ($m.llm_config -and $m.llm_config.model) { $model = $m.llm_config.model }
            if ($m.llm_config -and $m.llm_config.tools) { $tools = $m.llm_config.tools }
            if ($m.allowed_tools) { $osTools = $m.allowed_tools }
            
            # Safe Actions Check
            $actions = @()
            if ($m.actions) {
                foreach ($act in $m.actions) {
                     if ($act -is [string]) { $actions += $act } else { $actions += $act.name }
                }
            }

            $agentObj = @{
                id = $agent.Name
                name = ($m.name ?? $agent.Name)
                role = ($m.role ?? "Specialist")
                classification = $class
                description = ($m.description ?? "No description.")
                owner = ($m.owner ?? "Platform Team")
                model = $model
                tools = $tools
                os_tools = $osTools
                actions = $actions
                icon = "🤖" # Default
            }

            # Icon Logic for UI
            if ($class -eq 'brain') { $agentObj.icon = "🧠" }
            if ($agent.Name -match 'gedi') { $agentObj.icon = "⚖️" }
            if ($agent.Name -match 'security') { $agentObj.icon = "🛡️" }
            
            $rosterData.agents += $agentObj
            
            if ($class -eq 'brain') { $rosterData.stats.brains++ } else { $rosterData.stats.arms++ }

        } catch {
            Write-Warning "Failed to parse manifest for $($agent.Name)"
        }
    }
}

$rosterData.stats.total = $rosterData.agents.Count

$rosterData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Roster JSON generated at: $outFile" -ForegroundColor Green
Write-Host "Stats: $($rosterData.stats.brains) Brains, $($rosterData.stats.arms) Arms." -ForegroundColor Cyan
