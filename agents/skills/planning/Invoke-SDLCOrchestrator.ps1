<#
  Invoke-SDLCOrchestrator.ps1  —  skill planning.sdlc-orchestrator  v3

  Orchestratore interattivo SDLC EasyWay.
  Guida l'utente attraverso le 4 fasi del flusso SDLC agentico:
    Fase 0   — Contesto (3 domande + auto-suggest LLM + RAG)
    Fase 1   — Product Brief   (BA  → LLM Fan-Out → product-brief.md)
    Fase 2   — PRD             (PM  → LLM → prd.md con Evidence/Confidence)
    Fase 3   — PBI ADO         (Convert-PrdToPbi.ps1 -WhatIf → -Apply)
    Fase 4   — Sprint Plan     (Scrum Master → LLM → sprint-plan.md)

  NOVITÀ v3 (rispetto a v2):
    1. RAG pre-Brief: query Qdrant prima della Fase 1 (QDRANT_URL in .env.local)
    2. Evidence/Confidence nel PRD: sezione obbligatoria con fonti wiki
    3. initiative_id end-to-end: YAML front-matter in tutti i documenti + PBI ADO
    4. Auto-suggest Dominio e Pattern via LLM (veloce, confermabile dall'utente)
    5. Epic skip silenzioso quando ADO è offline

  LLM STRATEGY:
    Primary  : DeepSeek (DEEPSEEK_API_KEY)
    Fallback : OpenRouter (OPENROUTER_API_KEY) — antifragile
    Entrambi usano il formato OpenAI-compat (messages, temperature, max_tokens)

  RAG STRATEGY:
    Qdrant direct call (QDRANT_URL + QDRANT_API_KEY in .env.local)
    SSH tunnel consigliato: ssh -L 6333:localhost:6333 ubuntu@80.225.86.168 -i <key> -f -N
    Poi: QDRANT_URL=http://localhost:6333
    Se QDRANT_URL non è configurato → RAG skip silenzioso (degradation to v2 behavior)

  TRACEABILITY:
    initiative_id auto-generato: INIT-YYYYMMDD-<slug>
    Propagato in: product-brief.md, prd.md, sprint-plan.md (YAML front-matter)
    Propagato in: PBI ADO (campo descrizione HTML via Convert-PrdToPbi -InitiativeId)
    Incluso in output JSON: initiativeId

  USO:
    # Interattivo completo
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1

    # Con parametri pre-compilati
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" `
      -Description "Orchestratore conversazionale per il flusso BA->PM->PBI" `
      -EpicId 123 -Domain "Governance"

    # Con initiative_id esplicito (es. per riprendere una sessione)
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" -InitiativeId "INIT-20260301-agent-interactive-sdlc"

    # Skip fasi già completate
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" -SkipBrief -SkipSprint

    # Agent use (no interattività, output JSON)
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "..." -Description "..." -EpicId 0 -Domain "Governance" `
      -NoConfirm -Json

  REGISTRATO IN: agents/skills/registry.json → planning.sdlc-orchestrator
  WIKI: Wiki/EasyWayData.wiki/planning/sdlc-orchestrator-v3/prd.md
#>

#Requires -Version 5.1

Param(
    [string] $FeatureName,
    [string] $Description,
    [int]    $EpicId        = -1,
    [string] $Domain        = '',
    [string] $PbiPattern    = '',
    [string] $InitiativeId  = '',   # v3: auto-generato se vuoto
    [string] $RagUrl        = '',   # v3: override QDRANT_URL env var

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

$QDRANT_COLLECTION = 'easyway_wiki'

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

# ─── v3: YAML front-matter helper ───────────────────────────────────────────

function New-FrontMatter([hashtable]$meta) {
    $lines = @('---')
    foreach ($k in $meta.Keys) {
        $lines += "$k`: $($meta[$k])"
    }
    $lines += '---'
    return $lines -join "`n"
}

function Add-InitiativeHeader([string]$content, [hashtable]$meta) {
    $fm = New-FrontMatter $meta
    return "$fm`n`n$content"
}

# ─── v3: RAG via Qdrant direct ──────────────────────────────────────────────
# Chiama Qdrant scroll API con text match.
# Richiede QDRANT_URL (es. http://localhost:6333 via SSH tunnel).
# Se non configurato o irraggiungibile → restituisce '' (silent skip).

function Invoke-RAGSearch([string[]]$queries, [int]$k = 5) {
    $qdrantUrl = $RagUrl
    if (-not $qdrantUrl) { $qdrantUrl = $env:QDRANT_URL }
    if (-not $qdrantUrl) { $qdrantUrl = Read-EnvFile 'QDRANT_URL' }
    if (-not $qdrantUrl) { return '' }  # non configurato — skip silenzioso

    $qdrantKey = $env:QDRANT_API_KEY
    if (-not $qdrantKey) { $qdrantKey = Read-EnvFile 'QDRANT_API_KEY' }

    $scrollUrl = "$qdrantUrl/collections/$QDRANT_COLLECTION/points/scroll"
    $hdrs = @{ 'Content-Type' = 'application/json' }
    if ($qdrantKey) { $hdrs['api-key'] = $qdrantKey }

    $allChunks = [System.Collections.Generic.List[string]]::new()
    $seenContent = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($q in $queries) {
        if (-not $q.Trim()) { continue }
        $bodyObj = @{
            filter       = @{ must = @(@{ key = 'content'; match = @{ text = $q } }) }
            limit        = $k
            with_payload = $true
            with_vector  = $false
        }
        $bodyJson = $bodyObj | ConvertTo-Json -Depth 10

        try {
            $resp = Invoke-RestMethod `
                -Uri        $scrollUrl `
                -Method     Post `
                -Headers    $hdrs `
                -Body       ([System.Text.Encoding]::UTF8.GetBytes($bodyJson)) `
                -TimeoutSec 10

            $points = $resp.result.points
            if ($points) {
                foreach ($pt in $points) {
                    $content = $pt.payload.content
                    if (-not $content) { continue }
                    $key = $content.Substring(0, [Math]::Min(80, $content.Length))
                    if (-not $seenContent.Add($key)) { continue }  # dedup
                    $source  = if ($pt.payload.path) { $pt.payload.path } elseif ($pt.payload.filename) { $pt.payload.filename } else { 'wiki' }
                    $excerpt = $content.Substring(0, [Math]::Min(400, $content.Length))
                    $allChunks.Add("[$source]`n$excerpt")
                }
            }
        } catch {
            # Qdrant irraggiungibile o timeout — skip silenzioso
            return ''
        }
    }

    if ($allChunks.Count -eq 0) { return '' }

    $header = "CONOSCENZA WIKI EasyWay — $($allChunks.Count) chunk rilevanti da Qdrant:"
    $body   = ($allChunks | ForEach-Object { "---`n$_" }) -join "`n"
    return "$header`n$body"
}

# ─── v3: Auto-suggest Domain e Pattern via LLM ──────────────────────────────
# Chiamata veloce (max_tokens=150) per suggerire domain e pattern.
# Restituisce @{domain=''; pattern=''} o $null se LLM non disponibile.

function Invoke-LLMAutoSuggest([string]$name, [string]$desc) {
    $dsKey = $env:DEEPSEEK_API_KEY
    if (-not $dsKey) { $dsKey = Read-EnvFile 'DEEPSEEK_API_KEY' }
    $orKey = $env:OPENROUTER_API_KEY
    if (-not $orKey) { $orKey = Read-EnvFile 'OPENROUTER_API_KEY' }

    if (-not $dsKey -and -not $orKey) { return $null }

    $sysPrompt = @"
Sei un Business Analyst EasyWay. Classifica questa feature in base al dominio e pattern.
Domini disponibili: Infra, AMS, Frontend, Logic, Reporting, Data, Governance
Pattern disponibili: Feature standard, Task tecnico, Improvement/Bug

Rispondi SOLO in JSON (nessun testo extra):
{"domain": "<dominio>", "pattern": "<pattern>"}
"@
    $userPrompt = "Feature: $name`nDescrizione: $desc"

    $body = @{
        messages    = @(
            @{ role = 'system'; content = $sysPrompt }
            @{ role = 'user';   content = $userPrompt }
        )
        temperature = 0.1
        max_tokens  = 80
    }

    try {
        if ($dsKey) {
            $reqBody = ($body + @{ model = $DEEPSEEK_MODEL }) | ConvertTo-Json -Depth 10
            $resp = Invoke-RestMethod `
                -Uri     $DEEPSEEK_URL `
                -Method  Post `
                -Headers @{ Authorization = "Bearer $dsKey"; 'Content-Type' = 'application/json' } `
                -Body    ([System.Text.Encoding]::UTF8.GetBytes($reqBody)) `
                -TimeoutSec 20
        } else {
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
                -TimeoutSec 20
        }

        $raw = $resp.choices[0].message.content.Trim()
        # estrai JSON anche se wrappato in ```json```
        if ($raw -match '```json\s*([\s\S]+?)```') { $raw = $Matches[1].Trim() }
        elseif ($raw -match '\{[^}]+\}') { $raw = $Matches[0] }

        $parsed = $raw | ConvertFrom-Json
        $sugDomain  = if ($DOMAINS   -contains $parsed.domain)  { $parsed.domain }  else { '' }
        $sugPattern = if ($PBI_PATTERNS -contains $parsed.pattern) { $parsed.pattern } else { '' }

        if ($sugDomain -and $sugPattern) {
            return @{ domain = $sugDomain; pattern = $sugPattern }
        }
    } catch {
        # auto-suggest fallito — silent skip
    }
    return $null
}

# ─── ADO Epic Discovery (azure-devops skill) ────────────────────────────────

function Get-ADOActiveEpics([string]$domain) {
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

        $ids   = ($resp.workItems | Select-Object -First 15 | ForEach-Object { $_.id }) -join ','
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
    if ($EpicId -ge 0) { return $EpicId }
    if ($NoConfirm) { return 0 }

    # v3: skip silenzioso se ADO offline (nessun Write-Warning)
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
        # v3: messaggio neutro invece di warning
        if (-not $Json) {
            Write-Host "  ADO offline o nessuna epica attiva — inserisci Epic ID manualmente (0 = nessuna)" -ForegroundColor DarkGray
        }
        $epicRaw = Ask "Epic ADO ID (numerico o 0 per nessuna)" "0"
        return [int]($epicRaw -replace '[^0-9]', '')
    }
}

# ─── LLM ────────────────────────────────────────────────────────────────────

function Invoke-LLMWithFallback([string]$systemPrompt, [string]$userPrompt, [int]$maxTokens = 3000) {
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
        max_tokens  = $maxTokens
    }

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

# ─── BA system prompt (con Fan-Out interno + RAG context) ────────────────────
# v3: $ragContext iniettato nel system prompt se disponibile

function Get-BAPrompt([string]$epicId, [string]$domain, [string]$pattern, [string]$ragContext = '') {
    $ragSection = if ($ragContext) {
        "`n`n$ragContext`n`nUSA queste informazioni wiki come base per l'analisi. Cita le fonti rilevanti nel brief."
    } else { '' }

    return @"
Sei un Business Analyst esperto che lavora su EasyWay Data Portal (piattaforma enterprise di gestione dati).
Il tuo compito è creare un product brief completo e azionabile in italiano.

CONTESTO EASYWAY:
- Piattaforma enterprise con backend Node.js/TypeScript, frontend React, DB SQL Server
- Utenti: operatori dati, manager, amministratori di sistema
- Epic ADO: AB#$epicId   Dominio: $domain   Pattern PBI: $pattern
- Wiki-first: evita duplicazioni con funzionalità già esistenti$ragSection

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

# ─── PM system prompt (con Evidence/Confidence e RAG sources) ────────────────
# v3: sezione Evidence/Confidence obbligatoria nel PRD
#     fonti RAG passate come context per compilare la tabella

function Get-PMPrompt([string]$epicId, [string]$domain, [string]$featureName, [string]$ragContext = '') {
    $ragSection = if ($ragContext) {
        "`n`nFONTI WIKI DISPONIBILI (usa come Evidence):`n$ragContext"
    } else {
        "`n`nNOTA: Nessun contesto RAG disponibile. Usa Confidence=Low per le decisioni senza evidenza diretta."
    }

    return @"
Sei un Product Manager esperto che lavora su EasyWay Data Portal.
Il tuo compito è creare un PRD (Product Requirements Document) completo in italiano
basandoti sul product brief fornito dall'utente.

CONTESTO EASYWAY:
- Stack: Node.js/TypeScript backend, React frontend, SQL Server, ADO per work items
- Epic ADO: AB#$epicId   Dominio: $domain   Feature: $featureName$ragSection

STRUTTURA PRD RICHIESTA:

## Executive Summary
Problema, soluzione, business value, metriche principali (3-4 righe)

## Evidence & Confidence

| Area | Evidence | Confidence | Note |
|------|----------|------------|------|
| [Area tecnica 1] | [fonte wiki o N/A] | High/Medium/Low | [⚠️ Richiede validazione se Low] |
| [Area tecnica 2] | [fonte wiki o N/A] | High/Medium/Low | |
| [Area tecnica 3] | [fonte wiki o N/A] | High/Medium/Low | |

_(almeno 3 righe coprono: data model, security, integration/API)_
_(se Confidence = Low → aggiungi "⚠️ Richiede validazione umana" nella colonna Note)_

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
- La sezione **Evidence & Confidence è OBBLIGATORIA** (non ometterla)
- Ogni FR DEVE avere Acceptance Criteria misurabili
- La sezione ADO Mapping è OBBLIGATORIA (Convert-PrdToPbi.ps1 la usa)
- PBI suggeriti: titoli concisi, implementabili in 1 sprint
- Max 1400 parole totali (aumentato per accommodare Evidence section)
"@
}

# ─── Scrum Master system prompt (scrum-master skill) ────────────────────────

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
        Write-Host ""
        Write-Host "  ── Anteprima $docLabel ──────────────────────────────" -ForegroundColor Yellow
        $lines   = Get-Content $docPath
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
    Write-Host "║  EasyWay SDLC Orchestrator v3 — BA→PM→PBI→SM+RAG  ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

# ─── FASE 0: Gather context ──────────────────────────────────────────────────

Write-Phase "[0/4] CONTESTO — domande + auto-suggest + RAG"

if (-not $FeatureName) {
    $FeatureName = Ask "Nome feature (slug, es. 'agent-interactive-sdlc')"
    if (-not $FeatureName) { throw "FeatureName obbligatorio." }
}

if (-not $Description) {
    $Description = Ask "Descrizione breve della feature"
    if (-not $Description) { throw "Description obbligatoria." }
}

# v3: Auto-suggest Dominio e Pattern via LLM
$suggestApplied = $false
if (-not $NoConfirm -and (-not $Domain -or -not $PbiPattern) -and -not $Json) {
    Write-Step "Auto-suggest dominio e pattern via LLM..."
    $suggest = Invoke-LLMAutoSuggest $FeatureName $Description
    if ($suggest) {
        Write-Host ""
        Write-Host "  [LLM suggerisce] Dominio: $($suggest.domain) | Pattern: $($suggest.pattern)" -ForegroundColor Magenta
        $ans = Read-Host "  [INVIO per accettare / digita alternativa per Dominio]"
        if (-not $ans) {
            if (-not $Domain) { $Domain = $suggest.domain }
            $ans2 = Read-Host "  [INVIO per accettare Pattern '$($suggest.pattern)' / digita alternativa]"
            if (-not $ans2) {
                if (-not $PbiPattern) { $PbiPattern = $suggest.pattern }
            } else {
                $PbiPattern = $ans2
            }
        } else {
            $Domain = $ans
        }
        $suggestApplied = $true
    }
}

# Domanda 2: Dominio (se non già settato dall'auto-suggest)
if (-not $Domain -or $DOMAINS -notcontains $Domain) {
    $Domain = AskChoice "Dominio" $DOMAINS
}

# Domanda 1: Epic — usa ADO discovery
$EpicId = Ask-EpicId

# Domanda 3: Pattern PBI (se non già settato dall'auto-suggest)
if (-not $PbiPattern -or $PBI_PATTERNS -notcontains $PbiPattern) {
    $PbiPattern = AskChoice "Pattern PBI" $PBI_PATTERNS
}

$slug    = Get-SlugFromName $FeatureName
$wikiDir = "$WIKI_BASE/$slug"
$briefPath  = "$wikiDir/product-brief.md"
$prdPath    = "$wikiDir/prd.md"
$sprintPath = "$wikiDir/sprint-plan.md"

# v3: InitiativeId — auto-gen se non passato
if (-not $InitiativeId) {
    $dateStamp    = Get-Date -Format 'yyyyMMdd'
    $InitiativeId = "INIT-$dateStamp-$slug"
}

$generatedTs = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'

Write-Step "Feature slug  : $slug"
Write-Step "InitiativeId  : $InitiativeId"
Write-Step "Wiki path     : $wikiDir"
if ($EpicId -gt 0) { Write-Step "Epic: AB#$EpicId" }
Write-Step "Domain: $Domain  |  Pattern: $PbiPattern"

if (-not (Test-Path $wikiDir)) {
    New-Item -ItemType Directory -Path $wikiDir -Force | Out-Null
    Write-Step "Creata directory: $wikiDir"
}

# ─── FASE 0.5 (v3): RAG pre-Brief ────────────────────────────────────────────

Write-Phase "[0.5/4] RAG — Qdrant knowledge search"

$ragQuery1  = "$Domain $FeatureName"
$ragQuery2  = $Description.Substring(0, [Math]::Min(120, $Description.Length))
$ragContext = Invoke-RAGSearch @($ragQuery1, $ragQuery2) -k 5

if ($ragContext) {
    $chunkCount = ([regex]::Matches($ragContext, '---')).Count
    Write-Ok "RAG: $chunkCount chunk trovati da wiki — iniettati nei prompt BA e PM"
} else {
    Write-Step "RAG: QDRANT_URL non configurato o Qdrant offline — proseguo senza contesto wiki"
    Write-Step "(Configura: QDRANT_URL=http://localhost:6333 in .env.local, via SSH tunnel)"
}

# ─── front-matter helper ─────────────────────────────────────────────────────

$docMeta = @{
    initiative_id = $InitiativeId
    prd_id        = "PRD-$(Get-Date -Format 'yyyyMMdd')-$slug"
    epic_id       = if ($EpicId -gt 0) { "AB#$EpicId" } else { 'N/A' }
    domain        = $Domain
    generated     = $generatedTs
}

# ─── FASE 1: Product Brief ───────────────────────────────────────────────────

Write-Phase "[1/4] PRODUCT BRIEF — Business Analyst (Fan-Out + RAG)"

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

$baSystem = Get-BAPrompt $EpicId $Domain $PbiPattern $ragContext
$baUser   = "Crea il product brief per questa feature EasyWay:`n`nNome: $FeatureName`nDescrizione: $Description`nEpic ADO: AB#$EpicId`nDominio: $Domain`nPattern PBI: $PbiPattern"

if (-not $skipThisBrief) {
    Write-Step "Generando product-brief.md via LLM (Fan-Out a 4 dimensioni + RAG)..."
    $briefContent = Invoke-LLMWithFallback $baSystem $baUser
    # v3: aggiungi front-matter
    $briefWithFrontMatter = Add-InitiativeHeader $briefContent $docMeta
    Set-Content -Path $briefPath -Value $briefWithFrontMatter -Encoding UTF8
    Write-Ok "product-brief.md generato → $briefPath"
} else {
    Write-Step "Usando product-brief.md esistente: $briefPath"
}

if (-not $Json) {
    Invoke-DocApproval $briefPath "Product Brief" $baSystem $baUser
}

# ─── FASE 2: PRD ─────────────────────────────────────────────────────────────

Write-Phase "[2/4] PRD — Product Manager (Evidence/Confidence)"

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
$pmSystem = Get-PMPrompt $EpicId $Domain $FeatureName $ragContext
$pmUser   = "Crea il PRD per questa feature EasyWay basandoti sul product brief qui sotto.`n`nPRODUCT BRIEF:`n$briefContent"

if (-not $skipThisPrd) {
    Write-Step "Generando prd.md via LLM (Evidence/Confidence + RAG sources)..."
    $prdContent = Invoke-LLMWithFallback $pmSystem $pmUser -maxTokens 3500
    # v3: aggiungi front-matter
    $prdWithFrontMatter = Add-InitiativeHeader $prdContent $docMeta
    Set-Content -Path $prdPath -Value $prdWithFrontMatter -Encoding UTF8
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
        Write-Step "Applicando — creazione PBI su ADO (con InitiativeId=$InitiativeId)..."
        $convertArgs = @('-PrdPath', $prdPath, '-Apply', '-NoConfirm')
        if ($EpicId -gt 0)     { $convertArgs += @('-EpicId', $EpicId) }
        if ($InitiativeId)     { $convertArgs += @('-InitiativeId', $InitiativeId) }  # v3
        if ($Json)             { $convertArgs += '-Json' }

        $convertOut = & pwsh $convertScript @convertArgs
        if ($Json) {
            try {
                $parsed = $convertOut | ConvertFrom-Json
                $createdPbiIds = $parsed.pbiIds
            } catch { }
        } else {
            $convertOut | ForEach-Object {
                if ($_ -match 'PBI #(\d+) creato') { $createdPbiIds += [int]$Matches[1] }
            }
        }

        if ($createdPbiIds.Count -gt 0) {
            Write-Step "Saga log: $($createdPbiIds.Count) PBI creati: $($createdPbiIds -join ', ')"
        }
    }
}

# ─── FASE 4: Sprint Plan — Scrum Master ───────────────────────────────────────

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

        $prdForSprint = Get-Content $prdPath -Raw -Encoding UTF8
        $pbiListStr   = if ($createdPbiIds.Count -gt 0) {
            "PBI creati su ADO: " + ($createdPbiIds | ForEach-Object { "AB#$_" } | Join-String ', ')
        } else {
            "PBI IDs: non ancora creati su ADO (usa i PBI suggeriti nel PRD)"
        }

        $smSystem = Get-ScrumMasterPrompt $FeatureName $Domain
        $smUser   = "Crea il piano sprint per questa feature basandoti su PRD e lista PBI.`n`n$pbiListStr`n`nPRD:`n$prdForSprint"

        $sprintContent = Invoke-LLMWithFallback $smSystem $smUser
        # v3: aggiungi front-matter
        $sprintWithFrontMatter = Add-InitiativeHeader $sprintContent $docMeta
        Set-Content -Path $sprintPath -Value $sprintWithFrontMatter -Encoding UTF8
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
    featureName   = $FeatureName
    slug          = $slug
    initiativeId  = $InitiativeId          # v3
    epicId        = $EpicId
    domain        = $Domain
    briefPath     = $briefPath
    prdPath       = $prdPath
    sprintPath    = $sprintPath
    pbiIds        = $createdPbiIds
    ragUsed       = [bool]$ragContext       # v3
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  SDLC Orchestrator v3 — COMPLETATO" -ForegroundColor Green
    Write-Host ""
    Write-Host "  InitiativeId  : $InitiativeId" -ForegroundColor White
    Write-Host "  Product Brief : $briefPath" -ForegroundColor White
    Write-Host "  PRD           : $prdPath" -ForegroundColor White
    Write-Host "  Sprint Plan   : $sprintPath" -ForegroundColor White
    if ($createdPbiIds.Count -gt 0) {
        Write-Host "  PBI creati    : $($createdPbiIds -join ', ')" -ForegroundColor White
    }
    Write-Host "  RAG usato     : $(if ($ragContext) { 'Sì' } else { 'No (QDRANT_URL non configurato)' })" -ForegroundColor White
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
}
