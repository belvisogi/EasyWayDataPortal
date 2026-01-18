<#
.SYNOPSIS
    Agent GEDI: OODA Loop Implementation (Memory-Enhanced)
    Observe, Orient, Decide, Act - Philosophical Guardian for EasyWay.

.DESCRIPTION
    This script operationalizes the GEDI philosophy by running an OODA loop:
    1. Observe: Takes Context and Intent as input.
    2. Orient: Matches input against EasyWay principles AND Memory Context.
    3. Decide: Determines severity and intervention mode.
    4. Act: Outputs guidance and updates Memory (Stats/Session).

.PARAMETER Context
    The situation description (e.g. "Planning sprint", "Deployment failure").

.PARAMETER Intent
    The proposed action (e.g. "Skip tests", "Force push").

.PARAMETER DryRun
    Simulation mode.
#>
param(
    [string]$Context,
    [string]$Intent,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ManifestPath = "agents/agent_gedi/manifest.json"

# Import Memory Core
Import-Module (Join-Path $PSScriptRoot "core/AgentMemory.psm1") -Force

function Get-Principles {
    if (Test-Path $ManifestPath) {
        $m = Get-Content $ManifestPath -Raw | ConvertFrom-Json
        return $m.principles
    }
    return $null
}

function Orient-Principles {
    param($Principles, $Text)
    $foundPrinciples = @()
    if (-not $Principles) { return $foundPrinciples }

    $Text = "$Context $Intent".ToLower()
    
    # Heuristic Matching
    if ($Text -match "speed|fast|quick|rush|deadline|asap") { $foundPrinciples += $Principles.quality_over_speed }
    if ($Text -match "deploy|release|prod|live") { $foundPrinciples += $Principles.measure_twice_cut_once }
    if ($Text -match "doc|wiki|explain|why") { $foundPrinciples += $Principles.journey_matters }
    if ($Text -match "code|refactor|legacy|clean") { $foundPrinciples += $Principles.tangible_legacy }
    if ($Text -match "fix|bug|issue|problem") { $foundPrinciples += $Principles.pragmatic_action }
    
    # Serendipity
    if ($foundPrinciples.Count -eq 0) {
        $names = $Principles.PSObject.Properties.Name
        $randomName = $names | Get-Random
        $foundPrinciples += $Principles.$randomName
    }
    
    return $foundPrinciples
}

# --- Runtime Start ---
$AgentName = "agent_gedi"
$AgentsDir = "agents" # Relative from project root assumption

# 1. Boot & Memory Init
Initialize-AgentMemory -AgentName $AgentName -AgentsDir $AgentsDir
$session = Start-AgentSession -AgentName $AgentName -Intent "$Intent (Context: $Context)" -AgentsDir $AgentsDir
$ctx = Get-AgentContext -AgentName $AgentName -AgentsDir $AgentsDir

Write-Host "🥋 GEDI (OODA Loop): Active | Run #$($ctx.stats.runs)" -ForegroundColor Cyan
if ($ctx.philosophy_context.current_mood) {
    Write-Host "   🧘 Mood: $($ctx.philosophy_context.current_mood)" -ForegroundColor DarkGray
}

Write-Host "   👁️  Observe: Context='$Context', Intent='$Intent'" -ForegroundColor Gray
Update-AgentSession -AgentName $AgentName -StepDescription "Observed Context/Intent" -AgentsDir $AgentsDir

# 2. Orient
$principles = Get-Principles
$relevantPrinciples = Orient-Principles -Principles $principles -Text "$Context $Intent"
Update-AgentSession -AgentName $AgentName -StepDescription "Oriented Principles: $($relevantPrinciples.Count) found" -AgentsDir $AgentsDir

# 3. Decide & Act
$interventions = 0
foreach ($p in $relevantPrinciples) {
    Write-Host "   🧭 Orient: Principle Selected - $($p.description)" -ForegroundColor Yellow
    Update-AgentSession -AgentName $AgentName -StepDescription "Principle Selected: $($p.description)" -AgentsDir $AgentsDir
    
    Write-Host "   ⚖️  Decide: Advice Generated" -ForegroundColor Gray
    Write-Host "   ⚡ Act:" -ForegroundColor Green
    Write-Host "      💬 Philosophy: $($p.philosophy)" -ForegroundColor Cyan
    Write-Host "      ❓ Check: $($p.checks[0])" -ForegroundColor White
    
    $interventions++
    
    # Update Context Stats (Persistent)
    $pName = $p.PSObject.Properties.Name # This might need refinement depending on object structure
    # For now, simplistic stats update
    $ctx.stats.interventions_count++
}

# 4. Reflect (End Session)
if ($interventions -gt 0) {
    $ctx.philosophy_context.last_wisdom_dispensed = (Get-Date).ToString("o")
}
Set-AgentContext -AgentName $AgentName -Context $ctx -AgentsDir $AgentsDir
Stop-AgentSession -AgentName $AgentName -AgentsDir $AgentsDir

# JSON Output
$result = @{
    ooda_state = "complete"
    context = $Context
    principles_applied = $relevantPrinciples.description
    memory_stats = $ctx.stats
}

return $result
