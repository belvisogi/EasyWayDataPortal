<#
  Invoke-SDLCOrchestrator.ps1  —  skill planning.sdlc-orchestrator

  Orchestratore interattivo SDLC EasyWay.
  Guida l'utente attraverso le 4 fasi del flusso SDLC agentico:
    Fase 1 — Product Brief   (BA  → LLM → product-brief.md)
    Fase 2 — PRD             (PM  → LLM → prd.md)
    Fase 3 — PBI ADO         (Convert-PrdToPbi.ps1 -WhatIf → -Apply)
    Fase 4 — Branch creation (New-PbiBranch.ps1 per ogni PBI)

  LLM STRATEGY:
    Primary  : DeepSeek (DEEPSEEK_API_KEY)
    Fallback : OpenRouter (OPENROUTER_API_KEY) — antifragile
    Entrambi usano il formato OpenAI-compat (messages, temperature, max_tokens)

  RESUME:
    Se product-brief.md già esiste per la feature → chiede se usare quello esistente.
    Se prd.md già esiste → idem. Permette di riprendere da metà flusso.

  3 DOMANDE PRE-PRD (obbligatorie):
    1. Epic ADO attiva per questo dominio? (ID o "skip")
    2. Dominio? (Infra / AMS / Frontend / Logic / Reporting / Data / Governance)
    3. Pattern Feature/PBI? (Standard feature / Task tecnico / Improvement)

  USO:
    # Interattivo completo
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1

    # Con parametri pre-compilati
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" `
      -Description "Orchestratore conversazionale per il flusso BA→PM→PBI" `
      -EpicId 123 -Domain "Governance"

    # Skip fasi già completate
    pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1 `
      -FeatureName "agent-interactive-sdlc" -SkipBrief

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

# ─── BA system prompt ────────────────────────────────────────────────────────

function Get-BAPrompt([string]$epicId, [string]$domain, [string]$pattern) {
    return @"
Sei un Business Analyst esperto che lavora su EasyWay Data Portal (piattaforma enterprise di gestione dati).
Il tuo compito è creare un product brief completo e azionabile in italiano.

CONTESTO EASYWAY:
- Piattaforma enterprise con backend Node.js/TypeScript, frontend React, DB SQL Server
- Utenti: operatori dati, manager, amministratori di sistema
- Epic ADO: AB#$epicId   Dominio: $domain   Pattern PBI: $pattern
- Wiki-first: evita duplicazioni con funzionalità già esistenti

STRUTTURA PRODUCT BRIEF RICHIESTA:
## 1. Executive Summary
Problema principale, soluzione proposta, utenti target, timeline stimata (2-3 righe)

## 2. Problema
- Descrizione dettagliata del problema
- Chi lo sperimenta (ruoli specifici in EasyWay)
- Impatto se non risolto
- Perché risolvere ora

## 3. Utenti Target
- Persona primaria (ruolo, obiettivi, pain points)
- Persona secondaria (se applicabile)

## 4. Soluzione Proposta
- Descrizione della soluzione
- 3-5 capacità chiave con valore per l'utente
- MVP: cosa è critico vs cosa si può rimandare

## 5. Metriche di Successo
- 2-3 KPI misurabili con baseline e target

## 6. Rischi e Dipendenze
- Top 3 rischi con probabilità, impatto, mitigazione
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
- Priorità: chiarezza e utilizzo pratico
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
    Write-Host "║   EasyWay SDLC Orchestrator — BA → PM → PBI         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

# ─── FASE 0: Gather context ──────────────────────────────────────────────────

Write-Phase "[0/3] CONTESTO — 3 domande pre-PRD"

if (-not $FeatureName) {
    $FeatureName = Ask "Nome feature (slug, es. 'agent-interactive-sdlc')"
    if (-not $FeatureName) { throw "FeatureName obbligatorio." }
}

if (-not $Description) {
    $Description = Ask "Descrizione breve della feature"
    if (-not $Description) { throw "Description obbligatoria." }
}

# Domanda 1: Epic
if ($EpicId -lt 0) {
    $epicRaw = Ask "Epic ADO attiva per questo dominio? (ID numerico o 0 per nessuna)" "0"
    $EpicId = [int]($epicRaw -replace '[^0-9]', '')
}

# Domanda 2: Dominio
if (-not $Domain -or $DOMAINS -notcontains $Domain) {
    $Domain = AskChoice "Dominio" $DOMAINS
}

# Domanda 3: Pattern PBI
if (-not $PbiPattern -or $PBI_PATTERNS -notcontains $PbiPattern) {
    $PbiPattern = AskChoice "Pattern PBI" $PBI_PATTERNS
}

$slug    = Get-SlugFromName $FeatureName
$wikiDir = "$WIKI_BASE/$slug"
$briefPath = "$wikiDir/product-brief.md"
$prdPath   = "$wikiDir/prd.md"

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

Write-Phase "[1/3] PRODUCT BRIEF — Business Analyst"

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

if (-not $skipThisBrief) {
    Write-Step "Generando product-brief.md via LLM..."
    $baSystem = Get-BAPrompt $EpicId $Domain $PbiPattern
    $baUser   = "Crea il product brief per questa feature EasyWay:`n`nNome: $FeatureName`nDescrizione: $Description`nEpic ADO: AB#$EpicId`nDominio: $Domain`nPattern PBI: $PbiPattern"
    $briefContent = Invoke-LLMWithFallback $baSystem $baUser
    Set-Content -Path $briefPath -Value $briefContent -Encoding UTF8
    Write-Ok "product-brief.md generato → $briefPath"
} else {
    Write-Step "Usando product-brief.md esistente: $briefPath"
}

if (-not $Json) {
    $baSystem2 = Get-BAPrompt $EpicId $Domain $PbiPattern
    $baUser2   = "Crea il product brief per questa feature EasyWay:`n`nNome: $FeatureName`nDescrizione: $Description`nEpic ADO: AB#$EpicId`nDominio: $Domain`nPattern PBI: $PbiPattern"
    Invoke-DocApproval $briefPath "Product Brief" $baSystem2 $baUser2
}

# ─── FASE 2: PRD ─────────────────────────────────────────────────────────────

Write-Phase "[2/3] PRD — Product Manager"

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

if (-not $skipThisPrd) {
    Write-Step "Generando prd.md via LLM (usando product-brief come contesto)..."
    $briefContent = Get-Content $briefPath -Raw -Encoding UTF8
    $pmSystem = Get-PMPrompt $EpicId $Domain $FeatureName
    $pmUser   = "Crea il PRD per questa feature EasyWay basandoti sul product brief qui sotto.`n`nPRODUCT BRIEF:`n$briefContent"
    $prdContent = Invoke-LLMWithFallback $pmSystem $pmUser
    Set-Content -Path $prdPath -Value $prdContent -Encoding UTF8
    Write-Ok "prd.md generato → $prdPath"
} else {
    Write-Step "Usando prd.md esistente: $prdPath"
}

if (-not $Json) {
    $pmSystem2 = Get-PMPrompt $EpicId $Domain $FeatureName
    $briefContent2 = Get-Content $briefPath -Raw -Encoding UTF8
    $pmUser2 = "Crea il PRD per questa feature EasyWay basandoti sul product brief qui sotto.`n`nPRODUCT BRIEF:`n$briefContent2"
    Invoke-DocApproval $prdPath "PRD" $pmSystem2 $pmUser2
}

# ─── FASE 3: PBI Creation ─────────────────────────────────────────────────────

Write-Phase "[3/3] PBI ADO — Convert-PrdToPbi"

$convertScript = "$SKILL_DIR/Convert-PrdToPbi.ps1"

if (-not (Test-Path $convertScript)) {
    Write-Warn "Convert-PrdToPbi.ps1 non trovato in $convertScript. Salta fase PBI."
} else {
    Write-Step "WhatIf — PBI che verrebbero creati..."
    if ($EpicId -gt 0) {
        & pwsh $convertScript -PrdPath $prdPath -EpicId $EpicId -WhatIf
    } else {
        & pwsh $convertScript -PrdPath $prdPath -WhatIf
    }

    $doPbi = $true
    if (-not $NoConfirm -and -not $Json) {
        $ans = Ask "Creare i PBI su ADO? [A]pplica / [S]kip" "A"
        $doPbi = ($ans.ToUpper().Trim() -eq 'A')
    }

    $createdPbiIds = @()

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
}

# ─── OUTPUT FINALE ────────────────────────────────────────────────────────────

$result = @{
    featureName = $FeatureName
    slug        = $slug
    epicId      = $EpicId
    domain      = $Domain
    briefPath   = $briefPath
    prdPath     = $prdPath
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
    if ($createdPbiIds.Count -gt 0) {
        Write-Host "  PBI creati    : $($createdPbiIds -join ', ')" -ForegroundColor White
    }
    Write-Host "  ══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
}
