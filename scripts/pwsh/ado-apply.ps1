<#
.SYNOPSIS
  L1 Executor: Riceve `execution_plan.json` ed esegue i task su ADO ciecamente.
.DESCRIPTION
  Secondo l'architettura Enterprise, L1 ("Il Robot") è 100% deterministico.
  Nessun calcolo, nessun parsing, nessuna intelligenza. Prende un piano
  certificato (L3) e lo esegue, o fallisce con errore se il piano è malformato
  o se l'API ADO risponde con un errore (es. permessi mancanti).
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutionPlanPath
)

$ErrorActionPreference = 'Stop'

function Read-Plan([string]$path) {
    if (-not (Test-Path $path)) { throw "Execution plan not found: $path" }
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

function Build-JsonPatch([string]$title, [string]$description, [string]$acceptanceCriteria, [string]$areaPath, [string]$iterationPath, [string[]]$tags) {
    $patch = @(
        @{ op = 'add'; path = '/fields/System.Title'; value = $title }
    )
    if ($description) { $patch += @{ op = 'add'; path = '/fields/System.Description'; value = $description } }
    if ($acceptanceCriteria) { $patch += @{ op = 'add'; path = '/fields/Microsoft.VSTS.Common.AcceptanceCriteria'; value = $acceptanceCriteria } }
    if ($areaPath) { $patch += @{ op = 'add'; path = '/fields/System.AreaPath'; value = $areaPath } }
    if ($iterationPath) { $patch += @{ op = 'add'; path = '/fields/System.IterationPath'; value = $iterationPath } }
    if ($tags -and $tags.Count -gt 0) { $patch += @{ op = 'add'; path = '/fields/System.Tags'; value = ($tags -join '; ') } }
    return $patch
}

function Create-WorkItem([string]$orgUrl, [string]$project, [string]$workItemType, [array]$patch, [hashtable]$headers, [string]$apiVersion) {
    $typeSeg = '$' + [uri]::EscapeDataString($workItemType)
    $url = Join-AdoUrl $orgUrl $project ("/_apis/wit/workitems/{0}?api-version={1}" -f $typeSeg, $apiVersion)
    $body = $patch | ConvertTo-Json -Depth 20
    return Invoke-RestMethod -Method Post -Uri $url -Headers $headers -ContentType 'application/json-patch+json' -Body $body
}

function Link-ParentChild([string]$orgUrl, [string]$project, [int]$childId, [int]$parentId, [hashtable]$headers, [string]$apiVersion) {
    $url = Join-AdoUrl $orgUrl $project ("/_apis/wit/workitems/{0}?api-version={1}" -f $childId, $apiVersion)
    $patch = @(
        @{
            op    = 'add'
            path  = '/relations/-'
            value = @{
                rel = 'System.LinkTypes.Hierarchy-Reverse'
                url = "$($orgUrl.TrimEnd('/'))/_apis/wit/workItems/$parentId"
            }
        }
    )
    $body = $patch | ConvertTo-Json -Depth 20 -AsArray
    $null = Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -ContentType 'application/json-patch+json' -Body $body
}

Write-Host "L1 Executor: Engaging System..."

$planDoc = Read-Plan $ExecutionPlanPath
$adoOrg = $planDoc.adoOrg
$adoProject = $planDoc.adoProject
$apiVersion = '7.0'

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = $PWD.Path }
$importSecretsScript = Join-Path $repoRoot "agents" "skills" "utilities" "Import-AgentSecrets.ps1"

if (-not (Test-Path $importSecretsScript)) {
    throw "CRITICAL L1 ERROR: Universal Token Broker not found at $importSecretsScript. Action Blocked."
}

. $importSecretsScript
$secrets = Import-AgentSecrets -AgentId "agent_executor"
$pat = if ($secrets.ContainsKey("AZURE_DEVOPS_EXT_PAT")) { $env:AZURE_DEVOPS_EXT_PAT } else { $null }

if (-not $pat) {
    # Fallback for terminal caching issues
    $executorEnvPath = "C:\old\.env.executor"
    if (Test-Path $executorEnvPath) {
        $pat = (Get-Content $executorEnvPath | Where-Object { $_ -match "^AZURE_DEVOPS_EXT_PAT=" } | ForEach-Object { ($_.Split("="))[1] })
    }
}
if (-not $pat) { throw "CRITICAL L1 ERROR: ADO_PAT not granted by Global Gatekeeper (RBAC_DENY). Action Blocked." }
$headers = Get-AdoAuthHeader $pat

# ID Map da tempId (es. -1, -2) a RealId (assegnato da ADO). 
# Necessario per fare il link alle ParentId create contestualmente.
$idMap = @{}

foreach ($task in $planDoc.plan) {
    if ($task.action -eq 'EXISTING') {
        Write-Host "  > SKIP: ($($task.type)) '$($task.title)' already exists as ID $($task.id)."
        continue
    }

    if ($task.action -eq 'CREATE') {
        Write-Host "  > EXECUTE: Create ($($task.type)) '$($task.title)'..."
        
        $patch = Build-JsonPatch -title $task.title -description $task.description -acceptanceCriteria $task.acceptanceCriteria -areaPath $task.areaPath -iterationPath $task.iterationPath -tags $task.tags
        $resp = Create-WorkItem -orgUrl $adoOrg -project $adoProject -workItemType $task.type -patch $patch -headers $headers -apiVersion $apiVersion
        $realId = [int]$resp.id
        $idMap["$($task.tempId)"] = $realId
        
        Write-Host "             Created ADO ID: $realId"

        if ($task.parentId) {
            $realParentId = $idMap["$($task.parentId)"]
            if (-not $realParentId) {
                # Se il parentId non è in mappa, assumiamo sia un ID reale (non generato in questo run).
                $realParentId = [int]$task.parentId
            }
            Write-Host "             > Linking child $realId to parent $realParentId..."
            Link-ParentChild -orgUrl $adoOrg -project $adoProject -childId $realId -parentId $realParentId -headers $headers -apiVersion $apiVersion
        }
    }
}

Write-Host "L1 Execution Complete."
