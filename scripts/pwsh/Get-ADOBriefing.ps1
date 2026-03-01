<#
  Get-ADOBriefing.ps1

  Layer 0 della strategia ADO Session Awareness (antifragile).
  Interroga ADO REST API e restituisce uno snapshot dello stato corrente:
    - PR aperte verso develop e main
    - PR completate nelle ultime 24h
    - SHA corrente di main e develop
    - Pipeline runs recenti (ultime 5)

  Chiamare come PRIMA azione di ogni sessione Claude Code.
  Riferimento: Wiki/EasyWayData.wiki/guides/ado-session-awareness.md

  Uso:
    pwsh scripts/pwsh/Get-ADOBriefing.ps1
    pwsh scripts/pwsh/Get-ADOBriefing.ps1 -Json
    pwsh scripts/pwsh/Get-ADOBriefing.ps1 -OnlyOpen
    pwsh scripts/pwsh/Get-ADOBriefing.ps1 -HoursBack 48
#>

Param(
    [string]  $Pat           = $env:AZURE_DEVOPS_EXT_PAT,
    [string]  $WorkItemsPat  = $env:ADO_WORKITEMS_PAT,
    [string]  $OrgUrl        = 'https://dev.azure.com/EasyWayData',
    [string]  $Project       = 'EasyWay-DataPortal',
    [string]  $Repo          = 'EasyWayDataPortal',
    [int]     $HoursBack     = 24,
    [switch]  $Json,
    [switch]  $OnlyOpen
)

$ErrorActionPreference = 'Stop'

# ── PAT: carica da .env.local se non passato esplicitamente ──────────────────
$envFile = 'C:\old\.env.local'
if (-not $Pat -and (Test-Path $envFile)) {
    Get-Content $envFile | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | ForEach-Object {
        $Pat = ($_ -split '=', 2)[1].Trim().Trim('"')
    }
}
if (-not $WorkItemsPat -and (Test-Path $envFile)) {
    Get-Content $envFile | Where-Object { $_ -match '^ADO_WORKITEMS_PAT=' } | ForEach-Object {
        $WorkItemsPat = ($_ -split '=', 2)[1].Trim().Trim('"')
    }
}

if (-not $Pat) {
    Write-Error "PAT non trovato. Impostare AZURE_DEVOPS_EXT_PAT o passare -Pat <token>."
    exit 1
}

# ── Auth headers ──────────────────────────────────────────────────────────────
$bytes   = [System.Text.Encoding]::UTF8.GetBytes(":$Pat")
$b64     = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json' }

# Work Items header (ADO_WORKITEMS_PAT — scope Work Items R/W)
$headersWI = $null
if ($WorkItemsPat) {
    $bytesWI  = [System.Text.Encoding]::UTF8.GetBytes(":$WorkItemsPat")
    $b64WI    = [System.Convert]::ToBase64String($bytesWI)
    $headersWI = @{ Authorization = "Basic $b64WI"; 'Content-Type' = 'application/json' }
}

$apiBase = "$OrgUrl/$Project/_apis"
$repoBase = "$apiBase/git/repositories/$Repo"

# ── Helper: call ADO REST ─────────────────────────────────────────────────────
function Invoke-ADO {
    param([string]$Url)
    try {
        return Invoke-RestMethod -Uri $Url -Headers $headers -Method Get
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Warning "ADO API error $code : $Url"
        return $null
    }
}

# ── 1. PR aperte ─────────────────────────────────────────────────────────────
$openPRs = Invoke-ADO "$repoBase/pullrequests?searchCriteria.status=active&`$top=50&api-version=7.1"
$openList = if ($openPRs) { $openPRs.value } else { @() }

# ── 2. PR completate nelle ultime N ore ──────────────────────────────────────
$completedList = @()
if (-not $OnlyOpen) {
    $since = (Get-Date).AddHours(-$HoursBack).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $completedPRs = Invoke-ADO "$repoBase/pullrequests?searchCriteria.status=completed&searchCriteria.minTime=$since&`$top=20&api-version=7.1"
    $completedList = if ($completedPRs) { $completedPRs.value } else { @() }
}

# ── 3. SHA branch principali ─────────────────────────────────────────────────
function Get-BranchSHA {
    param([string]$Branch)
    $r = Invoke-ADO "$repoBase/refs?filter=heads/$Branch&api-version=7.1"
    if ($r -and $r.value.Count -gt 0) { return $r.value[0].objectId.Substring(0, 8) }
    return '????????'
}

$mainSHA    = Get-BranchSHA 'main'
$developSHA = Get-BranchSHA 'develop'

# ── 4. Pipeline runs recenti ─────────────────────────────────────────────────
$buildsRaw = Invoke-ADO "$apiBase/build/builds?`$top=5&api-version=7.1"
$builds    = if ($buildsRaw) { $buildsRaw.value } else { @() }

# ── 5. PBI Approved in backlog (richiede ADO_WORKITEMS_PAT) ──────────────────
$approvedPBIs = @()
if ($headersWI) {
    try {
        $wiqlBody = '{"query":"SELECT [System.Id],[System.Title],[System.State],[System.Tags] FROM WorkItems WHERE [System.WorkItemType] = ''Product Backlog Item'' AND [System.State] = ''Approved'' ORDER BY [System.Id] ASC"}'
        $wiqlResp = Invoke-RestMethod -Uri "$OrgUrl/$Project/_apis/wit/wiql?api-version=7.1" `
            -Method POST -Headers $headersWI -Body $wiqlBody
        foreach ($wi in $wiqlResp.workItems) {
            $detail = Invoke-RestMethod -Uri "$OrgUrl/$Project/_apis/wit/workitems/$($wi.id)?api-version=7.1" `
                -Headers $headersWI
            $approvedPBIs += [ordered]@{
                id    = $wi.id
                title = $detail.fields.'System.Title'
                tags  = $detail.fields.'System.Tags'
            }
        }
    } catch {
        # Non blocca — Work Items PAT opzionale
    }
}

# ── Struttura dati output ─────────────────────────────────────────────────────
$snapshot = [ordered]@{
    generatedAt  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    hoursBack    = $HoursBack
    branches     = [ordered]@{
        main    = $mainSHA
        develop = $developSHA
    }
    openPRs      = @($openList | ForEach-Object {
        [ordered]@{
            id        = $_.pullRequestId
            title     = $_.title
            source    = $_.sourceRefName -replace 'refs/heads/', ''
            target    = $_.targetRefName -replace 'refs/heads/', ''
            author    = $_.createdBy.displayName
            created   = ([datetime]$_.creationDate).ToString('MM-dd HH:mm')
            isDraft   = $_.isDraft
        }
    })
    completedPRs = @($completedList | ForEach-Object {
        [ordered]@{
            id         = $_.pullRequestId
            title      = $_.title
            source     = $_.sourceRefName -replace 'refs/heads/', ''
            target     = $_.targetRefName -replace 'refs/heads/', ''
            mergedBy   = $_.closedBy.displayName
            closedAt   = ([datetime]$_.closedDate).ToString('MM-dd HH:mm')
        }
    })
    approvedPBIs = $approvedPBIs
    recentBuilds = @($builds | ForEach-Object {
        $dur = ''
        if ($_.startTime -and $_.finishTime) {
            $s = ([datetime]$_.finishTime - [datetime]$_.startTime).TotalMinutes
            $dur = "$([math]::Round($s, 1))min"
        }
        [ordered]@{
            id       = $_.id
            name     = $_.definition.name
            result   = if ($_.result) { $_.result } else { $_.status }
            branch   = $_.sourceBranch -replace 'refs/heads/', ''
            duration = $dur
            queued   = ([datetime]$_.queueTime).ToString('MM-dd HH:mm')
        }
    })
}

# ── Output JSON ───────────────────────────────────────────────────────────────
if ($Json) {
    $snapshot | ConvertTo-Json -Depth 5
    exit 0
}

# ── Output human-readable ─────────────────────────────────────────────────────
$SEP = '=' * 60

Write-Host ""
Write-Host $SEP
Write-Host "  ADO SESSION BRIEFING  --  $($snapshot.generatedAt)"
Write-Host $SEP

Write-Host ""
Write-Host "BRANCHES" -ForegroundColor Cyan
Write-Host "  main    : $mainSHA"
Write-Host "  develop : $developSHA"

Write-Host ""
Write-Host "PR APERTE ($($openList.Count))" -ForegroundColor Cyan
if ($openList.Count -eq 0) {
    Write-Host "  (nessuna)"
} else {
    foreach ($pr in $snapshot.openPRs) {
        $draft = if ($pr.isDraft) { ' [DRAFT]' } else { '' }
        Write-Host ("  #{0,-5} {1}" -f $pr.id, $pr.title) -ForegroundColor White
        Write-Host ("         {0} -> {1}  |  {2}  |  {3}{4}" -f $pr.source, $pr.target, $pr.author, $pr.created, $draft)
    }
}

if (-not $OnlyOpen) {
    Write-Host ""
    Write-Host "PR COMPLETATE - ultime ${HoursBack}h ($($completedList.Count))" -ForegroundColor Cyan
    if ($completedList.Count -eq 0) {
        Write-Host "  (nessuna)"
    } else {
        foreach ($pr in $snapshot.completedPRs) {
            Write-Host ("  #{0,-5} {1}" -f $pr.id, $pr.title) -ForegroundColor Green
            Write-Host ("         {0} -> {1}  |  merged by {2}  |  {3}" -f $pr.source, $pr.target, $pr.mergedBy, $pr.closedAt)
        }
    }
}

if ($approvedPBIs.Count -gt 0) {
    Write-Host ""
    Write-Host "BACKLOG APPROVATO — PBI pronti per sviluppo ($($approvedPBIs.Count))" -ForegroundColor Magenta
    foreach ($pbi in $approvedPBIs) {
        $tagStr = if ($pbi.tags) { "  [tags: $($pbi.tags)]" } else { '' }
        Write-Host ("  #{0,-5} {1}{2}" -f $pbi.id, $pbi.title, $tagStr) -ForegroundColor White
    }
}

Write-Host ""
Write-Host "PIPELINE RUNS RECENTI" -ForegroundColor Cyan
if ($builds.Count -eq 0) {
    Write-Host "  (nessuna)"
} else {
    foreach ($b in $snapshot.recentBuilds) {
        $color = switch ($b.result) {
            'succeeded' { 'Green' }
            'failed'    { 'Red' }
            'canceled'  { 'DarkYellow' }
            default     { 'Yellow' }
        }
        $dur = if ($b.duration) { "  [$($b.duration)]" } else { '' }
        Write-Host ("  #{0,-6} {1,-12} {2,-10} {3}{4}" -f $b.id, $b.result, $b.branch, $b.queued, $dur) -ForegroundColor $color
    }
}

Write-Host ""
Write-Host $SEP
Write-Host ""
