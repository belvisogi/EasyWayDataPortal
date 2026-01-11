---
id: ew-orch-db-drift-check
title: DB Drift Check (WHAT)
summary: Verifica drift DB (oggetti richiesti) e produce un report machine-readable per gate/governance.
status: draft
owner: team-data
tags: [domain/db, layer/orchestration, audience/dba, privacy/internal, language/it, quality, drift]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare al workflow n8n reale e includere formato report.
---

# DB Drift Check (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/db-drift-check.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-drift-check.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-drift-check`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-drift-check",
    "params": { "targetEnv": "prod" },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-104"
  }
}
```

Riferimenti
- Governance gates: `Wiki/EasyWayData.wiki/agents-governance.md`



## Vedi anche

- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB Migrate (Flyway) (WHAT)](./db-migrate.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [KB Assessment (WHAT)](./kb-assessment.md)

