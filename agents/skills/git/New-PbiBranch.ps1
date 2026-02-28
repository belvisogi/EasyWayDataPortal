<#
  New-PbiBranch.ps1 — skill git.new-pbi-branch

  Crea un branch git per un PBI ADO e genera il template PR pre-compilato
  con AB#<id> e gli Acceptance Criteria recuperati dall'ADO API.

  PRINCIPIO ANTIFRAGILE:
    Il developer NON viene mai bloccato. Se ADO API non e' raggiungibile
    (rete, PAT scaduto, work item non trovato), lo script crea il branch
    comunque e genera il template con placeholder. Il sistema degrada
    gracefully: branch sempre creato, AC completi quando possibile.

  FLUSSO:
    1. Fetch work item da ADO API  →  se fallisce: warn + placeholder
    2. Genera branch name:  feat/PBI-<id>-<slug>
    3. DryRun: mostra piano senza toccare nulla
    4. git checkout -b feat/PBI-<id>-<slug>  da BaseBranch
    5. Scrive .git/PBI_PR_TEMPLATE.md (riusabile per il corpo della PR)
    6. Stampa PR template su stdout (copy-paste ready)
    7. Opzionale (-CreatePR): push + crea PR ADO con template pre-compilato

  USO:
    # Dry-run: mostra cosa farebbe
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -DryRun

    # Crea branch + template PR
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123

    # Crea branch + push + apre PR su ADO
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -CreatePR

    # Senza fetch ADO (offline / PAT non disponibile)
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -SkipFetch

    # Output JSON per agent consumption
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -Json

  REGISTRATO IN: agents/skills/registry.json  →  git.new-pbi-branch
  WIKI: Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md
#>

#Requires -Version 5.1

Param(
    [Parameter(Mandatory = $true)]
    [int]    $PbiId,

    [string] $Pat          = $env:AZURE_DEVOPS_EXT_PAT,
    [string] $OrgUrl       = 'https://dev.azure.com/EasyWayData',
    [string] $Project      = 'EasyWay-DataPortal',
    [string] $BaseBranch   = 'develop',

    [switch] $DryRun,
    [switch] $SkipFetch,
    [switch] $CreatePR,
    [switch] $Json
)

$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step([string]$msg) {
    if (-not $Json) { Write-Host "  → $msg" -ForegroundColor Cyan }
}

function Write-Warn([string]$msg) {
    if (-not $Json) { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }
}

function Write-Ok([string]$msg) {
    if (-not $Json) { Write-Host "  ✓  $msg" -ForegroundColor Green }
}

function ConvertFrom-HtmlToText([string]$html) {
    if ([string]::IsNullOrWhiteSpace($html)) { return '' }
    # Strip HTML tags e decode entita' comuni
    $text = $html -replace '<br\s*/?>', "`n"
    $text = $text -replace '<li[^>]*>', "`n- "
    $text = $text -replace '<[^>]+>', ''
    $text = $text -replace '&nbsp;', ' '
    $text = $text -replace '&lt;', '<'
    $text = $text -replace '&gt;', '>'
    $text = $text -replace '&amp;', '&'
    $text = $text -replace '&quot;', '"'
    # Normalizza spazi/newline
    $text = $text -replace '\r\n', "`n"
    $text = ($text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join "`n"
    return $text.Trim()
}

function New-BranchSlug([string]$title, [int]$maxLen = 35) {
    $slug = $title.ToLower()
    $slug = $slug -replace '[^a-z0-9\s-]', ''
    $slug = $slug -replace '\s+', '-'
    $slug = $slug -replace '-+', '-'
    $slug = $slug.Trim('-')
    if ($slug.Length -gt $maxLen) {
        $slug = $slug.Substring(0, $maxLen).TrimEnd('-')
    }
    return $slug
}

function Build-PrTemplate([int]$id, [string]$title, [string]$acText) {
    $acLines = if ($acText) {
        $acText -split "`n" | Where-Object { $_ } | ForEach-Object { "- $_" }
    } else {
        @('- << Acceptance Criteria non disponibili — compilare manualmente >>')
    }
    $checkboxes = if ($acText) {
        $acText -split "`n" | Where-Object { $_ } | ForEach-Object { "- [ ] $_" }
    } else {
        @('- [ ] << verificare AC con il team >>')
    }

    return @"
[PBI-$id] $title

AB#$id

## Acceptance Criteria

$($acLines -join "`n")

## Test Plan

$($checkboxes -join "`n")

## Note

_Aggiungere note implementative qui._
"@
}

# ── Repo root ──────────────────────────────────────────────────────────────────

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Error "Non sei in un repository git."
    exit 1
}

# ── Step 1: Fetch work item da ADO (con fallback) ─────────────────────────────

$pbiTitle = "PBI-$PbiId"
$pbiAC    = ''
$fetched  = $false

if ($SkipFetch) {
    Write-Warn "SkipFetch attivo — usando placeholder per titolo e AC."
} elseif (-not $Pat) {
    Write-Warn "PAT non disponibile (AZURE_DEVOPS_EXT_PAT vuoto) — usando placeholder."
} else {
    Write-Step "Fetch work item $PbiId da ADO..."
    try {
        $b64     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
        $fields  = 'System.Title,Microsoft.VSTS.Common.AcceptanceCriteria'
        $uri     = "$OrgUrl/$Project/_apis/wit/workitems/$($PbiId)?`$fields=$fields&api-version=7.1"
        $headers = @{ Authorization = "Basic $b64"; Accept = 'application/json' }

        $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 10

        $rawTitle = $resp.fields.'System.Title'
        $rawAC    = $resp.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'

        if ($rawTitle) {
            $pbiTitle = $rawTitle
            $pbiAC    = ConvertFrom-HtmlToText $rawAC
            $fetched  = $true
            Write-Ok "Work item trovato: `"$pbiTitle`""
        } else {
            Write-Warn "Work item $PbiId non ha titolo — verificare l'ID."
        }
    } catch {
        Write-Warn "Fetch ADO fallita ($($_.Exception.Message)) — continuo con placeholder."
        Write-Warn "Branch e template verranno creati comunque (antifragile)."
    }
}

# ── Step 2: Branch name ────────────────────────────────────────────────────────

$slug       = New-BranchSlug $pbiTitle
$branchName = "feat/PBI-$PbiId-$slug"
$prTemplate = Build-PrTemplate $PbiId $pbiTitle $pbiAC
$prTitle    = "[PBI-$PbiId] $pbiTitle"

# ── Step 3: DryRun — mostra piano senza eseguire ─────────────────────────────

if ($DryRun) {
    if ($Json) {
        @{
            dryRun     = $true
            pbiId      = $PbiId
            pbiTitle   = $pbiTitle
            branch     = $branchName
            baseBranch = $BaseBranch
            prTitle    = $prTitle
            prTemplate = $prTemplate
            acFetched  = $fetched
        } | ConvertTo-Json -Depth 5
    } else {
        Write-Host ""
        Write-Host "━━━  DRY RUN — nessuna modifica eseguita  ━━━" -ForegroundColor Magenta
        Write-Host "  Branch    : $branchName" -ForegroundColor White
        Write-Host "  Da        : $BaseBranch" -ForegroundColor White
        Write-Host "  PR Title  : $prTitle" -ForegroundColor White
        Write-Host "  AC fetch  : $(if ($fetched) { 'OK' } else { 'PLACEHOLDER' })" -ForegroundColor $(if ($fetched) { 'Green' } else { 'Yellow' })
        Write-Host ""
        Write-Host "── PR Template ─────────────────────────────────" -ForegroundColor DarkGray
        Write-Host $prTemplate
        Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
    }
    exit 0
}

# ── Step 4: Crea branch ────────────────────────────────────────────────────────

Write-Step "Checkout branch $branchName da $BaseBranch..."

# Assicura che BaseBranch sia aggiornato
git fetch origin $BaseBranch --quiet 2>$null

$existing = git branch --list $branchName
if ($existing) {
    Write-Warn "Branch '$branchName' esiste gia' — faccio checkout senza ricreare."
    git checkout $branchName
} else {
    git checkout -b $branchName "origin/$BaseBranch"
}

Write-Ok "Branch creato: $branchName"

# ── Step 5: Scrivi PR template in .git/ ───────────────────────────────────────

$templatePath = Join-Path $repoRoot '.git' 'PBI_PR_TEMPLATE.md'
$prTemplate | Set-Content -Path $templatePath -Encoding UTF8
Write-Ok "PR template scritto in .git/PBI_PR_TEMPLATE.md"

# ── Step 6: Output template su stdout ─────────────────────────────────────────

if (-not $Json) {
    Write-Host ""
    Write-Host "── PR Template (copy-paste) ─────────────────────" -ForegroundColor DarkGray
    Write-Host $prTemplate
    Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Prossimi passi:" -ForegroundColor White
    Write-Host "    1. Sviluppa su: $branchName" -ForegroundColor Cyan
    Write-Host "    2. ewctl commit  (Iron Dome)" -ForegroundColor Cyan
    Write-Host "    3. git push origin $branchName" -ForegroundColor Cyan
    Write-Host "    4. Apri PR con title '$prTitle'" -ForegroundColor Cyan
    Write-Host "       e incolla il template sopra come descrizione." -ForegroundColor Cyan
    if (-not $CreatePR) {
        Write-Host "    (oppure: riesegui con -CreatePR per push+PR automatici)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ── Step 7 (opzionale): Push + crea PR su ADO ────────────────────────────────

$prUrl = $null

if ($CreatePR) {
    if (-not $Pat) {
        Write-Warn "-CreatePR richiede PAT. Imposta AZURE_DEVOPS_EXT_PAT o passa -Pat."
    } else {
        Write-Step "Push branch su origin..."
        git push origin $branchName

        Write-Step "Creazione PR su ADO..."
        try {
            $b64      = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
            $apiUrl   = "$OrgUrl/$Project/_apis/git/repositories/EasyWayDataPortal/pullrequests?api-version=7.1"
            $body     = @{
                title           = $prTitle
                description     = $prTemplate
                sourceRefName   = "refs/heads/$branchName"
                targetRefName   = "refs/heads/$BaseBranch"
                mergeStrategy   = 'noFastForward'
            } | ConvertTo-Json -Depth 3

            $resp  = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body `
                        -Headers @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json' }
            $prUrl = "$OrgUrl/$Project/_git/EasyWayDataPortal/pullrequest/$($resp.pullRequestId)"
            Write-Ok "PR #$($resp.pullRequestId) creata: $prUrl"
        } catch {
            Write-Warn "Creazione PR fallita: $($_.Exception.Message)"
            Write-Warn "Push eseguito — apri la PR manualmente su ADO."
        }
    }
}

# ── Output finale ─────────────────────────────────────────────────────────────

$result = @{
    pbiId      = $PbiId
    pbiTitle   = $pbiTitle
    branch     = $branchName
    baseBranch = $BaseBranch
    prTitle    = $prTitle
    prTemplate = $prTemplate
    acFetched  = $fetched
    prUrl      = $prUrl
    templateFile = $templatePath
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
}
