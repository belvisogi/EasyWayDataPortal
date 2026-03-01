<#
  Invoke-SDLCOrchestrator.ps1  —  skill planning.sdlc-orchestrator

  Orchestratore interattivo SDLC EasyWay.
  Guida l'utente attraverso le 4 fasi del flusso SDLC agentico:
    Fase 1 — Product Brief   (BA  → LLM Fan-Out → product-brief.md)
    Fase 2 — PRD             (PM  → LLM → prd.md)
    Fase 3 — PBI ADO         (Convert-PrdToPbi.ps1 -WhatIf → -Apply)
    Fase 4 — Sprint Plan     (Scrum Master → LLM → sprint-plan.md)

  LLM STRATEGY:
    Primary  : DeepSeek (DEEPSEEK_API_KEY)
    Fallback : OpenRouter (OPENROUTER_API_KEY) — antifragile
    Entrambi usano il formato OpenAI-compat (messages, temperature, max_tokens)

  GOVERNANCE (staging skills integrati):
    - Epic Discovery: query ADO via WIQL per epiche attive (azure-devops skill)
    - BA Fan-Out: LLM analizza 4 dimensioni interne prima di sintetizzare (multi-agent-orchestration skill)
    - Scrum Master Phase 4: sprint plan con sizing Fibonacci dopo PBI creation (scrum-master skill)
    - Saga log: se PBI Apply parziale, mostra cosa creato e cosa no per cleanup (workflow-orchestration skill)

  RESUME:
    Se product-brief.md già esiste → chiede se usare quello esistente.
    Se prd.md già esiste → idem. Se sprint-plan.md esiste → idem.

  3 DOMANDE PRE-PRD (obbligatorie):
    1. Epic ADO attiva? → query WIQL epiche attive, mostra lista, utente sceglie
    2. Dominio? (Infra / AMS / Frontend / Logic / Reporting / Data / Governance)
    3. Pattern Feature/PBI? (Standard feature / Task tecnico / Improvement)

  USO:
    # Interattivo completo
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1

    # Con parametri pre-compilati
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" `
      -Description "Orchestratore conversazionale per il flusso BA->PM->PBI" `
      -EpicId 123 -Domain "Governance"

    # Skip fasi già completate
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" -SkipBrief -SkipSprint

    # Agent use (no interattività, output JSON)
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "..." -Description "..." -EpicId 0 -Domain "Governance" `
      -NoConfirm -Json

  REGISTRATO IN: agents/skills/registry.json → planning.sdlc-orchestrator
  WIKI: Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md
#>

#Requires -Version 5.1

Param(
    [string] $FeatureName,
    [string] $Description,
    [int]    $EpicId        = -1,
    [string] $Domain        = '',
    [string] $PbiPattern    = '',

    [switch] $SkipBrief,
    [switch] $SkipPrd,
    [switch] $SkipSprint,
    [switch] $NoBranch,
    [switch] $NoConfirm,
    [switch] $Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ─── constants ──────────────────────────────────────────────────────────────

$WIKI_BASE    = 'Wiki/EasyWayData.wiki/planning'
$SKILL_DIR    = 'agents/skills/planning'
$DOMAINS      = @('Infra', 'AMS', 'Frontend', 'Logic', 'Reporting', 'Data', 'Governance')
$PBI_PATTERNS = @('Feature standard', 'Task tecnico', 'Improvement/Bug')

$DEEPSEEK_URL    = 'https://api.deepseek.com/v1/chat/completions'
$OPENROUTER_URL  = 'https://openrouter.ai/api/v1/chat/completions'
$DEEPSEEK_MODEL  = 'deepseek-chat'
$OPENROUTER_MODEL = 'deepseek/deepseek-chat'

$ADO_ORG     = 'https://dev.azure.com/EasyWayData'
$ADO_PROJECT = 'EasyWay-DataPortal'

# ─── helpers ────────────────────────────────────────────────────────────────

function Write-Phase([string]$label) {
    if ($Json) { return }
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $label" -ForegroundColor Cyan
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-Step([string]$msg) {
    if (-not $Json) { Write-Host "  → $msg" -ForegroundColor White }
}

function Write-Ok([string]$msg) {
    if (-not $Json) { Write-Host "  ✓ $msg" -ForegroundColor Green }
}

function Write-Warn([string]$msg) {
    if (-not $Json) { Write-Warning $msg }
}

function Ask([string]$prompt, [string]$default = '') {
    if ($NoConfirm -and $default) { return $default }
    $hint = if ($default) { " [$default]" } else { '' }
    $answer = Read-Host "  $prompt$hint"
    if (-not $answer -and $default) { return $default }
    return $answer
}

function AskChoice([string]$prompt, [string[]]$choices) {
    if ($NoConfirm) { return $choices[0] }
    Write-Host ""
    for ($i = 0; $i -lt $choices.Count; $i++) {
        Write-Host "    [$($i+1)] $($choices[$i])" -ForegroundColor Gray
    }
    do {
        $raw = Read-Host "  $prompt (1-$($choices.Count))"
        $idx = [int]$raw - 1
    } while ($idx -lt 0 -or $idx -ge $choices.Count)
    return $choices[$idx]
}

function Read-EnvFile([string]$key) {
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        $line = Get-Content $envFile | Where-Object { $_ -match "^$key=" } | Select-Object -First 1
        if ($line) { return ($line -split '=', 2)[1].Trim().Trim('"') }
    }
    return $null
}

function Get-SlugFromName([string]$name) {
    $slug = $name.ToLower() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    return $slug
}

function Get-B64Auth([string]$pat) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes(":$pat")
    return [Convert]::ToBase64String($bytes)
}

# ─── ADO Epic Discovery (azure-devops skill) ────────────────────────────────

function Get-ADOActiveEpics([string]$domain) {
    # Query ADO via WIQL per epiche attive
    # Fonte: azure-devops/SKILL.md — WIQL query pattern

    $pat = $env:AZURE_DEVOPS_EXT_PAT
    if (-not $pat) { $pat = Read-EnvFile 'AZURE_DEVOPS_EXT_PAT' }
    if (-not $pat) { return @() }

    $b64  = Get-B64Auth $pat
    $hdrs = @{
        Authorization  = "Basic $b64"
        'Content-Type' = 'application/json'
        Accept         = 'application/json'
    }

    $wiql = "SELECT [System.Id], [System.Title], [System.State], [System.AreaPath] FROM WorkItems WHERE [System.WorkItemType] = 'Epic' AND [System.State] NOT IN ('Done', 'Removed', 'Closed') ORDER BY [System.ChangedDate] DESC"

    $wiqlBody = @{ query = $wiql } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod `
            -Uri     "$ADO_ORG/$ADO_PROJECT/_apis/wit/wiql?`$top=20&api-version=7.1" `
            -Method  Post `
            -Headers $hdrs `
            -Body    ([System.Text.Encoding]::UTF8.GetBytes($wiqlBody)) `
            -TimeoutSec 15

        if (-not $resp.workItems -or $resp.workItems.Count -eq 0) { return @() }

        # fetch titles in batch
        $ids = ($resp.workItems | Select-Object -First 15 | ForEach-Object { $_.id }) -join ','
        $items = Invoke-RestMethod `
            -Uri     "$ADO_ORG/_apis/wit/workitems?ids=$ids&fields=System.Id,System.Title,System.State&api-version=7.1" `
            -Method  Get `
            -Headers $hdrs `
            -TimeoutSec 15

        return $items.value | ForEach-Object {
            @{ id = $_.fields.'System.Id'; title = $_.fields.'System.Title'; state = $_.fields.'System.State' }
        }
    } catch {
        return @()
    }
}

function Ask-EpicId {
    # Se EpicId già passato come parametro, usa quello
    if ($EpicId -ge 0) { return $EpicId }

    if ($NoConfirm) { return 0 }

    Write-Step "Querying ADO per epiche attive..."
    $epics = @(Get-ADOActiveEpics $Domain)

    if ($epics.Count -gt 0) {
        Write-Host ""
        Write-Host "  Epiche ADO attive:" -ForegroundColor Yellow
        Write-Host "    [0] Nessuna epica / Nuova epica" -ForegroundColor Gray
        for ($i = 0; $i -lt $epics.Count; $i++) {
            $e = $epics[$i]
            Write-Host "    [$($i+1)] AB#$($e.id) — $($e.title)  [$($e.state)]" -ForegroundColor Gray
        }
        Write-Host ""
        $raw = Read-Host "  Seleziona epica (0 = nessuna)"
        $idx = [int]$raw
        if ($idx -eq 0 -or $idx -gt $epics.Count) { return 0 }
        return [int]$epics[$idx - 1].id
    } else {
        $epicRaw = Ask "Epic ADO attiva per questo dominio? (ID numerico o 0 per nessuna)" "0"
        return [int]($epicRaw -replace '[^0-9]', '')
    }
}

# ─── LLM ────────────────────────────────────────────────────────────────────

function Invoke-LLMWithFallback([string]$systemPrompt, [string]$userPrompt) {
    $dsKey = $env:DEEPSEEK_API_KEY
    if (-not $dsKey) { $dsKey = Read-EnvFile 'DEEPSEEK_API_KEY' }

    $orKey = $env:OPENROUTER_API_KEY
    if (-not $orKey) { $orKey = Read-EnvFile 'OPENROUTER_API_KEY' }

    $body = @{
        messages    = @(
            @{ role = 'system'; content = $systemPrompt }
            @{ role = 'user';   content = $userPrompt }
        )
        temperature = 0.3
        max_tokens  = 3000
    }

    # --- try DeepSeek ---
    if ($dsKey) {
        try {
            Write-Step "Chiamata DeepSeek..."
            $reqBody = ($body + @{ model = $DEEPSEEK_MODEL }) | ConvertTo-Json -Depth 10
            $resp = Invoke-RestMethod `
                -Uri     $DEEPSEEK_URL `
                -Method  Post `
                -Headers @{ Authorization = "Bearer $dsKey"; 'Content-Type' = 'application/json' } `
                -Body    ([System.Text.Encoding]::UTF8.GetBytes($reqBody)) `
                -TimeoutSec 90
            return $resp.choices[0].message.content.Trim()
        } catch {
            Write-Warn "DeepSeek non disponibile: $_"
            if (-not $orKey) { throw "DeepSeek fallito e OPENROUTER_API_KEY non trovata." }
        }
    } else {
        Write-Warn "DEEPSEEK_API_KEY non trovata — provo OpenRouter direttamente."
    }

    # --- fallback OpenRouter ---
    if ($orKey) {
        Write-Step "Fallback → OpenRouter (deepseek/deepseek-chat)..."
        $reqBody = ($body + @{ model = $OPENROUTER_MODEL }) | ConvertTo-Json -Depth 10
        $resp = Invoke-RestMethod `
            -Uri     $OPENROUTER_URL `
            -Method  Post `
            -Headers @{
                Authorization  = "Bearer $orKey"
                'Content-Type' = 'application/json'
                'HTTP-Referer' = 'https://easyway-dataportal.com'
                'X-Title'      = 'EasyWay SDLC Orchestrator'
            } `
            -Body    ([System.Text.Encoding]::UTF8.GetBytes($reqBody)) `
            -TimeoutSec 90
        return $resp.choices[0].message.content.Trim()
    }

    throw "Nessuna API key disponibile (DEEPSEEK_API_KEY o OPENROUTER_API_KEY). Impossibile generare documento."
}

# ─── BA system prompt (con Fan-Out interno) ──────────────────────────────────
# Fonte: multi-agent-orchestration/SKILL.md — Pattern Fan-Out adattato per single-LLM call
# Invece di spawning 4 agenti paralleli, chiediamo al LLM di ragionare lungo 4 dimensioni
# prima di sintetizzare, ottenendo qualità simile con un solo call.

function Get-BAPrompt([string]$epicId, [string]$domain, [string]$pattern) {
    return @"
Sei un Business Analyst esperto che lavora su EasyWay Data Portal (piattaforma enterprise di gestione dati).
Il tuo compito è creare un product brief completo e azionabile in italiano.

CONTESTO EASYWAY:
- Piattaforma enterprise con backend Node.js/TypeScript, frontend React, DB SQL Server
- Utenti: operatori dati, manager, amministratori di sistema
- Epic ADO: AB#$epicId   Dominio: $domain   Pattern PBI: $pattern
- Wiki-first: evita duplicazioni con funzionalità già esistenti

METODO DI ANALISI (Fan-Out — multi-agent-orchestration pattern):
Prima di scrivere il brief, analizza internamente queste 4 dimensioni:
  A) MERCATO/CONTESTO: Qual è la situazione attuale? Che gap risolve?
  B) UTENTI: Chi è impattato? Quali ruoli EasyWay? Quali pain points concreti?
  C) FATTIBILITÀ TECNICA: Complessità stack EasyWay? Dipendenze? Rischi tecnici?
  D) VALORE BUSINESS: Perché ora? Quale KPI migliora? ROI atteso?
Poi sintetizza in un brief coerente che integra tutte e 4 le prospettive.

STRUTTURA PRODUCT BRIEF RICHIESTA:
## 1. Executive Summary
Problema principale, soluzione proposta, utenti target, timeline stimata (2-3 righe)

## 2. Problema
- Descrizione dettagliata del problema (dimensione A+B)
- Chi lo sperimenta (ruoli specifici in EasyWay)
- Impatto se non risolto
- Perché risolvere ora (dimensione D)

## 3. Utenti Target
- Persona primaria (ruolo, obiettivi, pain points — dimensione B)
- Persona secondaria (se applicabile)

## 4. Soluzione Proposta
- Descrizione della soluzione (dimensione C: fattibilità prima)
- 3-5 capacità chiave con valore per l'utente
- MVP: cosa è critico vs cosa si può rimandare

## 5. Metriche di Successo
- 2-3 KPI misurabili con baseline e target (dimensione D)

## 6. Rischi e Dipendenze
- Top 3 rischi con probabilità, impatto, mitigazione (dimensione C+A)
- Dipendenze tecniche note

## 7. Handoff Notes
- **Epic ADO**: AB#$epicId
- **Dominio**: $domain
- **Pattern PBI**: $pattern
- **Pronto per PM**: checklist completezza

REGOLE:
- Scrivi in italiano
- Sii specifico e azionabile (no generici)
- Ogni sezione max 150 parole
- Priorità: chiarezza e utilizzo pratico del brief come input per il PRD
"@
}

# ─── PM system prompt ────────────────────────────────────────────────────────

function Get-PMPrompt([string]$epicId, [string]$domain, [string]$featureName) {
    return @"
Sei un Product Manager esperto che lavora su EasyWay Data Portal.
Il tuo compito è creare un PRD (Product Requirements Document) completo in italiano
basandoti sul product brief fornito dall'utente.

CONTESTO EASYWAY:
- Stack: Node.js/TypeScript backend, React frontend, SQL Server, ADO per work items
- Epic ADO: AB#$epicId   Dominio: $domain   Feature: $featureName

STRUTTURA PRD RICHIESTA:

## Executive Summary
Problema, soluzione, business value, metriche principali (3-4 righe)

## Requisiti Funzionali

### FR-001: [Titolo] [MUST/SHOULD/COULD]
**Descrizione**: ...
**Acceptance Criteria**:
- Criterio 1 (misurabile, Given/When/Then)
- Criterio 2
**Priorità**: MUST/SHOULD/COULD

_(ripeti per ogni FR, max 8 requisiti)_

## Requisiti Non-Funzionali

### NFR-001: [Titolo] [MUST]
**Descrizione**: ...
**AC**: metrica specifica (es. "risposta < 200ms al p95")

_(2-4 NFR: performance, security, reliability, usability)_

## User Stories (formato ADO)

Come [ruolo EasyWay], voglio [capacità] così da [beneficio].
_(3-6 user story in italiano)_

## ADO Mapping

| Campo | Valore |
|-------|--------|
| **Epic ID** | AB#$epicId |
| **Domain** | $domain |
| **Area Path** | EasyWay\$domain |
| **PBI suggeriti** | [elenco titoli, 1 per riga] |

## Out of Scope
- Item 1 — motivo
- Item 2 — motivo

## Dipendenze e Rischi
- Dipendenza tecnica principale
- Rischio top 1 con mitigazione

REGOLE:
- Scrivi in italiano
- Ogni FR DEVE avere Acceptance Criteria misurabili
- La sezione ADO Mapping è OBBLIGATORIA (Convert-PrdToPbi.ps1 la usa)
- PBI suggeriti: titoli concisi, implementabili in 1 sprint
- Max 1200 parole totali
"@
}

# ─── Scrum Master system prompt (scrum-master skill) ────────────────────────
# Fonte: C:\old\.agents\skills\scrum-master\SKILL.md
# Adattato per EasyWay: usa ADO PBI IDs, sprint da 2 settimane, sizing Fibonacci

function Get-ScrumMasterPrompt([string]$featureName, [string]$domain) {
    return @"
Sei uno Scrum Master esperto che lavora su EasyWay Data Portal.
Il tuo compito è creare un piano sprint in italiano basandoti sul PRD e sulla lista PBI forniti.

CONTESTO EASYWAY:
- Sprint: 2 settimane, capacità standard 40 story points
- Fibonacci sizing: 1=XS(1-2h), 2=S(2-4h), 3=M(4-8h), 5=L(1-2gg), 8=XL(2-3gg), 13=Epic(da spezzare)
- Regola: se una story è >8 punti, DEVE essere spezzata in sub-story
- Feature: $featureName   Dominio: $domain

LIVELLI DI COMPLESSITÀ (per decidere n. sprint):
- Level 0 (1 PBI):   nessun sprint formale, direct implementation
- Level 1 (2-10 PBI): 1 sprint
- Level 2 (11-20 PBI): 2 sprint
- Level 3 (21-40 PBI): 3-4 sprint

STRUTTURA SPRINT PLAN RICHIESTA:

## Overview
- Feature: $featureName
- Livello complessità: Level X
- Sprint totali stimati: N
- Capacità per sprint: 40 SP

## Story Sizing

| PBI ID | Titolo | SP | Priorità | Sprint |
|--------|--------|----|----------|--------|
| AB#XXX | ...    | 3  | MUST     | S1     |
_(una riga per PBI)_

## Sprint 1 — [Goal]
**Obiettivo**: [frase chiara del goal sprint]
**Capacità**: XX/40 SP
**PBI inclusi**: AB#XXX, AB#YYY
**Definition of Done**:
- [ ] Tutti i requisiti MUST implementati
- [ ] Test passing
- [ ] Code review completato
- [ ] Deploy su DEV verificato

_(ripeti per ogni sprint)_

## Rischi Sprint
- Rischio 1 con contingency plan
- Rischio 2

## Definition of Done Globale
- [ ] Tutti i FR-MUST hanno test di accettazione passanti
- [ ] NFR verificati in ambiente CERT
- [ ] Documentazione wiki aggiornata
- [ ] PR approvata e mergiata su develop

REGOLE:
- Scrivi in italiano
- Ogni sprint deve avere un goal chiaro e misurabile
- Non mettere più di 40 SP per sprint
- Ordina i PBI per dipendenza (before ordering by priority)
- Story >8 SP: segnala come "DA SPEZZARE" nel piano
- Output: documento markdown pronto per wiki
"@
}

# ─── interactive loop per approvazione doc ───────────────────────────────────

function Invoke-DocApproval([string]$docPath, [string]$docLabel, [string]$systemPrompt, [string]$userPrompt) {
    if ($Json) { return }

    while ($true) {
        # mostra anteprima
        Write-Host ""
        Write-Host "  ── Anteprima $docLabel ──────────────────────────────" -ForegroundColor Yellow
        $lines = Get-Content $docPath
        $preview = $lines | Select-Object -First 35
        $preview | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        if ($lines.Count -gt 35) {
            Write-Host "  ... ($(($lines.Count - 35)) righe non mostrate — vedi $docPath)" -ForegroundColor DarkGray
        }
        Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "  [A]pprova  [R]igenera  [E]dit manuale  [Q]uit"

        switch ($choice.ToUpper().Trim()) {
            'A' { Write-Ok "$docLabel approvato."; return }
            'R' {
                $note = Read-Host "  Note per rigenerazione (opz.)"
                $extraPrompt = if ($note) { "$userPrompt`n`nNOTE DI MIGLIORAMENTO: $note" } else { $userPrompt }
                Write-Step "Rigenerando $docLabel..."
                $newContent = Invoke-LLMWithFallback $systemPrompt $extraPrompt
                Set-Content -Path $docPath -Value $newContent -Encoding UTF8
                Write-Ok "Rigenerato → $docPath"
            }
            'E' {
                Write-Host "  Apri $docPath in un editor e salva. Poi premi INVIO per continuare." -ForegroundColor Magenta
                Read-Host "  [INVIO quando pronto]" | Out-Null
            }
            'Q' {
                Write-Host "  Orchestratore interrotto. File salvato: $docPath" -ForegroundColor Yellow
                exit 0
            }
        }
    }
}

# ─── MAIN ────────────────────────────────────────────────────────────────────

if (-not $Json) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   EasyWay SDLC Orchestrator — BA → PM → PBI → SM   ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

# ─── FASE 0: Gather context ──────────────────────────────────────────────────

Write-Phase "[0/4] CONTESTO — 3 domande pre-PRD"

if (-not $FeatureName) {
    $FeatureName = Ask "Nome feature (slug, es. 'agent-interactive-sdlc')"
    if (-not $FeatureName) { throw "FeatureName obbligatorio." }
}

if (-not $Description) {
    $Description = Ask "Descrizione breve della feature"
    if (-not $Description) { throw "Description obbligatoria." }
}

# Domanda 2: Dominio (prima dell'epic — serve per il filtro WIQL)
if (-not $Domain -or $DOMAINS -notcontains $Domain) {
    $Domain = AskChoice "Dominio" $DOMAINS
}

# Domanda 1: Epic — usa ADO discovery
$EpicId = Ask-EpicId

# Domanda 3: Pattern PBI
if (-not $PbiPattern -or $PBI_PATTERNS -notcontains $PbiPattern) {
    $PbiPattern = AskChoice "Pattern PBI" $PBI_PATTERNS
}

$slug    = Get-SlugFromName $FeatureName
$wikiDir = "$WIKI_BASE/$slug"
$briefPath  = "$wikiDir/product-brief.md"
$prdPath    = "$wikiDir/prd.md"
$sprintPath = "$wikiDir/sprint-plan.md"

Write-Step "Feature slug: $slug"
Write-Step "Wiki path: $wikiDir"
if ($EpicId -gt 0) { Write-Step "Epic: AB#$EpicId" }
Write-Step "Domain: $Domain  |  Pattern: $PbiPattern"

# crea directory wiki se non esiste
if (-not (Test-Path $wikiDir)) {
    New-Item -ItemType Directory -Path $wikiDir -Force | Out-Null
    Write-Step "Creata directory: $wikiDir"
}

# ─── FASE 1: Product Brief ───────────────────────────────────────────────────

Write-Phase "[1/4] PRODUCT BRIEF — Business Analyst (Fan-Out)"

$skipThisBrief = $SkipBrief.IsPresent

if (-not $skipThisBrief -and (Test-Path $briefPath)) {
    if ($NoConfirm) {
        Write-Step "product-brief.md trovato — uso esistente (NoConfirm)."
        $skipThisBrief = $true
    } else {
        $ans = Ask "product-brief.md già esiste. [U]sa esistente / [R]igenera" "U"
        $skipThisBrief = ($ans.ToUpper().Trim() -ne 'R')
    }
}

$baSystem = Get-BAPrompt $EpicId $Domain $PbiPattern
$baUser   = "Crea il product brief per questa feature EasyWay:`n`nNome: $FeatureName`nDescrizione: $Description`nEpic ADO: AB#$EpicId`nDominio: $Domain`nPattern PBI: $PbiPattern"

if (-not $skipThisBrief) {
    Write-Step "Generando product-brief.md via LLM (Fan-Out a 4 dimensioni)..."
    $briefContent = Invoke-LLMWithFallback $baSystem $baUser
    Set-Content -Path $briefPath -Value $briefContent -Encoding UTF8
    Write-Ok "product-brief.md generato → $briefPath"
} else {
    Write-Step "Usando product-brief.md esistente: $briefPath"
}

if (-not $Json) {
    Invoke-DocApproval $briefPath "Product Brief" $baSystem $baUser
}

# ─── FASE 2: PRD ─────────────────────────────────────────────────────────────

Write-Phase "[2/4] PRD — Product Manager"

$skipThisPrd = $SkipPrd.IsPresent

if (-not $skipThisPrd -and (Test-Path $prdPath)) {
    if ($NoConfirm) {
        Write-Step "prd.md trovato — uso esistente (NoConfirm)."
        $skipThisPrd = $true
    } else {
        $ans = Ask "prd.md già esiste. [U]sa esistente / [R]igenera" "U"
        $skipThisPrd = ($ans.ToUpper().Trim() -ne 'R')
    }
}

$briefContent = Get-Content $briefPath -Raw -Encoding UTF8
$pmSystem = Get-PMPrompt $EpicId $Domain $FeatureName
$pmUser   = "Crea il PRD per questa feature EasyWay basandoti sul product brief qui sotto.`n`nPRODUCT BRIEF:`n$briefContent"

if (-not $skipThisPrd) {
    Write-Step "Generando prd.md via LLM (usando product-brief come contesto)..."
    $prdContent = Invoke-LLMWithFallback $pmSystem $pmUser
    Set-Content -Path $prdPath -Value $prdContent -Encoding UTF8
    Write-Ok "prd.md generato → $prdPath"
} else {
    Write-Step "Usando prd.md esistente: $prdPath"
}

if (-not $Json) {
    Invoke-DocApproval $prdPath "PRD" $pmSystem $pmUser
}

# ─── FASE 3: PBI Creation ─────────────────────────────────────────────────────

Write-Phase "[3/4] PBI ADO — Convert-PrdToPbi"

$convertScript = "$SKILL_DIR/Convert-PrdToPbi.ps1"
$createdPbiIds = @()

if (-not (Test-Path $convertScript)) {
    Write-Warn "Convert-PrdToPbi.ps1 non trovato in $convertScript. Salta fase PBI."
} else {
    Write-Step "WhatIf — PBI che verrebbero creati..."
    $whatIfArgs = @('-PrdPath', $prdPath, '-WhatIf')
    if ($EpicId -gt 0) { $whatIfArgs += @('-EpicId', $EpicId) }
    & pwsh $convertScript @whatIfArgs

    $doPbi = $true
    if (-not $NoConfirm -and -not $Json) {
        $ans = Ask "Creare i PBI su ADO? [A]pplica / [S]kip" "A"
        $doPbi = ($ans.ToUpper().Trim() -eq 'A')
    }

    if ($doPbi) {
        Write-Step "Applicando — creazione PBI su ADO..."
        $convertArgs = @('-PrdPath', $prdPath, '-Apply', '-NoConfirm')
        if ($EpicId -gt 0) { $convertArgs += @('-EpicId', $EpicId) }
        if ($Json) { $convertArgs += '-Json' }

        $convertOut = & pwsh $convertScript @convertArgs
        if ($Json) {
            try {
                $parsed = $convertOut | ConvertFrom-Json
                $createdPbiIds = $parsed.pbiIds
            } catch { }
        } else {
            # estrai PBI IDs dall'output testuale per fase 4
            $convertOut | ForEach-Object {
                if ($_ -match 'PBI #(\d+) creato') { $createdPbiIds += [int]$Matches[1] }
            }
        }

        # Saga compensation log (workflow-orchestration-patterns skill)
        if ($Json -and $createdPbiIds.Count -gt 0) {
            Write-Step "Saga log: $($createdPbiIds.Count) PBI creati: $($createdPbiIds -join ', ')"
        }
    }
}

# ─── FASE 4: Sprint Plan — Scrum Master ───────────────────────────────────────
# Fonte: C:\old\.agents\skills\scrum-master\SKILL.md
# Genera sprint plan con story sizing Fibonacci e grouping per sprint

Write-Phase "[4/4] SPRINT PLAN — Scrum Master"

$skipThisSprint = $SkipSprint.IsPresent

if (-not $skipThisSprint -and (Test-Path $sprintPath)) {
    if ($NoConfirm) {
        Write-Step "sprint-plan.md trovato — uso esistente (NoConfirm)."
        $skipThisSprint = $true
    } else {
        $ans = Ask "sprint-plan.md già esiste. [U]sa esistente / [R]igenera" "U"
        $skipThisSprint = ($ans.ToUpper().Trim() -ne 'R')
    }
}

if (-not $skipThisSprint) {
    $doSprint = $true
    if (-not $NoConfirm -and -not $Json) {
        $ans = Ask "Generare Sprint Plan? [A]pplica / [S]kip" "A"
        $doSprint = ($ans.ToUpper().Trim() -eq 'A')
    }

    if ($doSprint) {
        Write-Step "Generando sprint-plan.md via LLM (Scrum Master - Fibonacci sizing)..."

        # costruisci contesto: PRD + lista PBI creati
        $prdForSprint = Get-Content $prdPath -Raw -Encoding UTF8
        $pbiListStr   = if ($createdPbiIds.Count -gt 0) {
            "PBI creati su ADO: " + ($createdPbiIds | ForEach-Object { "AB#$_" } | Join-String ', ')
        } else {
            "PBI IDs: non ancora creati su ADO (usa i PBI suggeriti nel PRD)"
        }

        $smSystem = Get-ScrumMasterPrompt $FeatureName $Domain
        $smUser   = "Crea il piano sprint per questa feature basandoti su PRD e lista PBI.`n`n$pbiListStr`n`nPRD:`n$prdForSprint"

        $sprintContent = Invoke-LLMWithFallback $smSystem $smUser
        Set-Content -Path $sprintPath -Value $sprintContent -Encoding UTF8
        Write-Ok "sprint-plan.md generato → $sprintPath"

        if (-not $Json) {
            Invoke-DocApproval $sprintPath "Sprint Plan" $smSystem $smUser
        }
    }
}

# Suggerimento branch
if (-not $NoBranch -and -not $Json) {
    Write-Host ""
    Write-Host "  ── Prossimo passo: crea branch per ogni PBI ──────────" -ForegroundColor Cyan
    if ($createdPbiIds.Count -gt 0) {
        foreach ($id in $createdPbiIds) {
            Write-Host "  pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId $id -DryRun" -ForegroundColor DarkCyan
        }
    } else {
        Write-Host "  pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId <ID> -DryRun" -ForegroundColor DarkCyan
    }
}

# ─── OUTPUT FINALE ────────────────────────────────────────────────────────────

$result = @{
    featureName = $FeatureName
    slug        = $slug
    epicId      = $EpicId
    domain      = $Domain
    briefPath   = $briefPath
    prdPath     = $prdPath
    sprintPath  = $sprintPath
    pbiIds      = $createdPbiIds
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  SDLC Orchestrator — COMPLETATO" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Product Brief : $briefPath" -ForegroundColor White
    Write-Host "  PRD           : $prdPath" -ForegroundColor White
    Write-Host "  Sprint Plan   : $sprintPath" -ForegroundColor White
    if ($createdPbiIds.Count -gt 0) {
        Write-Host "  PBI creati    : $($createdPbiIds -join ', ')" -ForegroundColor White
    }
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
}
