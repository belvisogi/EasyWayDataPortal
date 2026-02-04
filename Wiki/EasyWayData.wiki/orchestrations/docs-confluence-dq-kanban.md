---
id: ew-orch-docs-confluence-dq-kanban
title: Docs DQ Kanban - Confluence Cloud (WHAT)
summary: Export read-only da Confluence Cloud + creazione/aggiornamento pagina Kanban dedicata (HITL, WhatIf di default) per la DQ della documentazione.
status: draft
owner: team-platform
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, confluence, dq, kanban, governance]
llm:
  redaction: [email, phone]
  include: true
  pii: none
  chunk_hint: 250-400
entities: []
updated: '2026-01-09'
next: Aggiungere una checklist di esito (export OK, pagina aggiornata, link ai report) o un next step esplicito.
type: guide
---

[[../start-here.md|Home]] > [[../domains/docs-governance.md|Docs]] > Orchestration

# Docs DQ Kanban - Confluence Cloud (WHAT)

Parametri (source of truth)
- `scripts/intents/docs-dq-confluence-cloud-001.json`

Contratto
- Intent: `docs/agentic/templates/intents/docs-confluence-dq-kanban.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/docs-confluence-dq-kanban.manifest.json`

## Runtime

### 1) Plan (no network, no write)
```powershell
pwsh scripts/confluence-dq-board.ps1 -IntentPath "scripts/intents/docs-dq-confluence-cloud-001.json" -PlanOnly
```sql

### 2) Export (richiede network + credenziali via env var)
Env:
- `CONFLUENCE_EMAIL`
- `CONFLUENCE_API_TOKEN`

```powershell
pwsh scripts/confluence-dq-board.ps1 -IntentPath "scripts/intents/docs-dq-confluence-cloud-001.json" -Export
```sql

Output:
- `out/confluence/pages.jsonl`

### 3) (Opz.) Update pagina Kanban (HITL)
Di default e' `-WhatIf` (nessuna scrittura su Confluence).
```powershell
pwsh scripts/confluence-dq-board.ps1 -IntentPath "scripts/intents/docs-dq-confluence-cloud-001.json" -Export -UpdateBoard -WhatIf
```sql

Per scrivere davvero (solo dopo approvazione):
```powershell
pwsh scripts/confluence-dq-board.ps1 -IntentPath "scripts/intents/docs-dq-confluence-cloud-001.json" -Export -UpdateBoard -WhatIf:$false
```sql





