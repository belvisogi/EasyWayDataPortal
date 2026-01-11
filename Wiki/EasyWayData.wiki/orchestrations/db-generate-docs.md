---
id: ew-orch-db-generate-docs
title: DB Generate Docs (WHAT)
summary: Rigenera artefatti di documentazione DB (diagram JSON, indici Wiki) in modo governato.
status: draft
owner: team-data
tags: [domain/db, layer/orchestration, audience/dev, audience/dba, privacy/internal, language/it, docs]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare al workflow n8n reale e aggiungere esempi artifacts[].
---

# DB Generate Docs (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/db-generate-docs.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-generate-docs.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-generate-docs`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-generate-docs",
    "params": { "target": "portal-diagram" },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-105"
  }
}
```

Riferimenti
- DB Diagram Viewer: `http://localhost:3000/portal/tools/db-diagram`



## Vedi anche

- [DB User Create (WHAT)](./db-user-create.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [n8n-db-table-create](./n8n-db-table-create.md)
- [DB User Rotate (WHAT)](./db-user-rotate.md)
- [n8n-db-ddl-inventory](./n8n-db-ddl-inventory.md)

