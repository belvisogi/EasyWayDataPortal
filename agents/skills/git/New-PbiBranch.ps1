<#
  New-PbiBranch.ps1 — skill git.new-pbi-branch

  Crea un branch git per un PBI ADO e genera il template PR pre-compilato
  con AB#<id> e gli Acceptance Criteria recuperati dall'ADO API.

  GOVERNANCE GATE (non negoziabile):
    Il branch viene creato SOLO se il PBI e' in stato "Business Approved"
    (o in uno degli stati in -AllowedStates). Questo gate non ha bypass
    silenziosi: se lo stato non e' approvato, lo script esce con errore
    chiaro e non crea nulla.

  ANTIFRAGILITA':
    La verifica dello stato richiede connettivita' ADO. Se ADO non e'
    raggiungibile:
      - Comportamento default: BLOCCO (safe-by-default)
      - Con -ForceOffline: continua, ma logga l'override in modo esplicito
        e rumoroso. L'operatore si assume la responsabilita'.
    NOTA: -ForceOffline bypassa la verifica di connettivita', NON il gate
    di stato. Se riesci a raggiungere ADO, il gate si applica sempre.

  FLUSSO:
    1. Fetch work item da ADO API (stato + titolo + AC)
       → se ADO non raggiungibile e non -ForceOffline: BLOCCO
       → se ADO non raggiungibile e -ForceOffline: warn + placeholder
    2. GATE: verifica stato == "Business Approved"
       → se stato non approvato: BLOCCO (neanche -ForceOffline bypassa)
    3. DryRun: mostra piano senza toccare nulla
    4. git checkout -b feat/PBI-<id>-<slug> da BaseBranch
    5. Scrive .git/PBI_PR_TEMPLATE.md
    6. Stampa PR template su stdout (copy-paste ready)
    7. Opzionale (-CreatePR): push + crea PR ADO con template pre-compilato

  USO:
    # Dry-run: verifica stato e mostra cosa farebbe
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -DryRun

    # Crea branch + template PR (richiede stato Business Approved)
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123

    # Crea branch + push + apre PR su ADO
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -CreatePR

    # EMERGENZA: ADO irraggiungibile, operatore si assume responsabilita'
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -ForceOffline

    # Output JSON per agent consumption
    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 -Json

  REGISTRATO IN: agents/skills/registry.json  →  git.new-pbi-branch
  WIKI: Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md
#>

#Requires -Version 5.1

Param(
    [Parameter(Mandatory = $true)]
    [int]      $PbiId,

    [string]   $Pat           = $env:AZURE_DEVOPS_EXT_PAT,
    [string]   $OrgUrl        = 'https://dev.azure.com/EasyWayData',
    [string]   $Project       = 'EasyWay-DataPortal',
    [string]   $BaseBranch    = 'develop',

    # Stati ADO che autorizzano la creazione del branch.
    # Di default solo "Business Approved". Modificabile via parametro
    # per ambienti con naming diverso (es. "Approved", "Ready for Dev").
    [string[]] $AllowedStates = @('Business Approved'),

    [switch]   $DryRun,
    [switch]   $CreatePR,

    # ESCAPE VALVE: usa solo se ADO e' irraggiungibile e hai certezza
    # che il PBI sia approvato. L'override viene loggato esplicitamente.
    [switch]   $ForceOffline,

    [switch]   $Json
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

function Write-Gate([string]$msg) {
    Write-Host "  🚫 GATE: $msg" -ForegroundColor Red
}

function Exit-Blocked([string]$reason, [hashtable]$extra = @{}) {
    if ($Json) {
        @{ blocked = $true; reason = $reason } + $extra | ConvertTo-Json -Depth 3
    } else {
        Write-Host ""
        Write-Gate $reason
        Write-Host ""
    }
    exit 2
}

function ConvertFrom-HtmlToText([string]$html) {
    if ([string]::IsNullOrWhiteSpace($html)) { return '' }
    $text = $html -replace '<br\s*/?>', "`n"
    $text = $text -replace '<li[^>]*>', "`n- "
    $text = $text -replace '<[^>]+>', ''
    $text = $text -replace '&nbsp;', ' '
    $text = $text -replace '&lt;', '<'
    $text = $text -replace '&gt;', '>'
    $text = $text -replace '&amp;', '&'
    $text = $text -replace '&quot;', '"'
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

function Build-PrTemplate([int]$id, [string]$title, [string]$acText, [string]$state) {
    $acLines = if ($acText) {
        $acText -split "`n" | Where-Object { $_ } | ForEach-Object { "- $_" }
    } else {
        @('- << Acceptance Criteria non compilati sul PBI ADO — aggiungere prima del merge >>')
    }
    $checkboxes = if ($acText) {
        $acText -split "`n" | Where-Object { $_ } | ForEach-Object { "- [ ] $_" }
    } else {
        @('- [ ] << verificare AC con il team >>')
    }

    $offlineNote = if ($state -eq '__OFFLINE__') {
        "`n> ⚠ Branch creato con -ForceOffline: stato PBI non verificato. Confermare Business Approved su ADO prima del merge.`n"
    } else { '' }

    return @"
[PBI-$id] $title

AB#$id
$offlineNote
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

# ── Step 1: Fetch work item da ADO ────────────────────────────────────────────

$pbiTitle   = "PBI-$PbiId"
$pbiAC      = ''
$pbiState   = ''
$fetched    = $false
$adoReached = $false

if (-not $Pat -and -not $ForceOffline) {
    Exit-Blocked "PAT non disponibile (AZURE_DEVOPS_EXT_PAT vuoto). Impossibile verificare stato del PBI. Imposta il PAT o usa -ForceOffline (solo in emergenza)."
}

if ($Pat) {
    Write-Step "Fetch work item $PbiId da ADO..."
    try {
        $b64     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
        $fields  = 'System.Title,System.State,Microsoft.VSTS.Common.AcceptanceCriteria'
        $uri     = "$OrgUrl/$Project/_apis/wit/workitems/$($PbiId)?`$fields=$fields&api-version=7.1"
        $headers = @{ Authorization = "Basic $b64"; Accept = 'application/json' }

        $resp       = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 10
        $adoReached = $true

        $pbiTitle = $resp.fields.'System.Title'
        $pbiState = $resp.fields.'System.State'
        $pbiAC    = ConvertFrom-HtmlToText $resp.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
        $fetched  = $true

        Write-Ok "Work item trovato: `"$pbiTitle`" [stato: $pbiState]"

    } catch {
        $adoReached = $false
        if ($ForceOffline) {
            Write-Warn "Fetch ADO fallita: $($_.Exception.Message)"
            Write-Warn "-ForceOffline attivo — stato NON verificato. Operatore assume responsabilita'."
            $pbiTitle = "PBI-$PbiId"
            $pbiState = '__OFFLINE__'
        } else {
            Exit-Blocked "ADO non raggiungibile ($($_.Exception.Message)). Impossibile verificare stato del PBI $PbiId. Usa -ForceOffline solo in caso di vera emergenza e con certezza che il PBI sia Business Approved." @{ pbiId = $PbiId }
        }
    }
} elseif ($ForceOffline) {
    # PAT mancante + ForceOffline: permesso solo se esplicito
    Write-Warn "PAT mancante + -ForceOffline: stato PBI NON verificato."
    $pbiState = '__OFFLINE__'
}

# ── Step 2: GATE stato Business Approved ──────────────────────────────────────
#
# QUESTO GATE NON HA BYPASS.
# Se ADO e' stato raggiunto e lo stato non e' nella lista allowed → BLOCCO.
# -ForceOffline bypassa solo il requisito di connettivita', non questo gate.

if ($adoReached) {
    $stateOk = $AllowedStates -contains $pbiState

    if (-not $stateOk) {
        if (-not $Json) {
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
            Write-Host "  GATE: PBI $PbiId non e' Business Approved." -ForegroundColor Red
            Write-Host "  Stato attuale : $pbiState" -ForegroundColor Red
            Write-Host "  Stati ammessi : $($AllowedStates -join ', ')" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Lo sviluppo parte solo dopo l'approvazione business." -ForegroundColor Yellow
            Write-Host "  Richiedere l'approvazione su ADO e riprovare." -ForegroundColor Yellow
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
            Write-Host ""
        } else {
            @{
                blocked       = $true
                reason        = "PBI non in stato Business Approved"
                pbiId         = $PbiId
                pbiTitle      = $pbiTitle
                currentState  = $pbiState
                allowedStates = $AllowedStates
            } | ConvertTo-Json -Depth 3
        }
        exit 2
    }

    Write-Ok "Gate superato: stato '$pbiState' e' autorizzato."
} elseif ($pbiState -eq '__OFFLINE__') {
    Write-Warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Warn " OVERRIDE OFFLINE ATTIVO — stato PBI non verificato."
    Write-Warn " Questo override viene registrato."
    Write-Warn " Verificare manualmente che PBI $PbiId sia Business Approved."
    Write-Warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ── Step 3: Branch name ────────────────────────────────────────────────────────

$slug       = New-BranchSlug $pbiTitle
$branchName = "feat/PBI-$PbiId-$slug"
$prTemplate = Build-PrTemplate $PbiId $pbiTitle $pbiAC $pbiState
$prTitle    = "[PBI-$PbiId] $pbiTitle"

# ── Step 4: DryRun — mostra piano senza eseguire ─────────────────────────────

if ($DryRun) {
    if ($Json) {
        @{
            dryRun        = $true
            pbiId         = $PbiId
            pbiTitle      = $pbiTitle
            pbiState      = $pbiState
            stateVerified = $adoReached
            branch        = $branchName
            baseBranch    = $BaseBranch
            prTitle       = $prTitle
            prTemplate    = $prTemplate
            acFetched     = $fetched
        } | ConvertTo-Json -Depth 5
    } else {
        Write-Host ""
        Write-Host "━━━  DRY RUN — nessuna modifica eseguita  ━━━" -ForegroundColor Magenta
        Write-Host "  PBI       : $PbiId — $pbiTitle" -ForegroundColor White
        Write-Host "  Stato     : $pbiState$(if ($adoReached) { ' ✓' } else { ' (non verificato)' })" -ForegroundColor $(if ($adoReached) { 'Green' } else { 'Yellow' })
        Write-Host "  Branch    : $branchName" -ForegroundColor White
        Write-Host "  Da        : $BaseBranch" -ForegroundColor White
        Write-Host "  PR Title  : $prTitle" -ForegroundColor White
        Write-Host "  AC        : $(if ($pbiAC) { 'presenti' } else { 'placeholder' })" -ForegroundColor $(if ($pbiAC) { 'Green' } else { 'Yellow' })
        Write-Host ""
        Write-Host "── PR Template ─────────────────────────────────" -ForegroundColor DarkGray
        Write-Host $prTemplate
        Write-Host "────────────────────────────────────────────────" -ForegroundColor DarkGray
    }
    exit 0
}

# ── Step 5: Crea branch ────────────────────────────────────────────────────────

Write-Step "Checkout branch $branchName da $BaseBranch..."

git fetch origin $BaseBranch --quiet 2>$null

$existing = git branch --list $branchName
if ($existing) {
    Write-Warn "Branch '$branchName' esiste gia' — faccio checkout senza ricreare."
    git checkout $branchName
} else {
    git checkout -b $branchName "origin/$BaseBranch"
}

Write-Ok "Branch creato: $branchName"

# ── Step 6: Scrivi PR template ─────────────────────────────────────────────────

$templatePath = Join-Path $repoRoot '.git' 'PBI_PR_TEMPLATE.md'
$prTemplate | Set-Content -Path $templatePath -Encoding UTF8
Write-Ok "PR template scritto in .git/PBI_PR_TEMPLATE.md"

# ── Step 7: Output template su stdout ─────────────────────────────────────────

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

# ── Step 8 (opzionale): Push + crea PR su ADO ────────────────────────────────

$prUrl = $null

if ($CreatePR) {
    if (-not $Pat) {
        Write-Warn "-CreatePR richiede PAT. Imposta AZURE_DEVOPS_EXT_PAT o passa -Pat."
    } else {
        Write-Step "Push branch su origin..."
        git push origin $branchName

        Write-Step "Creazione PR su ADO..."
        try {
            $b64    = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
            $apiUrl = "$OrgUrl/$Project/_apis/git/repositories/EasyWayDataPortal/pullrequests?api-version=7.1"
            $body   = @{
                title         = $prTitle
                description   = $prTemplate
                sourceRefName = "refs/heads/$branchName"
                targetRefName = "refs/heads/$BaseBranch"
                mergeStrategy = 'noFastForward'
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
    pbiId         = $PbiId
    pbiTitle      = $pbiTitle
    pbiState      = $pbiState
    stateVerified = $adoReached
    branch        = $branchName
    baseBranch    = $BaseBranch
    prTitle       = $prTitle
    prTemplate    = $prTemplate
    acFetched     = $fetched
    prUrl         = $prUrl
    templateFile  = $templatePath
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
}
