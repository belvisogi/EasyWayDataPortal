<#
  Create-ReleasePR.ps1

  Crea una Release PR da develop verso main su Azure DevOps con:
    - Titolo auto-generato: "[Release] Session N — develop→main"
    - Descrizione auto-generata: tabella PR mergeate su develop + delta SHA + checklist deploy
    - Governance integrata: blocca source≠develop e target≠main
    - Merge strategy: noFastForward (coerente con policy branch protetti)

  Registrata come skill "devops.create-release-pr" in agents/skills/registry.json.
  Chiamabile da agenti (agent_scrummaster, agent_pr_gate) o da umano.

  Uso:
    pwsh scripts/pwsh/Create-ReleasePR.ps1 -WhatIf          # dry-run
    pwsh scripts/pwsh/Create-ReleasePR.ps1 -WhatIf -Json    # dry-run machine-readable
    pwsh scripts/pwsh/Create-ReleasePR.ps1                  # crea PR reale
    pwsh scripts/pwsh/Create-ReleasePR.ps1 -SessionLabel "Session 37"
#>

param(
    [string] $SourceBranch = "develop",
    [string] $TargetBranch = "main",
    [string] $SessionLabel = "",       # se vuoto → auto-detect dall'ultima Release PR su main
    [string] $Pat          = $env:AZURE_DEVOPS_EXT_PAT,
    [switch] $WhatIf,                  # stampa titolo+descrizione senza creare la PR
    [switch] $Json                     # output JSON (per agent consumption)
)

$ErrorActionPreference = 'Stop'

# ── Costanti ADO ─────────────────────────────────────────────────────────────
$OrgUrl   = 'https://dev.azure.com/EasyWayData'
$Project  = 'EasyWay-DataPortal'
$RepoId   = 'EasyWayDataPortal'
$ApiBase  = "$OrgUrl/$Project/_apis"
$RepoBase = "$ApiBase/git/repositories/$RepoId"

# ── Load PAT ─────────────────────────────────────────────────────────────────
if (-not $Pat) {
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        $line = Get-Content $envFile | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | Select-Object -First 1
        if ($line) { $Pat = ($line -split '=', 2)[1].Trim().Trim('"') }
    }
}
if (-not $Pat) {
    Write-Error "PAT non trovato. Impostare AZURE_DEVOPS_EXT_PAT o passare -Pat <token>."
    exit 1
}

# ── Auth header ───────────────────────────────────────────────────────────────
$bytes   = [System.Text.Encoding]::UTF8.GetBytes(":$Pat")
$b64     = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json' }

# ── Helper: GET ADO REST ──────────────────────────────────────────────────────
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

# ── Governance check ─────────────────────────────────────────────────────────
if ($SourceBranch -notin @('develop') -and $SourceBranch -notmatch '^release/') {
    Write-Error "GOVERNANCE VIOLATION: SourceBranch deve essere 'develop' o 'release/*'. Ricevuto: '$SourceBranch'"
    exit 1
}
if ($TargetBranch -ne 'main') {
    Write-Error "GOVERNANCE VIOLATION: TargetBranch deve essere 'main'. Ricevuto: '$TargetBranch'"
    exit 1
}

# ── Get SHA completi dei branch ───────────────────────────────────────────────
function Get-BranchSHA {
    param([string]$Branch, [switch]$Full)
    $r = Invoke-ADO "$RepoBase/refs?filter=heads/$Branch&api-version=7.1"
    if ($r -and $r.value.Count -gt 0) {
        $sha = $r.value[0].objectId
        if ($Full) { return $sha }
        return $sha.Substring(0, 8)
    }
    return $null
}

$sourceSHAFull  = Get-BranchSHA $SourceBranch -Full
$targetSHAFull  = Get-BranchSHA $TargetBranch -Full
$sourceSHAShort = if ($sourceSHAFull) { $sourceSHAFull.Substring(0, 8) } else { '????????' }
$targetSHAShort = if ($targetSHAFull) { $targetSHAFull.Substring(0, 8) } else { '????????' }

if (-not $sourceSHAFull) {
    Write-Error "Branch '$SourceBranch' non trovato su ADO."
    exit 1
}
if (-not $targetSHAFull) {
    Write-Error "Branch '$TargetBranch' non trovato su ADO."
    exit 1
}

if ($sourceSHAFull -eq $targetSHAFull) {
    Write-Warning "I branch '$SourceBranch' e '$TargetBranch' sono allo stesso commit ($sourceSHAShort). Nessuna PR necessaria."
    if ($Json) { @{ skipped = $true; reason = "same_sha"; sha = $sourceSHAShort } | ConvertTo-Json; exit 0 }
    exit 0
}

# ── Auto-detect SessionLabel dall'ultima Release PR su main ──────────────────
if (-not $SessionLabel) {
    $mainPRs = Invoke-ADO "$RepoBase/pullrequests?searchCriteria.status=completed&searchCriteria.targetRefName=refs/heads/main&`$top=10&api-version=7.1"
    $lastSession = 0
    if ($mainPRs -and $mainPRs.value) {
        foreach ($pr in $mainPRs.value) {
            if ($pr.title -match '\[Release\] Session (\d+)') {
                $n = [int]$Matches[1]
                if ($n -gt $lastSession) { $lastSession = $n }
            }
        }
    }
    $nextSession = $lastSession + 1
    $SessionLabel = "Session $nextSession"
}

# ── Get PR mergeate su develop dal ultimo release su main ─────────────────────
# Trova la data dell'ultimo merge su main
$lastMainMergeDate = $null
$mainPRsAll = Invoke-ADO "$RepoBase/pullrequests?searchCriteria.status=completed&searchCriteria.targetRefName=refs/heads/main&`$top=5&api-version=7.1"
if ($mainPRsAll -and $mainPRsAll.value.Count -gt 0) {
    $lastMainMergeDate = [datetime]$mainPRsAll.value[0].closedDate
}

# PR mergeate su develop (massimo 50, poi filtriamo per data)
$developPRsRaw = Invoke-ADO "$RepoBase/pullrequests?searchCriteria.status=completed&searchCriteria.targetRefName=refs/heads/$SourceBranch&`$top=50&api-version=7.1"
$developPRs = @()
if ($developPRsRaw -and $developPRsRaw.value) {
    $developPRs = $developPRsRaw.value | Where-Object {
        if ($lastMainMergeDate) {
            [datetime]$_.closedDate -gt $lastMainMergeDate
        } else {
            $true
        }
    }
}

# ── Componi descrizione PR ────────────────────────────────────────────────────
$prTable = if ($developPRs.Count -gt 0) {
    $rows = $developPRs | ForEach-Object {
        $src = $_.sourceRefName -replace 'refs/heads/', ''
        "| #$($_.pullRequestId) | $($_.title) | ``$src`` |"
    }
    "| PR | Titolo | Branch |`n|-----|--------|--------|`n" + ($rows -join "`n")
} else {
    "_Nessuna PR trovata nel delta (o branch già allineati)._"
}

$bq = '`'  # backtick letterale (nei here-string @"..."@ il backtick e' escape char)
$description = @"
## Cosa
$prTable

## Delta SHA
- **$SourceBranch** HEAD: ${bq}$sourceSHAShort${bq}
- **$TargetBranch** HEAD: ${bq}$targetSHAShort${bq}

## Checklist deploy server
- [ ] ${bq}git fetch origin main && git reset --hard origin/main${bq}
- [ ] ${bq}docker compose up --build agent-runner${bq}
- [ ] Verificare agent-runner healthy
"@

$prTitle = "[Release] $SessionLabel - ${SourceBranch}->${TargetBranch}"

# ── WhatIf mode ───────────────────────────────────────────────────────────────
if ($WhatIf) {
    if ($Json) {
        @{
            whatIf       = $true
            title        = $prTitle
            source       = $SourceBranch
            target       = $TargetBranch
            sourceSHA    = $sourceSHAShort
            targetSHA    = $targetSHAShort
            deltaCount   = $developPRs.Count
            description  = $description
        } | ConvertTo-Json -Depth 3
    } else {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  [WhatIf] Nessuna PR creata — anteprima:" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "TITOLO:" -ForegroundColor Yellow
        Write-Host "  $prTitle"
        Write-Host ""
        Write-Host "DELTA: $($developPRs.Count) PR da $SourceBranch ($sourceSHAShort) → $TargetBranch ($targetSHAShort)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "DESCRIZIONE:" -ForegroundColor Yellow
        Write-Host $description
        Write-Host ""
    }
    exit 0
}

# ── POST PR su ADO ────────────────────────────────────────────────────────────
$body = @{
    title             = $prTitle
    description       = $description
    sourceRefName     = "refs/heads/$SourceBranch"
    targetRefName     = "refs/heads/$TargetBranch"
    isDraft           = $false
    completionOptions = @{
        squashMerge   = $false
        mergeStrategy = "noFastForward"
    }
} | ConvertTo-Json -Depth 3

try {
    $result = Invoke-RestMethod -Uri "$RepoBase/pullrequests?api-version=7.1" `
        -Headers $headers -Method Post -Body $body
} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Errore creazione PR: $($_.Exception.Message)`n$errBody"
    exit 1
}

$prId  = $result.pullRequestId
$prUrl = "$OrgUrl/$Project/_git/$RepoId/pullrequest/$prId"

# ── Output ────────────────────────────────────────────────────────────────────
if ($Json) {
    @{
        id          = $prId
        url         = $prUrl
        title       = $prTitle
        source      = $SourceBranch
        target      = $TargetBranch
        sourceSHA   = $sourceSHAShort
        targetSHA   = $targetSHAShort
        deltaCount  = $developPRs.Count
    } | ConvertTo-Json
} else {
    Write-Host ""
    Write-Host "✔ PR #$prId creata: $prUrl" -ForegroundColor Green
    Write-Host "  Titolo : $prTitle"
    Write-Host "  Delta  : $($developPRs.Count) PR  |  $SourceBranch ($sourceSHAShort) → $TargetBranch ($targetSHAShort)"
    Write-Host ""
}
