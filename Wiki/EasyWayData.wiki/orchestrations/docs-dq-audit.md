---
id: ew-orch-docs-dq-audit
title: Docs DQ Audit + Kanban (WHAT)
summary: Scorecard di Data Quality per la documentazione (doc-as-data) + backlog Kanban per la revisitazione; update Wiki opzionale (HITL) e reversibile.
status: draft
owner: team-platform
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, governance, dq, kanban]
llm:
  redaction: [email, phone]
  include: true
  pii: none
  chunk_hint: 250-400
entities: []
updated: '2026-01-09'
next: Aggiungere checklist di verifica (scorecard generata, backlog generato, preview kanban) o un next step esplicito.
type: guide
---

[[../start-here.md|Home]] > [[../domains/docs-governance.md|Docs]] > Orchestration

# Docs DQ Audit + Kanban (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/docs-dq-audit.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/docs-dq-audit.manifest.json`
- Quest Board (Wiki): `Wiki/EasyWayData.wiki/quest-board-docs-dq.md`

## Runtime (locale)

### 1) Genera scorecard + backlog (nessuna modifica alla Wiki)
```powershell
pwsh scripts/docs-dq-scorecard.ps1 `
  -WikiPath "Wiki/EasyWayData.wiki" `
  -OutScorecard "out/docs-dq-scorecard.json" `
  -OutBacklog "out/docs-dq-backlog.json" `
  -OutQuestBoardPreview "out/docs-dq-quest-board.preview.md"
```sql

### 2) (Opz.) Aggiorna la pagina Kanban in Wiki (HITL, reversibile)
Di default e' in `-WhatIf`.
```powershell
pwsh scripts/docs-dq-scorecard.ps1 `
  -WikiPath "Wiki/EasyWayData.wiki" `
  -UpdateQuestBoard `
  -WhatIf
```sql

Per applicare davvero:
```powershell
pwsh scripts/docs-dq-scorecard.ps1 `
  -WikiPath "Wiki/EasyWayData.wiki" `
  -UpdateQuestBoard `
  -WhatIf:$false
```sql

Rollback:
- Ogni apply salva backup e summary in `out/docs-dq-scorecard-apply/<runId>/`.





