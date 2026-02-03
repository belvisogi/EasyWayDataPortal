---
id: ew-orch-ado-userstory-create
title: ADO User Story Create (WHAT)
summary: Creazione User Story su Azure DevOps con prefetch best practices (Wiki + esterne).
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, privacy/internal, language/it, ado]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-09'
next: Aggiungere esempi output stateBefore/stateAfter.
---

[[../start-here.md|Home]] > [[../ado-operating-model.md|Ado]] > Orchestration

# ADO User Story Create (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/ado-userstory-create.intent.json`
- Intent (prefetch): `docs/agentic/templates/intents/ado-bestpractice-prefetch.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/ado-userstory-create.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `ado-userstory-create`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "ado-userstory-create",
    "params": {
      "ado": {
        "orgUrl": "https://dev.azure.com/<org>",
        "project": "<project>"
      },
      "title": "Come utente voglio ... per ...",
      "prefetchBestPractices": true,
      "downloadExternal": true
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "ado-userstory-create-001"
  }
}
```sql

Riferimenti
- Output contract: `Wiki/EasyWayData.wiki/output-contract.md`
- Intent contract: `Wiki/EasyWayData.wiki/intent-contract.md`
- Policy ADO (Operating Model): `Wiki/EasyWayData.wiki/ado-operating-model.md`

## Vedi anche

- [Agent Scaffold (WHAT)](./agent-scaffold.md)
- [Orchestrator n8n (WHAT)](./orchestrator-n8n.md)




