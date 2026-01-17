<#
  adosearch.ps1
  Interactive ADO Search Wizard.
  Flow: Team -> Area -> Iteration -> Query -> Scrum Master
#>

Param(
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

# Helper to run governance actions
function Call-Governance {
    param($Action, $Team = $null)
    # Construct arguments for standalone pwsh execution
    $passArgs = @("-NoProfile", "-File", "$PSScriptRoot/agent-ado-governance.ps1", "-Action", $Action)
    if ($Team) { $passArgs += ("-Team", $Team) }
    
    # Run in new pwsh ensures clean environment
    $json = pwsh @passArgs
    if (-not $json) { return $null }
    try {
        return $json | ConvertFrom-Json
    }
    catch {
        Write-Warning "Failed to parse JSON from governance. Raw output:"
        Write-Warning $json
        return $null
    }
}

function Ask-Choice {
    param($Title, $Options, $LabelProperty = 'name')
    Write-Host "`n🔵 $Title" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $opt = $Options[$i]
        $label = if ($LabelProperty) { $opt.$LabelProperty } else { $opt }
        Write-Host "  [$($i+1)] $label"
    }
    
    while ($true) {
        $idx = Read-Host "  Select (1-$($Options.Count))"
        if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $Options.Count) {
            return $Options[[int]$idx - 1]
        }
        Write-Warning "Invalid selection."
    }
}

Write-Host "`n🚀 ADO Search Wizard`n" -ForegroundColor Green

# 1. Select Team
Write-Host "Fetching Teams..." -ForegroundColor Gray
$teams = Call-Governance -Action 'ado:teams.list'
if (-not $teams) { throw "No teams found." }

$selectedTeam = Ask-Choice -Title "Select Team" -Options $teams -LabelProperty 'name'
$teamName = $selectedTeam.name
Write-Host "✅ Selected Team: $teamName" -ForegroundColor Cyan

# 2. Select Area
Write-Host "Fetching Areas for $teamName..." -ForegroundColor Gray
$areas = Call-Governance -Action 'ado:team.areas' -Team $teamName
if (-not $areas) { 
    Write-Warning "No specific areas found for team. Using default project context."
    # Fallback logic could go here
}
else {
    $selectedArea = Ask-Choice -Title "Select Area" -Options $areas -LabelProperty 'value'
    $areaPath = $selectedArea.value
    Write-Host "✅ Selected Area: $areaPath" -ForegroundColor Cyan
}

# 3. Select Iteration (Optional)
Write-Host "Fetching Iterations for $teamName..." -ForegroundColor Gray
$iters = Call-Governance -Action 'ado:team.iterations' -Team $teamName
$currentIter = $iters | Where-Object { 
    $now = Get-Date
    $start = [DateTime]$_.startDate
    $end = [DateTime]$_.finishDate
    return $now -ge $start -and $now -le $end
}

$iterChoice = "All Backlog"
if ($currentIter) {
    $q = Read-Host "`nFilter by current iteration '$($currentIter.name)'? (Y/n)"
    if ($q -ne 'n') { $iterChoice = $currentIter.path }
}

# 4. Construct Query
$wiql = "SELECT [System.Id], [System.Title], [System.State], [System.Tags], [System.AssignedTo] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] IN ('Product Backlog Item', 'Bug')"

if ($areaPath) {
    if ($selectedArea.includeChildren) {
        $wiql += " AND [System.AreaPath] UNDER '$areaPath'"
    }
    else {
        $wiql += " AND [System.AreaPath] = '$areaPath'"
    }
}

if ($iterChoice -ne "All Backlog") {
    $wiql += " AND [System.IterationPath] = '$iterChoice'"
}

Write-Host "`n🔍 Generated Query:" -ForegroundColor Gray
Write-Host $wiql -ForegroundColor Yellow

# 5. Execute Scrum Master
$conf = Read-Host "`nExecute Search? (Y/n)"
if ($conf -ne 'n') {
    $argsList = @(
        "-Action", "ado:userstory.export",
        "-Query", $wiql,
        "-Print"
    )
    pwsh "$PSScriptRoot/agent-ado-scrummaster.ps1" @argsList
}
