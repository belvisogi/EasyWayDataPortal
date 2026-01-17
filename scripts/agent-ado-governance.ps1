<#
  agent-ado-governance.ps1
  Agente per la governance di progetto Azure DevOps.
  Capabilities:
    - ado:project.structure (Areas, Iterations)
    - ado:check (Audit configurazioni - placeholder)
#>

Param(
    [ValidateSet('ado:project.structure', 'ado:teams.list', 'ado:team.areas', 'ado:team.iterations', 'ado:check', 'ado:intent.resolve')]
    [string]$Action,
  
    [string]$IntentPath,
    [switch]$NonInteractive,
    [switch]$WhatIf,
    [switch]$LogEvent,
    [switch]$Print,
    [string]$OutPath,
    [string]$Team,
    [string]$Query,
    [string]$WorkItemType,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Read-Intent($path) {
    if (-not $path) { return $null }
    if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
    (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Out-Result($obj) { $obj | ConvertTo-Json -Depth 20 -Compress | Write-Output }

# --- AUTH JS ---
# (Duplicated strictly for standalone execution capability)
function Get-AdoAuthHeader([string]$pat) {
    if (-not $pat) { throw "PAT is empty" }
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))
    return @{ Authorization = ("Basic {0}" -f $base64AuthInfo) }
}

function Join-AdoUrl([string]$root, [string]$proj, [string]$suffix) {
    $root = $root.TrimEnd('/')
    # If project handled in suffix or root, adjust logic. Standard: org/project/_apis...
    # ADO urls: https://dev.azure.com/{org}/{project}/_apis/...
    return "$root/$proj/$suffix"
}

# --- MAIN ---

$intent = Read-Intent $IntentPath
$p = if ($null -ne $intent) { $intent.params } else { @{} }
if ($OutPath) { $p.outPath = $OutPath }
# Map script parameters to internal dictionary if provided via CLI args (for Team actions)
if ($PSBoundParameters['Team']) { $p.team = $PSBoundParameters['Team'] }
if ($PSBoundParameters['Query']) { $p.query = $PSBoundParameters['Query'] }
if ($PSBoundParameters['WorkItemType']) { $p.workItemType = $PSBoundParameters['WorkItemType'] }
if ($PSBoundParameters['Force']) { $p.force = $true }


# Auto-discovery Config (Generic)
$orgUrl = $p.ado?.org
$project = $p.ado?.project
$pat = $p.ado?.pat

if (-not $orgUrl -or -not $project -or -not $pat) {
    $configDir = Join-Path (Split-Path $PSScriptRoot -Parent) '../../Rules.Vault/config' # Adjust relative path
    # Try different relative path if running from Rules.Vault directly
    if (-not (Test-Path $configDir)) { $configDir = Join-Path (Split-Path $PSScriptRoot -Parent) '../config' }
    
    $connPath = Join-Path $configDir 'connections.json'; $secPath = Join-Path $configDir 'secrets.json'
    if (Test-Path $connPath) {
        $conns = (Get-Content $connPath -Raw | ConvertFrom-Json); $connDict = if ($conns.connections) { $conns.connections } else { $conns }
        foreach ($key in $connDict.PSObject.Properties.Name) { if ($connDict.$key.type -eq 'ado') { if (-not $orgUrl) { $orgUrl = $connDict.$key.org }; if (-not $project) { $project = $connDict.$key.project }; break } }
    }
    if (Test-Path $secPath) {
        $secs = (Get-Content $secPath -Raw | ConvertFrom-Json); $secDict = if ($secs.secrets) { $secs.secrets } else { $secs }
        foreach ($key in $secDict.PSObject.Properties.Name) { if ($secDict.$key.pat -and -not $pat) { $pat = $secDict.$key.pat; break } }
    }
    if (-not $pat) { $pat = $env:ADO_PAT }
}

if (-not $orgUrl) { Write-Error "ADO Org URL not found."; exit 1 }
if (-not $project) { Write-Error "ADO Project not found."; exit 2 }
if (-not $pat) { Write-Error "ADO PAT not found."; exit 3 }

$headers = Get-AdoAuthHeader $pat
$apiVersion = '7.0'

switch ($Action) {
    'ado:project.structure' {
        # Fetch Classification Nodes (Areas and Iterations)
        # https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/classification-nodes/get-root-nodes?view=azure-devops-rest-7.0
        
        $url = "$orgUrl/$project/_apis/wit/classificationnodes?`$depth=5&api-version=$apiVersion"
        try {
            $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
            
            $nodes = $resp.value
            $structure = @{
                Areas      = @()
                Iterations = @()
            }
            
            # Helper to flatten/simplify
            function ConvertTo-FlatNodes($nodeList, $type) {
                $out = @()
                foreach ($n in $nodeList) {
                    $item = [ordered]@{
                        Name          = $n.name
                        Path          = if ($n.path) { $n.path } else { $n.name } # Sometimes path is missing in root
                        StructureType = $n.structureType
                        ChildrenCount = if ($n.children) { $n.children.Count } else { 0 }
                    }
                    if ($type -eq 'iteration' -and $n.attributes) {
                        $item['StartDate'] = $n.attributes.startDate
                        $item['FinishDate'] = $n.attributes.finishDate
                    }
                    $out += $item
                    
                    if ($n.children) {
                        $out += ConvertTo-FlatNodes $n.children $type
                    }
                }
                return $out
            }

            foreach ($rootNode in $nodes) {
                if ($rootNode.structureType -eq 'area') {
                    $structure.Areas = ConvertTo-FlatNodes @($rootNode) 'area'
                }
                elseif ($rootNode.structureType -eq 'iteration') {
                    $structure.Iterations = ConvertTo-FlatNodes @($rootNode) 'iteration'
                }
            }

            if ($Print) {
                Write-Host "`n🏗️  Project Structure: $project`n" -ForegroundColor Cyan
                Write-Host "📂 Areas ($($structure.Areas.Count))" -ForegroundColor Yellow
                $structure.Areas | Format-Table -AutoSize | Out-String | Write-Host
                
                Write-Host "`n⏱️  Iterations ($($structure.Iterations.Count))" -ForegroundColor Yellow
                $structure.Iterations | Format-Table -AutoSize | Out-String | Write-Host
            }
            else {
                Out-Result $structure
            }
        }
        catch {
            $err = $_.Exception.Message
            Out-Result @{ ok = $false; error = $err }
        }
    }
    
    'ado:teams.list' {
        # Fetch Project Teams
        # https://learn.microsoft.com/en-us/rest/api/azure/devops/core/teams/get-teams?view=azure-devops-rest-7.0
        
        $url = "$orgUrl/_apis/projects/$project/teams?api-version=$apiVersion"
        try {
            $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
            $teams = $resp.value | Select-Object id, name, description, url

            if ($Print) {
                Write-Host "`n👥 Teams found in $project ($($teams.Count))`n" -ForegroundColor Cyan
                $teams | Format-Table id, name, description -AutoSize | Out-String | Write-Host
            }
            else {
                Out-Result $teams
            }
        }
        catch {
            $err = $_.Exception.Message
            Out-Result @{ ok = $false; error = $err }
        }
    }

    'ado:team.areas' {
        # Fetch Team-specific Areas
        # GET https://dev.azure.com/{org}/{project}/{team}/_apis/work/teamsettings/teamfieldvalues?api-version=7.0
        
        $team = $p.team
        if (-not $team) { throw "Parameter -Team is required for this action." }
        
        $url = "$orgUrl/$project/$team/_apis/work/teamsettings/teamfieldvalues?api-version=$apiVersion"
        try {
            $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
            $values = $resp.values | Select-Object value, includeChildren
            
            if ($Print) {
                Write-Host "`n📁 Areas for Team '$team'`n" -ForegroundColor Cyan
                $values | Format-Table -AutoSize | Out-String | Write-Host
            }
            else { Out-Result $values }
        }
        catch { Out-Result @{ ok = $false; error = $_.Exception.Message } }
    }

    'ado:team.iterations' {
        # Fetch Team-specific Iterations
        # GET https://dev.azure.com/{org}/{project}/{team}/_apis/work/teamsettings/iterations?api-version=7.0
        
        $team = $p.team
        if (-not $team) { throw "Parameter -Team is required for this action." }
        
        $url = "$orgUrl/$project/$team/_apis/work/teamsettings/iterations?api-version=$apiVersion"
        try {
            $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
            $iters = $resp.value | Select-Object name, path, @{N = 'startDate'; E = { $_.attributes.startDate } }, @{N = 'finishDate'; E = { $_.attributes.finishDate } }
            
            if ($Print) {
                Write-Host "`n📅 Iterations for Team '$team'`n" -ForegroundColor Cyan
                $iters | Format-Table -AutoSize | Out-String | Write-Host
            }
            else { Out-Result $iters }
        }
        catch { Out-Result @{ ok = $false; error = $_.Exception.Message } }
    }

    'ado:check' {
        # Placeholder for audit logic
        Write-Host "TODO: Checks governance settings"
    }

    'ado:intent.resolve' {
        # GOVERNANCE DECISION LAYER
        # Decides whether to execute query via Scrum Master or ask for clarification.
        
        $q = $intent.params.query ?? $p.query
        $wit = $intent.params.workItemType ?? $p.workItemType
        $force = $intent.params.force ?? $p.force ?? $false
        
        # 1. Analyze Intent
        # Matches: [System.Id] = 123 OR System.Id = 123 OR [System.Id] IN (1,2)
        $isSpecific = $q -match 'System\.Id\]?\s*(=|IN)' 
        $hasScope = $q -match 'System\.AreaPath' -or $q -match 'System\.IterationPath' -or $q -match 'System\.Tags'
        
        if ($isSpecific -or $hasScope -or $force) {
            # DECISION: Safe to Execute -> Delegate to Scrum Master
            $smScript = "$PSScriptRoot/agent-ado-scrummaster.ps1"
            if (-not (Test-Path $smScript)) { throw "Scrum Master agent not found at $smScript" }
            
            Write-Host "🤖 Governance Decision: Query is specific/forced. Delegating to Scrum Master..." -ForegroundColor DarkGray
            
            $argsList = @('-Action', 'ado:userstory.export', '-WorkItemType', $wit, '-Query', $q)
            if ($Print) { $argsList += '-Print' }
            if ($force) { $argsList += '-Force' }
            
            & pwsh -NoProfile -File $smScript @argsList
        }
        else {
            # DECISION: Ambiguous -> Governance Logic
            Write-Warning "🚧 Governance Intercept: Ambiguous Query detected (No specific ID or Scope)."
            
            # Fetch Areas (Internal call to prevent external overhead)
            $areas = & pwsh -NoProfile -File $PSCommandPath -Action 'ado:project.structure' | ConvertFrom-Json
            $areaNodes = $areas.Areas | Sort-Object Name

            if (-not $NonInteractive) {
                Write-Host "`n📍 Ambiguous Scope. Please select a Target Area:" -ForegroundColor Cyan
                $i = 1
                foreach ($a in $areaNodes) {
                    Write-Host "   [$i] $($a.Name) ($($a.Path))"
                    $i++
                }
                Write-Host "   [0] Cancel / Show All"
                
                $selection = Read-Host "`nSelect Area Index"
                if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $areaNodes.Count) {
                    $selectedArea = $areaNodes[$selection - 1]
                    Write-Host "✅ Scoping to Area: $($selectedArea.Path)" -ForegroundColor Green
                    
                    # Refine Query
                    # Remove generic WHERE, or append AND
                    if ($q -notmatch 'WHERE') { $q += " WHERE [System.AreaPath] UNDER '$($selectedArea.Path)'" }
                    else { $q += " AND [System.AreaPath] UNDER '$($selectedArea.Path)'" }
                    
                    # Log refined intent
                    Write-Verbose "Refined Query: $q"
                    
                    # Execute Delegate
                    $smScript = "$PSScriptRoot/agent-ado-scrummaster.ps1"
                    $argsList = @('-Action', 'ado:userstory.export', '-WorkItemType', $wit, '-Query', $q)
                    if ($Print) { $argsList += '-Print' }
                    if ($force) { $argsList += '-Force' } # Pass force to bypass SM check if any
                    
                    & pwsh -NoProfile -File $smScript @argsList
                    return
                }
            }
            
            # Fallback (Non-Interactive or Cancel)
            Write-Warning "   Query '$q' is broad. Use --Interactive to select specific Area or provide -Query with [System.AreaPath]."
            Write-Warning "   Available Areas: $($areaNodes.Name -join ', ')"
            
            # Self-call to listed teams as backup guidance
            # & pwsh -NoProfile -File $PSCommandPath -Action 'ado:teams.list' -Print
            return
        }
    }
}
