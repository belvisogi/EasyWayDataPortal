<#
.SYNOPSIS
  L3 Validator: Riceve `backlog.json`, interroga ADO in Read-Only e produce `execution_plan.json`
.DESCRIPTION
  Agisce come livello di ragionamento architetturale (L3). Non applica le modifiche, 
  ma calcola la differenza tra il backlog e la realtà (ADO).
  Produce un piano strettamente deterministico per lo step L1.
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$BacklogPath,
  
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'out/execution_plan.json',

    [string]$AdoOrgUrl = "https://dev.azure.com/EasyWayData",
    [string]$AdoProject = "EasyWay-DataPortal",
    [string]$AreaPath = "EasyWayDataPortal",
    [string]$IterationPath = "EasyWayDataPortal\Sprint 01"
)

$ErrorActionPreference = 'Stop'

function Read-Backlog([string]$path) {
    if (-not (Test-Path $path)) { throw "Backlog file not found: $path" }
    return (Get-Content -Raw -Path $path | ConvertFrom-Json)
}

function Get-AdoAuthHeader([string]$pat) {
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $pat))
    return @{ Authorization = "Basic $token" }
}

function Join-AdoUrl([string]$orgUrl, [string]$project, [string]$pathAndQuery) {
    $base = $orgUrl.TrimEnd('/')
    $projEnc = [uri]::EscapeDataString($project)
    return ("{0}/{1}{2}" -f $base, $projEnc, $pathAndQuery)
}

function Get-ExistingWorkItemByTitle([string]$orgUrl, [string]$project, [string]$workItemType, [string]$title, [string]$prdId, [hashtable]$headers, [string]$apiVersion) {
    $safeTitle = $title.Replace("'", "''")
    $wiql = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = '$workItemType' AND [System.Title] = '$safeTitle'"
    if ($prdId) {
        $wiql += " AND [System.Tags] CONTAINS 'PRD:$prdId'"
    }
    $postUrl = Join-AdoUrl $orgUrl $project ("/_apis/wit/wiql?api-version={0}" -f $apiVersion)
    try {
        $body = @{ query = $wiql } | ConvertTo-Json
        $resp = Invoke-RestMethod -Method Post -Uri $postUrl -Headers $headers -ContentType 'application/json' -Body $body
        if ($resp.workItems -and $resp.workItems.Count -gt 0) {
            return [int]$resp.workItems[0].id
        }
        return $null
    }
    catch {
        Write-Warning "Failed to query ADO. Assuming WorkItem doesn't exist. Error: $_"
        return $null
    }
}

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }
$importSecretsScript = Join-Path $repoRoot "agents" "skills" "utilities" "Import-AgentSecrets.ps1"

if (-not (Test-Path $importSecretsScript)) {
    Write-Warning "Universal Token Broker not found at $importSecretsScript. Running in Blind-Planner mode (assuming NO items exist)."
    $pat = $null
}
else {
    . $importSecretsScript
    $secrets = Import-AgentSecrets -AgentId "agent_planner"
    $pat = if ($secrets.ContainsKey("AZURE_DEVOPS_EXT_PAT")) { $env:AZURE_DEVOPS_EXT_PAT } else { $null }
}

if (-not $pat) {
    Write-Warning "ADO_PAT not granted by Global Gatekeeper (RBAC_DENY) or unavailable. Running in Blind-Planner mode."
}
else {
    $headers = Get-AdoAuthHeader $pat
}
$apiVersion = '7.0'

$backlog = Read-Backlog $BacklogPath
$prdId = $backlog.prdId

Write-Host "L3 Validation: Planning execution for PRD ID [$prdId]..."

$executionPlan = @()
$globalTags = @('AutoPRD', "PRD:$prdId")
$virtualIdCounter = -1

foreach ($epic in $backlog.epics) {
    $epicId = $null
    if ($pat) { $epicId = Get-ExistingWorkItemByTitle -orgUrl $AdoOrgUrl -project $AdoProject -workItemType 'Epic' -title $epic.title -prdId $prdId -headers $headers -apiVersion $apiVersion }
  
    if (-not $epicId) {
        $epicId = $virtualIdCounter--
        $executionPlan += [ordered]@{
            action        = 'CREATE'
            type          = 'Epic'
            tempId        = $epicId
            title         = $epic.title
            description   = $epic.description
            areaPath      = $AreaPath
            iterationPath = $IterationPath
            tags          = $globalTags
            parentId      = $null
        }
    }
    else {
        $executionPlan += [ordered]@{ action = 'EXISTING'; type = 'Epic'; id = $epicId; title = $epic.title }
    }

    foreach ($feature in $epic.features) {
        $featureId = $null
        if ($pat) { $featureId = Get-ExistingWorkItemByTitle -orgUrl $AdoOrgUrl -project $AdoProject -workItemType 'Feature' -title $feature.title -prdId $prdId -headers $headers -apiVersion $apiVersion }
    
        if (-not $featureId) {
            $featureId = $virtualIdCounter--
            $executionPlan += [ordered]@{
                action        = 'CREATE'
                type          = 'Feature'
                tempId        = $featureId
                title         = $feature.title
                description   = $feature.description
                areaPath      = $AreaPath
                iterationPath = $IterationPath
                tags          = $globalTags
                parentId      = $epicId
            }
        }
        else {
            $executionPlan += [ordered]@{ action = 'EXISTING'; type = 'Feature'; id = $featureId; title = $feature.title }
        }

        foreach ($pbi in $feature.pbis) {
            $pbiId = $null
            if ($pat) { $pbiId = Get-ExistingWorkItemByTitle -orgUrl $AdoOrgUrl -project $AdoProject -workItemType 'Product Backlog Item' -title $pbi.title -prdId $prdId -headers $headers -apiVersion $apiVersion }
      
            if (-not $pbiId) {
                $pbiId = $virtualIdCounter--
                $executionPlan += [ordered]@{
                    action             = 'CREATE'
                    type               = 'Product Backlog Item'
                    tempId             = $pbiId
                    title              = $pbi.title
                    description        = ''
                    acceptanceCriteria = $pbi.acceptanceCriteria
                    areaPath           = $AreaPath
                    iterationPath      = $IterationPath
                    tags               = $globalTags
                    parentId           = $featureId
                }
            }
            else {
                $executionPlan += [ordered]@{ action = 'EXISTING'; type = 'Product Backlog Item'; id = $pbiId; title = $pbi.title }
            }
        }
    }
}

$outDir = [IO.Path]::GetDirectoryName($OutputPath)
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$planDoc = [ordered]@{
    prdId         = $prdId
    adoOrg        = $AdoOrgUrl
    adoProject    = $AdoProject
    itemsToCreate = @($executionPlan | Where-Object action -eq 'CREATE').Count
    plan          = $executionPlan
}

$planDoc | ConvertTo-Json -Depth 30 -Compress | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "L3 Validation Complete. Plan saved to $OutputPath"
