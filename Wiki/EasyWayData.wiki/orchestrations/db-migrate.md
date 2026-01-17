---
id: ew-orch-db-migrate
title: DB Migrate (Flyway) (WHAT)
summary: Esegue Flyway validate/migrate su database target in modo governato (con approvazione human-in-the-loop per produzione) e produce esito strutturato per audit.
status: active
owner: team-data
tags: [domain/db, layer/orchestration, audience/dba, privacy/internal, language/it, flyway, migration]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-16'
next: Collegare al workflow n8n reale (validate/migrate) e allegare evidenze.
---

[[start-here|Home]] > [[domains/db|db]] > [[Layer - Orchestration|Orchestration]]

# DB Migrate (Flyway) (WHAT)

## Domande a cui risponde
1. Come lancio una migrazione Flyway tramite orchestrare n8n?
2. Posso eseguire solo la validazione senza migrare?
3. Quali file di configurazione servono per l'azione `validate`?

Contratto
- Intent: `docs/agentic/templates/intents/db-migrate.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-migrate.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-migrate`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-migrate",
    "params": {
      "action": "validate",
      "configFiles": "db/flyway/flyway.conf"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-103"
  }
}
```sql

Riferimenti
- Flyway: `Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/flyway.md`



## Vedi anche

- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB Drift Check (WHAT)](./db-drift-check.md)
- [n8n-db-ddl-inventory](./n8n-db-ddl-inventory.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)


