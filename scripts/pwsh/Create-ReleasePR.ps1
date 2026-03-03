<#
  Create-ReleasePR.ps1

  Crea una Release PR da develop verso main su Azure DevOps con:
    - Titolo auto-generato: "[Release] Session N — develop→main"
    - Descrizione auto-generata: tabella PR mergeate su develop + delta SHA + checklist deploy
    - Governance integrata: blocca source≠develop e target≠main
    - Merge strategy: noFastForward (coerente con policy branch protetti)
    - Work item linking strutturale via API (non regex fragile)
    - Conflict pre-check prima della creazione PR

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
    [string] $Pat          = "",
    [switch] $SkipConflictCheck,       # escape hatch per emergenze
    [switch] $WhatIf,                  # stampa titolo+descrizione senza creare la PR
    [switch] $Json                     # output JSON (per agent consumption)
)

$ErrorActionPreference = 'Stop'

# ── Import shared module ─────────────────────────────────────────────────────
Import-Module "$PSScriptRoot/modules/ewctl/ewctl.ado-pr.psm1" -Force

# ── Resolve PAT & Auth ───────────────────────────────────────────────────────
$Pat = Resolve-AdoPat -Pat $Pat -EnvVarNames @('ADO_PR_CREATOR_PAT', 'AZURE_DEVOPS_EXT_PAT')
if (-not $Pat) {
    Write-Error "PAT non trovato. Impostare ADO_PR_CREATOR_PAT (preferito) o AZURE_DEVOPS_EXT_PAT."
    exit 1
}
$headers = New-AdoAuthHeaders -Pat $Pat

# ── Costanti ADO ─────────────────────────────────────────────────────────────
$OrgUrl   = 'https://dev.azure.com/EasyWayData'
$Project  = 'EasyWay-DataPortal'
$RepoId   = 'EasyWayDataPortal'
$RepoBase = "$OrgUrl/$Project/_apis/git/repositories/$RepoId"

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
    $r = Invoke-AdoApi -Url "$RepoBase/refs?filter=heads/$Branch&api-version=7.1" -Headers $headers
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
    $mainPRs = Invoke-AdoApi -Url "$RepoBase/pullrequests?searchCriteria.status=completed&searchCriteria.targetRefName=refs/heads/main&`$top=10&api-version=7.1" -Headers $headers
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
$lastMainMergeDate = $null
$mainPRsAll = Invoke-AdoApi -Url "$RepoBase/pullrequests?searchCriteria.status=completed&searchCriteria.targetRefName=refs/heads/main&`$top=5&api-version=7.1" -Headers $headers
if ($mainPRsAll -and $mainPRsAll.value.Count -gt 0) {
    $lastMainMergeDate = [datetime]$mainPRsAll.value[0].closedDate
}

$developPRsRaw = Invoke-AdoApi -Url "$RepoBase/pullrequests?searchCriteria.status=completed&searchCriteria.targetRefName=refs/heads/$SourceBranch&`$top=50&api-version=7.1" -Headers $headers
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

$bq = '`'
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

# ── Discover work items via API (structural, not regex) ───────────────────────
$workItemIds = @()
if ($developPRs.Count -gt 0) {
    $prIds = $developPRs | ForEach-Object { [int]$_.pullRequestId }
    $workItemIds = Get-PrWorkItemIds -Headers $headers -PrIds $prIds `
        -PrObjects $developPRs -IncludeTitleFallback
}

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
            workItemIds  = $workItemIds
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
        if ($workItemIds.Count -gt 0) {
            Write-Host ""
            Write-Host "WORK ITEMS: $($workItemIds -join ', ')" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "WORK ITEMS: nessuno trovato nelle PR mergeate" -ForegroundColor DarkYellow
        }
        Write-Host ""
        Write-Host "DESCRIZIONE:" -ForegroundColor Yellow
        Write-Host $description
        Write-Host ""
    }
    exit 0
}

# ── Create PR via shared module ───────────────────────────────────────────────
$prResult = New-AdoPullRequest -Headers $headers -Title $prTitle `
    -SourceBranch $SourceBranch -TargetBranch $TargetBranch `
    -Description $description -WorkItemIds $workItemIds `
    -SkipConflictCheck:$SkipConflictCheck

if (-not $prResult.Success) {
    if ($prResult.Conflicts -and $prResult.Conflicts.HasConflicts) {
        $files = $prResult.Conflicts.ConflictedFiles -join ', '
        Write-Error "CONFLITTI RILEVATI: $files"
        Write-Host "Risolvi con: pwsh agents/skills/git/Resolve-PRConflicts.ps1 -SourceBranch $SourceBranch -TargetBranch $TargetBranch" -ForegroundColor Yellow
        Write-Host "Oppure usa -SkipConflictCheck per forzare." -ForegroundColor DarkYellow
    } else {
        Write-Error "Errore creazione PR: $($prResult.Error)"
    }
    exit 1
}

# ── Output ────────────────────────────────────────────────────────────────────
if ($Json) {
    @{
        id          = $prResult.PrId
        url         = $prResult.PrUrl
        title       = $prTitle
        source      = $SourceBranch
        target      = $TargetBranch
        sourceSHA   = $sourceSHAShort
        targetSHA   = $targetSHAShort
        deltaCount  = $developPRs.Count
        workItemIds = $workItemIds
    } | ConvertTo-Json
} else {
    Write-Host ""
    Write-Host "✔ PR #$($prResult.PrId) creata: $($prResult.PrUrl)" -ForegroundColor Green
    Write-Host "  Titolo : $prTitle"
    Write-Host "  Delta  : $($developPRs.Count) PR  |  $SourceBranch ($sourceSHAShort) → $TargetBranch ($targetSHAShort)"
    if ($workItemIds.Count -gt 0) {
        Write-Host "  PBI    : $($workItemIds -join ', ')" -ForegroundColor Cyan
    }
    Write-Host ""
}
