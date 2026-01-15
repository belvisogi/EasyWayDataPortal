# Agent Governance – Helper interattivo

**Ruolo**: Policy, Quality Gates, Approvals
**Core Tool**: `scripts/agent-governance.ps1`
**Visione**: Qualità non negoziabile, ma automatizzata.

## Scopo
- Proporre attività di quality/gates e lasciare all’utente la scelta di cosa eseguire, con verifiche simili alla pipeline ADO.

## ⚙️ Workflow Standard (3-Step Pattern)

Tutti i task completati da questo agente DEVONO seguire questo pattern:

### 1. Task Boundary Update
Aggiornare task boundary con summary **cumulativo** di tutto il lavoro svolto.
- *Past tense*
- *Comprehensive*

### 2. Walkthrough Artifact
Creare/aggiornare `walkthrough.md` documentando:
- Compliance check eseguiti
- Policy enforceate
- Esito controlli

### 3. Notify User
Chiamare `notify_user` con:
- Path al walkthrough
- Messaggio conciso
- Next steps

### 🦗 GEDI Integration
Opzionalmente, chiamare `agent_gedi` per philosophical review.

## Uso rapido
- Interattivo (consigliato):
  - `pwsh scripts/agent-governance.ps1`
- Selezione esplicita:
  - `pwsh scripts/agent-governance.ps1 -Wiki -Checklist -DbDrift -GenAppSettings`
- Esegui tutto (se abilitato):
  - `pwsh scripts/agent-governance.ps1 -All`
- Dry‑run:
  - `pwsh scripts/agent-governance.ps1 -WhatIf`

## Attività proposte
- Wiki Normalize & Review: normalizza e ricostruisce indici/chunk (`Wiki/EasyWayData.wiki/scripts/*`).
- Pre‑Deploy Checklist (API): controlli env/Auth/DB/Blob/OpenAPI (`npm run check:predeploy`).
- DB Drift Check: verifica oggetti DB richiesti (`npm run db:drift`).
- KB Consistency (advisory): coerenza tra cambi DB/API/agents docs e KB/Wiki.
- Genera App Settings da .env.local: produce `out/appsettings*.json` per deploy.
- Terraform Plan (facoltativo): init/validate/plan su `infra/terraform`.

## 📚 Riferimenti
- **Manifest**: [`manifest.json`](./manifest.json)
- **Standard Workflow**: [`../AGENT_WORKFLOW_STANDARD.md`](../AGENT_WORKFLOW_STANDARD.md)
