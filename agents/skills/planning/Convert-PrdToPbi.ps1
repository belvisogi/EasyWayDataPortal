<#
  Convert-PrdToPbi.ps1  —  skill planning.prd-to-pbi

  FASE 2 del flusso SDLC agentico EasyWay:
    Product Brief (BA) → PRD (PM) → PBI su ADO (questo script) → git.new-pbi-branch

  Legge un PRD.md, usa DeepSeek per decomporre i requisiti in PBI strutturati,
  e li crea su Azure DevOps via REST API.

  GOVERNANCE:
    - WhatIf obbligatorio prima di Apply: mostra il piano senza toccare ADO
    - MaxPbi = 20 di default (protezione blast radius)
    - Ogni PBI creato viene loggato con ID e titolo
    - Apply richiede conferma interattiva (a meno di -NoConfirm per agent use)

  ANTIFRAGILITA':
    - DeepSeek non raggiungibile: esce con errore chiaro (non crea nulla)
    - ADO non raggiungibile: esce con errore chiaro
    - EpicId non trovato nel PRD e non passato: avvisa e continua senza link epic

  FLUSSO:
    1. Leggi PRD.md
    2. Estrai sezione "ADO Mapping" (EpicId + Domain + PBI suggeriti)
    3. Chiama DeepSeek per strutturare FR/NFR in PBI ADO
    4. WhatIf: stampa piano tabulare
    5. Apply: crea PBI via POST _apis/wit/workitems/$Product%20Backlog%20Item
    6. Output: lista PBI ID per feed in git.new-pbi-branch

  USO:
    # Dry-run: vedi cosa creerebbe
    pwsh agents/skills/planning/Convert-PrdToPbi.ps1 -PrdPath "Wiki/.../prd.md" -WhatIf

    # Crea PBI su ADO (con conferma interattiva)
    pwsh agents/skills/planning/Convert-PrdToPbi.ps1 -PrdPath "Wiki/.../prd.md" -Apply

    # Agent use (no conferma interattiva, output JSON)
    pwsh agents/skills/planning/Convert-PrdToPbi.ps1 -PrdPath "Wiki/.../prd.md" -Apply -NoConfirm -Json

    # Override Epic ID
    pwsh agents/skills/planning/Convert-PrdToPbi.ps1 -PrdPath "..." -Apply -EpicId 42

  REGISTRATO IN: agents/skills/registry.json → planning.prd-to-pbi
  WIKI: Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md
#>

#Requires -Version 5.1

Param(
    [Parameter(Mandatory = $true)]
    [string] $PrdPath,

    [string] $Pat             = $env:AZURE_DEVOPS_EXT_PAT,
    [string] $OrgUrl          = 'https://dev.azure.com/EasyWayData',
    [string] $Project         = 'EasyWay-DataPortal',
    [string] $DeepSeekApiKey  = $env:DEEPSEEK_API_KEY,
    [string] $DeepSeekModel   = 'deepseek-chat',

    [int]    $EpicId          = 0,
    [int]    $MaxPbi          = 20,

    [switch] $WhatIf,
    [switch] $Apply,
    [switch] $NoConfirm,
    [switch] $Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ─── helpers ───────────────────────────────────────────────────────────────

function Write-Step([string]$msg) {
    if (-not $Json) { Write-Host "  → $msg" -ForegroundColor Cyan }
}

function Write-Warn([string]$msg) {
    if (-not $Json) { Write-Warning $msg }
}

function Get-Pat {
    if ($Pat) { return $Pat }
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        $line = Get-Content $envFile | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | Select-Object -First 1
        if ($line) { return ($line -split '=', 2)[1].Trim().Trim('"') }
    }
    throw "PAT non trovato. Imposta AZURE_DEVOPS_EXT_PAT o usa -Pat."
}

function Get-DeepSeekKey {
    if ($DeepSeekApiKey) { return $DeepSeekApiKey }
    # tenta import da .env.secrets (ambiente server) o .env.local
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        $line = Get-Content $envFile | Where-Object { $_ -match '^DEEPSEEK_API_KEY=' } | Select-Object -First 1
        if ($line) { return ($line -split '=', 2)[1].Trim().Trim('"') }
    }
    throw "DEEPSEEK_API_KEY non trovato. Imposta env:DEEPSEEK_API_KEY o aggiungi a .env.local."
}

function Get-B64Auth([string]$pat) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes(":$pat")
    return [Convert]::ToBase64String($bytes)
}

# ─── step 1: leggi PRD ─────────────────────────────────────────────────────

if (-not (Test-Path $PrdPath)) {
    throw "PRD non trovato: $PrdPath"
}
$prdContent = Get-Content $PrdPath -Raw -Encoding UTF8
Write-Step "PRD letto: $PrdPath ($($prdContent.Length) chars)"

# ─── step 2: estrai ADO Mapping dal PRD ────────────────────────────────────

$detectedEpicId = $EpicId
if ($detectedEpicId -eq 0) {
    # cerca pattern "AB#<id>" nella sezione ADO Mapping
    if ($prdContent -match '(?i)AB#(\d+)') {
        $detectedEpicId = [int]$Matches[1]
        Write-Step "Epic ID rilevato dal PRD: AB#$detectedEpicId"
    } else {
        Write-Warn "Epic ID non trovato nel PRD. I PBI verranno creati senza link epic. Usa -EpicId per specificarlo."
    }
}

# ─── step 3: chiama DeepSeek per strutturare i PBI ────────────────────────

Write-Step "Chiamata DeepSeek ($DeepSeekModel) per decomposizione PRD in PBI..."

$dsKey = Get-DeepSeekKey

$systemPrompt = @"
Sei un Product Manager esperto che lavora con Azure DevOps.
Il tuo compito è analizzare un PRD e produrre una lista di Product Backlog Items (PBI) strutturati.

Per ogni PBI produci un JSON con questi campi esatti:
{
  "title": "Titolo conciso (max 80 caratteri, in italiano)",
  "description": "Come [ruolo], voglio [azione] così da [beneficio]. (in italiano)",
  "acceptanceCriteria": ["Criterio 1 misurabile", "Criterio 2 misurabile"],
  "priority": 1,
  "effort": 3
}

Dove:
- priority: 1=High (Must Have), 2=Medium (Should Have), 3=Low (Could Have)
- effort: stima in story points (1=XS, 2=S, 3=M, 5=L, 8=XL)

Regole:
- Massimo $MaxPbi PBI totali
- Focalizzati sui Must Have e Should Have
- Ogni PBI deve essere implementabile in un singolo sprint
- Non ripetere requirements già coperti da altri PBI
- Output: JSON array puro, nessun testo prima o dopo

Esempio output:
[
  {
    "title": "Login utente con email e password",
    "description": "Come utente registrato, voglio accedere con email e password così da fruire dei contenuti personalizzati.",
    "acceptanceCriteria": ["Validazione email RFC 5322", "Password minimo 8 caratteri", "Messaggio errore chiaro se credenziali errate"],
    "priority": 1,
    "effort": 3
  }
]
"@

$userPrompt = "Analizza questo PRD ed estrai i PBI:`n`n$prdContent"

$dsBody = @{
    model    = $DeepSeekModel
    messages = @(
        @{ role = 'system'; content = $systemPrompt }
        @{ role = 'user';   content = $userPrompt }
    )
    temperature       = 0.1
    max_tokens        = 4096
    response_format   = @{ type = 'json_object' }
} | ConvertTo-Json -Depth 10

try {
    $dsResp = Invoke-RestMethod `
        -Uri     'https://api.deepseek.com/v1/chat/completions' `
        -Method  Post `
        -Headers @{ Authorization = "Bearer $dsKey"; 'Content-Type' = 'application/json' } `
        -Body    ([System.Text.Encoding]::UTF8.GetBytes($dsBody)) `
        -TimeoutSec 60
} catch {
    throw "DeepSeek API error: $_`nVerifica DEEPSEEK_API_KEY e connettivita'."
}

$rawJson = $dsResp.choices[0].message.content.Trim()

# DeepSeek con json_object a volte wrappa in { "pbis": [...] } — unwrap se necessario
try {
    $parsed = $rawJson | ConvertFrom-Json
    if ($parsed -is [System.Collections.IEnumerable] -and $parsed -isnot [string]) {
        $pbis = $parsed
    } elseif ($null -ne $parsed.pbis) {
        $pbis = $parsed.pbis
    } elseif ($null -ne $parsed.items) {
        $pbis = $parsed.items
    } else {
        # prova il primo array nella risposta
        $pbis = $parsed | Get-Member -MemberType NoteProperty | ForEach-Object {
            $val = $parsed.($_.Name)
            if ($val -is [System.Collections.IEnumerable] -and $val -isnot [string]) { return $val }
        } | Select-Object -First 1
        if (-not $pbis) { throw "Struttura JSON inattesa dalla risposta DeepSeek." }
    }
} catch {
    throw "Parsing risposta DeepSeek fallito: $_`nRaw: $rawJson"
}

# applica limite MaxPbi
if ($pbis.Count -gt $MaxPbi) {
    Write-Warn "DeepSeek ha restituito $($pbis.Count) PBI — troncato a $MaxPbi (usa -MaxPbi per aumentare)"
    $pbis = $pbis | Select-Object -First $MaxPbi
}

Write-Step "DeepSeek: $($pbis.Count) PBI estratti dal PRD"

# ─── step 4: WhatIf — stampa piano ────────────────────────────────────────

$priorityLabel = @{ 1 = 'High'; 2 = 'Medium'; 3 = 'Low' }
$effortLabel   = @{ 1 = 'XS'; 2 = 'S'; 3 = 'M'; 5 = 'L'; 8 = 'XL' }

if ($WhatIf -or (-not $Apply)) {
    if (-not $Json) {
        Write-Host ""
        Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  WHATIF — PBI che verrebbero creati su ADO" -ForegroundColor Yellow
        if ($detectedEpicId -gt 0) {
            Write-Host "  Epic: AB#$detectedEpicId" -ForegroundColor Yellow
        }
        Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Yellow
        $i = 1
        foreach ($pbi in $pbis) {
            $prio  = $priorityLabel[[int]$pbi.priority]
            $eff   = $effortLabel[[int]$pbi.effort]
            Write-Host ""
            Write-Host "  [$i/$($pbis.Count)] $($pbi.title)" -ForegroundColor White
            Write-Host "       Priorità: $prio | Effort: $eff SP" -ForegroundColor Gray
            Write-Host "       $($pbi.description)" -ForegroundColor Gray
            if ($pbi.acceptanceCriteria) {
                Write-Host "       AC:" -ForegroundColor Gray
                foreach ($ac in $pbi.acceptanceCriteria) {
                    Write-Host "         ✓ $ac" -ForegroundColor DarkGray
                }
            }
            $i++
        }
        Write-Host ""
        Write-Host "  Usa -Apply per creare questi $($pbis.Count) PBI su ADO." -ForegroundColor Yellow
        Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
    }

    if (-not $Apply) {
        if ($Json) {
            @{ whatIf = $true; count = $pbis.Count; epicId = $detectedEpicId; plan = $pbis } | ConvertTo-Json -Depth 10
        }
        exit 0
    }
}

# ─── step 5: conferma interattiva ─────────────────────────────────────────

if (-not $NoConfirm -and -not $Json) {
    Write-Host "  Stai per creare $($pbis.Count) PBI su ADO (Epic: AB#$detectedEpicId)." -ForegroundColor Magenta
    $answer = Read-Host "  Confermi? [y/N]"
    if ($answer -notmatch '^[yY]') {
        Write-Host "  Operazione annullata." -ForegroundColor Yellow
        exit 0
    }
}

# ─── step 6: crea PBI su ADO ──────────────────────────────────────────────

$pat   = Get-Pat
$b64   = Get-B64Auth $pat
$hdrs  = @{
    Authorization  = "Basic $b64"
    'Content-Type' = 'application/json-patch+json'
    Accept         = 'application/json'
}

$createdIds = [System.Collections.Generic.List[object]]::new()
$errors     = [System.Collections.Generic.List[object]]::new()
$i = 1

foreach ($pbi in $pbis) {
    Write-Step "Creando PBI $i/$($pbis.Count): $($pbi.title)"

    # Componi descrizione HTML (ADO usa HTML per il campo System.Description)
    $acHtml = ''
    if ($pbi.acceptanceCriteria) {
        $acItems = ($pbi.acceptanceCriteria | ForEach-Object { "<li>$_</li>" }) -join ''
        $acHtml  = "<br><b>Acceptance Criteria:</b><ul>$acItems</ul>"
    }
    $descHtml = "<p>$($pbi.description)</p>$acHtml"

    # ADO priority: 1=High=1, 2=Medium=2, 3=Low=3
    $adoPriority = [int]$pbi.priority

    $patch = [System.Collections.Generic.List[object]]::new()
    $patch.Add(@{ op = 'add'; path = '/fields/System.Title';       value = $pbi.title })
    $patch.Add(@{ op = 'add'; path = '/fields/System.Description'; value = $descHtml })
    $patch.Add(@{ op = 'add'; path = '/fields/Microsoft.VSTS.Common.Priority'; value = $adoPriority })
    if ($pbi.effort -gt 0) {
        $patch.Add(@{ op = 'add'; path = '/fields/Microsoft.VSTS.Scheduling.StoryPoints'; value = [int]$pbi.effort })
    }

    # Link all'epica se disponibile
    if ($detectedEpicId -gt 0) {
        $patch.Add(@{
            op    = 'add'
            path  = '/relations/-'
            value = @{
                rel        = 'System.LinkTypes.Hierarchy-Reverse'
                url        = "$OrgUrl/$Project/_apis/wit/workitems/$detectedEpicId"
                attributes = @{ comment = "Linked from Convert-PrdToPbi.ps1" }
            }
        })
    }

    $patchBody = $patch | ConvertTo-Json -Depth 10 -AsArray

    $apiUrl = "$OrgUrl/$Project/_apis/wit/workitems/`$Product%20Backlog%20Item?api-version=7.1"

    try {
        $resp = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $hdrs `
                    -Body ([System.Text.Encoding]::UTF8.GetBytes($patchBody)) `
                    -TimeoutSec 30

        $created = @{
            id    = $resp.id
            title = $pbi.title
            url   = $resp._links.html.href
        }
        $createdIds.Add($created)

        if (-not $Json) {
            Write-Host "    ✓ PBI #$($resp.id) creato: $($pbi.title)" -ForegroundColor Green
        }
    } catch {
        $errMsg = "ERRORE su '$($pbi.title)': $_"
        $errors.Add(@{ title = $pbi.title; error = $errMsg })
        Write-Warn $errMsg
    }

    $i++
}

# ─── step 7: output ────────────────────────────────────────────────────────

$result = @{
    pbiIds    = $createdIds | ForEach-Object { $_.id }
    epicId    = $detectedEpicId
    count     = $createdIds.Count
    created   = $createdIds
    errors    = $errors
}

if ($Json) {
    $result | ConvertTo-Json -Depth 10
} else {
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  RISULTATO: $($createdIds.Count)/$($pbis.Count) PBI creati su ADO" -ForegroundColor Green
    if ($detectedEpicId -gt 0) {
        Write-Host "  Epic link: AB#$detectedEpicId" -ForegroundColor Green
    }
    if ($errors.Count -gt 0) {
        Write-Host "  ERRORI: $($errors.Count) PBI non creati — vedi output sopra" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  PBI ID creati: $($result.pbiIds -join ', ')" -ForegroundColor White
    Write-Host ""
    Write-Host "  Prossimo passo — crea i branch per ogni PBI:" -ForegroundColor Cyan
    foreach ($id in $result.pbiIds) {
        Write-Host "    pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId $id -DryRun" -ForegroundColor DarkCyan
    }
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
}
