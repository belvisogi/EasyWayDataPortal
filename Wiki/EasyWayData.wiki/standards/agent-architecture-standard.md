---
title: "Agent Architecture Standard"
category: standards
domain: docs
tags: agents, standardization, best-practices, architecture
priority: critical
audience:
  - agent-developers
  - system-architects
last-updated: 2026-01-17
id: ew-standards-agent-architecture-standard
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/spec, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# 🤖 Agent Architecture Standard

Questa pagina definisce lo standard architetturale obbligatorio per la creazione e manutenzione degli agenti AI nel portale EasyWay.

> **Principio**: "Ogni Agente è un Cittadino di Prima Classe". Deve avere identità (Manifest), istruzioni (README) e memoria (Graph/Logs).

## 1. Classificazione Agenti (Brain vs Arm) 🧠💪

Ogni agente deve essere classificato in una delle due categorie:

### 🧠 Strategic Agent (Brain)
- **Ruolo**: Pianificazione, Governance, Decision Making, Gestione Rischi.
- **Capability**: Deve implementare o consultare il loop **OODA**.
- **Integration**: **GEDI Mandatory** (deve consultare GEDI prima di agire).
- **Es**: `agent_governance`, `agent_scrummaster`, `agent_gedi`.

### 💪 Executive Agent (Arm)
- **Ruolo**: Esecuzione Task, Determinismo, Velocità.
- **Capability**: Input -> Azione -> Output (Lineare).
- **Integration**: **GEDI Optional** (solo su errore critico).
- **Es**: `agent_api`, `agent_synapse`, `agent_second_brain`.

## 2. Struttura della Directory

Ogni agente risiede in `agents/<agent_name>/` e DEVE contenere:

```text
agents/agent_name/
├── manifest.json       # 🆔 La Carta d'Identità (Capabilities)
├── README.md           # 📖 Il Manuale d'Uso (Role & Usage)
└── (optional) priority.json / memory/
```sql

Gli script esecutivi (il "cervello") risiedono centralizzati in `scripts/` per favorire il riuso, ma sono referenziati dal manifest.

## 2. Manifest Schema (`manifest.json`)

Il `manifest.json` è il contratto che l'Orchestratore usa per capire cosa sa fare l'agente.

### Campi Obbligatori
- **name**: Nome univoco (es. `Agent_Second_Brain`).
- **classification**: `brain` o `arm` (Obbligatorio).
- **role**: Ruolo funzionale (es. `Navigator`, `Guardian`, `Executor`).
- **description**: Cosa fa e quando chiamarlo.
- **readme**: Link relativo al README (es. `README.md`).
- **knowledge_sources**: Lista file che l'agente "legge" (es. `agents/memory/knowledge-graph.json`).
- **actions**: Lista delle capability (Function Calling).

### Esempio Manifest
```json
{
  "name": "Agent_Audit",
  "role": "Inspector",
  "description": "Esegue audit su conformità e qualità.",
  "readme": "README.md",
  "knowledge_sources": [ "standards/agent-architecture-standard.md" ],
  "actions": [
    {
      "name": "audit:perform",
      "script": "../../scripts/agent-audit.ps1",
      "params": { "Target": "All", "DryRun": false }
    }
  ]
}
```sql

## 3. README Standard (`README.md`)

Ogni agente deve spiegarsi agli umani (e agli altri LLM).

### Sezioni Obbligatorie
1.  **Header**: Nome e Ruolo.
2.  **Overview**: Scopo ad alto livello.
3.  **Capabilities**: Lista puntata di cosa sa fare.
4.  **Architecture**: Script utilizzati, memoria letta/scritta.
5.  **Usage**: Comandi di esempio (PowerShell).
6.  **Principles**: Regole di ingaggio (es. "Idempotenza", "Non-distruttivo").

## 4. Scripting Guidelines (`scripts/*.ps1`)

Gli script PowerShell che implementano l'agente devono seguire queste regole:

1.  **Idempotenza**: Eseguire lo script 2 volte non deve rompere nulla.
2.  **DryRun**: Supportare SEMPRE `-DryRun` per mostrare cosa farebbe senza farlo.
3.  **Logging**: Usare `Write-Host` con colori per feedback umano (Cyan=Info, Green=Success, Yellow=Warn, Red=Error).
4.  **Parameter Validation**: Usare `[ValidateSet()]` e tipi forti.

## 5. Come creare un nuovo Agente

Per creare un nuovo agente conforme allo standard, usare l'agente scaffolder:

```powershell
pwsh scripts/agent-creator.ps1 -Action agent:scaffold -Intent/Params @{ agentName = 'agent_audit' }
# Oppure copia manuale da agent_template
```sql

## 6. Audit & Compliance

Un Agente di Audit (`agent_audit`) verificherà periodicamente:
- Presenza `README.md` linkato nel manifest.
- Validità JSON del manifest.
- Esistenza script referenziati.

### Auto-Remediation 🚑
L'Audit Agent supporta la modalità `-AutoFix`:
- **Crea Manifest**: Se mancano campi (`name`, `readme`), li aggiunge.
- **Crea README**: Se manca file `README.md`, ne genera uno scheletro basato sul ruolo.

```powershell
pwsh scripts/agent-audit.ps1 -AutoFix
```sql

## 7. GEDI Integration & Runtime Lifecycle 🧠

Per i dettagli completi su come un agente "pensa" e "ricorda", fare riferimento a:  
👉 **[Agent Runtime Lifecycle & Memory](../concept/agent-runtime-lifecycle.md)**

### OODA Integration
1.  **Observe**: L'agente raccoglie contesto.
2.  **Call GEDI**: `pwsh scripts/agent-gedi.ps1 -Context "..."`
3.  **Act**: Includere il consiglio di GEDI nei log o nel feedback all'utente.

## 8. Templates & Creation

Quando si crea un nuovo agente, scegliere il template in base alla classificazione:

### 💪 Arm Template (Default)
- **Base**: Copia da `agents/agent_template`.
- **Focus**: Performance, Idempotenza.
- **Script**: Singolo file `.ps1` con switch `-DryRun`.

### 🧠 Brain Template (Advanced)
- **Base**: Arm Template + OODA Loop.
- **Add-on**:
    1. Aggiungere `manifest.json`: `"classification": "brain"`.
    2. Implementare `scripts/agent-NAME.ps1` con logica OODA (vedi `agent_gedi.ps1` come esempio).
    3. Integrare GEDI nelle decisioni critiche.

## 9. Memory Provider & Dual Stack Strategy ☯️

Il sistema opera in due modalità (`Enterprise` vs `Framework`). Gli sviluppatori NON devono scrivere logica condizionale (`if azure`) negli script degli agenti.

### Il Pattern Obbligatorio
Usare sempre e solo le funzioni astratte di `scripts/core/AgentMemory.psm1`:
*   `Get-AgentContext`
*   `Set-AgentContext`
*   `Start-AgentSession`

Il sistema caricherà automaticamente il **Provider** corretto (`AzureMemoryProvider` o `LocalMemoryProvider`) in base alla variabile d'ambiente `$env:EASYWAY_MODE`.

> **Vietato**: Accedere direttamente a file JSON o Azure Storage negli script di logica pura. Usare sempre il modulo Memory.

---
**Status**: Active  
**Owner**: Platform Team


