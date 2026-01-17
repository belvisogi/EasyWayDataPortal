---
id: ew-orch-db-user-revoke
title: DB User Revoke (WHAT)
summary: Revoca un utente DB in modo governato (WhatIf-by-default) e registra l'operazione per audit e compliance (registry/logs).
status: active
owner: team-data
tags: [domain/db, layer/orchestration, audience/dba, privacy/internal, language/it, security, iam]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-16'
next: Aggiungere esempi output stateBefore/stateAfter.
---

[[start-here|Home]] > [[domains/db|db]] > [[Layer - Orchestration|Orchestration]]

# DB User Revoke (WHAT)

## Domande a cui risponde
1. Come revoco un'utenza tecnica dal database in emergenza?
2. L'azione cancella l'utente o toglie solo i permessi?
3. Viene generato un log di audit per la revoca?

Contratto
- Intent: `docs/agentic/templates/intents/db-user-revoke.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-user-revoke.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-user-revoke`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-user-revoke",
    "params": {
      "server": "<server>",
      "database": "<db>",
      "username": "svc_tenant01_writer",
      "auth": "sql"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-108"
  }
}
```sql



## Vedi anche

- [DB User Rotate (WHAT)](./db-user-rotate.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [IAM Provision Access (WHAT)](./iam-provision-access.md)
- [DB Migrate (Flyway) (WHAT)](./db-migrate.md)


