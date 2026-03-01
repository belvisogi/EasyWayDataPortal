---
prd_id: PRD-20260301-sdlc-orchestrator-v3
initiative_id: INIT-20260301-sdlc-orchestrator-v3
author: agent_discovery + Giuseppe Belviso
status: Approved
date: 2026-03-01
epic_id: N/A (infrastructure)
domain: Governance
---

# PRD — Invoke-SDLCOrchestrator v3

## Executive Summary

Il test live del flusso SDLC agentico (Session 43) ha evidenziato 3 gap critici rispetto al
design MASTER (`EASYWAY_AGENTIC_SDLC_MASTER.md`): nessun RAG pre-Brief (l'agente parte da
"tabula rasa"), PRD senza Evidence/Confidence (gap anti-allucinazione), e nessun `initiative_id`
propagato tra i documenti e i work item ADO. La v3 chiude questi tre gap e migliora l'UX con
auto-suggest LLM per dominio/pattern e skip silenzioso quando ADO è offline.

---

## Requisiti Funzionali

### FR-001: RAG pre-Brief su Qdrant [MUST]

**Descrizione**: Prima di generare il Product Brief (Fase 1), l'orchestratore interroga la
Knowledge Base EasyWay (Qdrant 167k chunks) con 2 query derivate da feature name, domain e
description. I chunk rilevanti vengono iniettati nel prompt BA come `CONOSCENZA WIKI EasyWay`
così il LLM non parte da tabula rasa.

**Acceptance Criteria**:
- Se `QDRANT_URL` è configurato (env o `.env.local`), viene eseguita la query Qdrant prima della Fase 1
- Il contesto RAG (max 10 chunk, 400 chars/chunk) viene iniettato nel system prompt BA
- Se Qdrant è irraggiungibile o `QDRANT_URL` non è configurato, l'orchestratore continua senza RAG (silent skip)
- Il numero di chunk trovati è loggato a schermo: `→ RAG: N chunk trovati da wiki`
- Il contesto RAG è anche passato alla Fase 2 (PRD) per la sezione Evidence

**Priorità**: MUST

**Configurazione**:
- `QDRANT_URL` in `.env.local` → es. `http://localhost:6333` (via SSH tunnel) o URL diretto
- `QDRANT_API_KEY` in `.env.local` → chiave Qdrant
- Nota: se si usa la porta 6333 remota, configurare SSH tunnel prima di lanciare l'orchestratore:
  ```
  ssh -L 6333:localhost:6333 -i /c/old/Virtual-machine/ssh-key-2026-01-25.key ubuntu@80.225.86.168 -f -N
  ```

---

### FR-002: Evidence & Confidence nel PRD [MUST]

**Descrizione**: Il prompt PM viene aggiornato per richiedere una sezione `## Evidence & Confidence`
(tabella con Area / Evidence / Confidence / Note). Le fonti RAG ottenute nella Fase 0 vengono
fornite come context al PM così le può citare come evidence. La regola è: Confidence = Low implica
nota "⚠️ Richiede validazione umana" nella riga della tabella.

**Acceptance Criteria**:
- Il PRD generato contiene la sezione `## Evidence & Confidence` con almeno 3 righe
- Ogni area tecnica chiave (data model, security, integration) ha una riga nella tabella
- Se RAG ha trovato chunk rilevanti, le fonti wiki sono usate come Evidence
- Le righe con Confidence = Low contengono la nota di validazione
- L'Approval loop (A/R/E/Q) mostra la sezione Evidence nel preview

**Priorità**: MUST

---

### FR-003: Traceability initiative_id end-to-end [MUST]

**Descrizione**: All'avvio dell'orchestratore viene generato un `initiative_id` univoco nel formato
`INIT-YYYYMMDD-<slug>` (es. `INIT-20260301-agent-interactive-sdlc`). Questo ID viene:
1. Scritto come YAML front-matter in `product-brief.md`, `prd.md` e `sprint-plan.md`
2. Passato a `Convert-PrdToPbi.ps1` tramite il nuovo parametro `-InitiativeId`
3. Aggiunto alla descrizione HTML di ogni PBI creato su ADO come `Initiative ID: INIT-...`
4. Incluso nell'output JSON finale (`initiativeId`)

**Acceptance Criteria**:
- `initiative_id` è presente nel front-matter di tutti i documenti generati
- Ogni PBI creato su ADO ha `<b>Initiative ID</b>: INIT-...` nella descrizione
- L'output JSON finale include `initiativeId`
- Se `-InitiativeId` è passato come parametro, viene usato quello (non auto-generato)
- Il front-matter include anche: `prd_id`, `epic_id`, `domain`, `generated` (timestamp ISO)

**Priorità**: MUST

---

### FR-004: Auto-suggest Dominio e Pattern via LLM [SHOULD]

**Descrizione**: Dopo aver ricevuto `FeatureName` e `Description`, e prima di chiedere il dominio
all'utente, l'orchestratore effettua una chiamata LLM veloce per ottenere un suggerimento di
Dominio e Pattern PBI. Il suggerimento viene presentato all'utente che può confermarlo con INVIO
o sostituirlo digitando un'alternativa.

**Acceptance Criteria**:
- LLM call per auto-suggest ha `max_tokens=150` e `temperature=0.1` (veloce)
- Il suggerimento viene mostrato: `[LLM suggerisce] Dominio: X | Pattern: Y`
- L'utente può premere INVIO per accettare o digitare un valore diverso
- Se LLM non è disponibile (nessuna API key), si prosegue direttamente con le domande standard
- Con `-NoConfirm` il suggerimento LLM viene accettato automaticamente

**Priorità**: SHOULD

---

### FR-005: Epic skip silenzioso quando ADO è offline [SHOULD]

**Descrizione**: Quando ADO non è raggiungibile durante la fase di discovery delle epiche, la
funzione `Ask-EpicId` non mostra warning rossi ma un messaggio neutro e procede con la domanda
manuale. Il workflow non si interrompe.

**Acceptance Criteria**:
- Se `Get-ADOActiveEpics` restituisce `@()` per errore di rete, il messaggio è: `ADO offline — inserisci Epic ID manualmente o 0`
- Nessun warning `Write-Warning` viene mostrato in questo scenario
- Con `-NoConfirm`, il fallback è sempre `EpicId = 0`

**Priorità**: SHOULD

---

## Requisiti Non-Funzionali

### NFR-001: RAG timeout [MUST]
**Descrizione**: La chiamata Qdrant deve avere timeout ≤ 10 secondi. Se supera il timeout, si
prosegue senza RAG.
**AC**: Il timeout è configurato con `TimeoutSec 10` su Invoke-RestMethod; errore di timeout
→ `$ragContext = ''`

### NFR-002: Retrocompatibilità parametri [MUST]
**Descrizione**: Tutti i parametri esistenti (`-FeatureName`, `-EpicId`, `-Domain`, ecc.) restano
immutati. I nuovi parametri (`-InitiativeId`, `-RagUrl`) sono opzionali con default sicuri.
**AC**: Chiamate v2 esistenti funzionano senza modifiche.

### NFR-003: Silent degradation [MUST]
**Descrizione**: Se RAG non funziona, se ADO non risponde, o se LLM auto-suggest fallisce,
l'orchestratore NON si interrompe — degrada silenziosamente alla modalità v2.
**AC**: Nessun `throw` nei blocchi RAG e auto-suggest. Solo `try/catch` con `return ''`.

---

## ADO Mapping

| Campo | Valore |
|-------|--------|
| **Epic ID** | N/A (infrastructure skill) |
| **Domain** | Governance |
| **Area Path** | EasyWay\Governance |
| **PBI suggeriti** | - [PBI-1] Implementare RAG pre-Brief in Invoke-SDLCOrchestrator<br>- [PBI-2] Aggiungere Evidence/Confidence al prompt PM<br>- [PBI-3] Propagare initiative_id end-to-end<br>- [PBI-4] Auto-suggest dominio+pattern via LLM<br>- [PBI-5] Epic skip silenzioso ADO offline |

---

## Architettura Tecnica

### Modifiche a Invoke-SDLCOrchestrator.ps1

```
Nuovi parametri:
  [string] $InitiativeId = ''   # auto-gen se vuoto
  [string] $RagUrl = ''         # override QDRANT_URL env var

Nuove funzioni:
  Invoke-RAGSearch([string[]]$queries, [int]$k = 5)
    → chiama Qdrant scroll API con text match
    → restituisce formatted context string o '' se offline

  Invoke-LLMAutoSuggest([string]$name, [string]$desc)
    → chiama LLM con prompt veloce (max_tokens=150)
    → restituisce @{ domain=''; pattern='' } o $null se KO

  New-FrontMatter([hashtable]$meta)
    → genera YAML front-matter per i documenti

  Add-InitiativeHeader([string]$content, [hashtable]$meta)
    → prepend front-matter a un documento generato

Modifiche al flusso:
  Fase 0: FeatureName/Description → auto-suggest LLM → Domain/Epic/Pattern
  Fase 0.5 (nuova): RAG search su Qdrant → $ragContext
  Fase 1: BA prompt + $ragContext iniettato
  Fase 2: PM prompt + $ragContext come fonti Evidence
  Fase 3: Convert-PrdToPbi -InitiativeId $InitiativeId
  Output JSON: aggiunto initiativeId
```

### Modifiche a Convert-PrdToPbi.ps1

```
Nuovo parametro:
  [string] $InitiativeId = ''

In fase di creazione PBI (step 6):
  Se $InitiativeId → aggiunge a descHtml:
    "<p><b>Initiative ID</b>: $InitiativeId</p>"

In JSON output:
  $result.initiativeId = $InitiativeId
```

---

## Out of Scope

- Cambio alla Knowledge API del portal (`/api/knowledge`) — v3 chiama Qdrant direttamente
- Embedding vettoriale — si usa text search (già implementato in Qdrant)
- Modifica a `Convert-PrdToPbi.ps1` per la decomposizione Epic/Feature (rimane PBI-only)
- Dashboard traceability — P2 (sessione futura)

---

## Dipendenze e Rischi

- **Dipendenza**: SSH tunnel per accesso Qdrant locale (`QDRANT_URL=http://localhost:6333`)
- **Rischio top 1**: RAG restituisce chunk non pertinenti → mitigazione: silent skip se score < soglia, e l'utente approva sempre il Brief prima di procedere

---

## Definition of Done

- [ ] `Invoke-SDLCOrchestrator.ps1` v3 funziona con test manuale (FeatureName + Description)
- [ ] RAG context appare nel Brief generato quando Qdrant è raggiungibile
- [ ] PRD generato contiene sezione `## Evidence & Confidence`
- [ ] `initiative_id` nel front-matter di brief.md, prd.md, sprint-plan.md
- [ ] PBI creati su ADO hanno Initiative ID in descrizione
- [ ] Retrocompatibilità: parametri v2 funzionano senza modifiche
- [ ] PR → develop approvata e mergiata
