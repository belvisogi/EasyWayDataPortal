<#
.SYNOPSIS
    Agent GEDI: OODA Loop Implementation
    Observe, Orient, Decide, Act - Philosophical Guardian for EasyWay.

.DESCRIPTION
    This script operationalizes the GEDI philosophy by running an OODA loop:
    1. Observe: Takes Context and Intent as input.
    2. Orient: Matches input against EasyWay principles (loaded from manifest).
    3. Decide: Determines severity and intervention mode.
    4. Act: Outputs guidance, warnings, or blocking gates.

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
    
    # Heuristic Matching (Simulating Semantic Search)
    if ($Text -match "speed|fast|quick|rush|deadline|asap") { $foundPrinciples += $Principles.quality_over_speed }
    if ($Text -match "deploy|release|prod|live") { $foundPrinciples += $Principles.measure_twice_cut_once }
    if ($Text -match "doc|wiki|explain|why") { $foundPrinciples += $Principles.journey_matters }
    if ($Text -match "code|refactor|legacy|clean") { $foundPrinciples += $Principles.tangible_legacy }
    if ($Text -match "fix|bug|issue|problem") { $foundPrinciples += $Principles.pragmatic_action }
    
    # Default if no match: Serendipity (Pick one random)
    if ($foundPrinciples.Count -eq 0) {
        $names = $Principles.PSObject.Properties.Name
        $randomName = $names | Get-Random
        $foundPrinciples += $Principles.$randomName
    }
    
    return $foundPrinciples
}

Write-Host "🥋 GEDI (OODA Loop): Active" -ForegroundColor Cyan
Write-Host "   👁️  Observe: Context='$Context', Intent='$Intent'" -ForegroundColor Gray

# 1. Orient
$principles = Get-Principles
$relevantPrinciples = Orient-Principles -Principles $principles -Text "$Context $Intent"

# 2. Decide & 3. Act
foreach ($p in $relevantPrinciples) {
    Write-Host "   🧭 Orient: Principle Selected - $($p.description)" -ForegroundColor Yellow
    
    Write-Host "   ⚖️  Decide: Advice Generated" -ForegroundColor Gray
    Write-Host "   ⚡ Act:" -ForegroundColor Green
    Write-Host "      💬 Philosophy: $($p.philosophy)" -ForegroundColor Cyan
    Write-Host "      ❓ Check: $($p.checks[0])" -ForegroundColor White
    
    if ($DryRun) {
        Write-Host "      (DryRun: No blocking action taken)" -ForegroundColor DarkGray
    }
}

# JSON Output for programmatic integration
$result = @{
    ooda_state = "complete"
    context = $Context
    principles_applied = $relevantPrinciples.description
}

if (-not $DryRun) {
    # Logging legacy side-effect if needed
}

return $result
