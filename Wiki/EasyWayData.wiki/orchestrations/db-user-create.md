---
id: ew-orch-db-user-create
title: DB User Create (WHAT)
summary: Crea un utente DB in modo governato (WhatIf-by-default), con audit e (opz.) Key Vault.
status: draft
owner: team-data
tags: [domain/db, layer/orchestration, audience/dba, privacy/internal, language/it, security, iam]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Aggiungere esempi output stateBefore/stateAfter.
---

# DB User Create (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/db-user-create.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-user-create.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-user-create`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-user-create",
    "params": {
      "server": "<server>",
      "database": "<db>",
      "username": "svc_tenant01_writer",
      "auth": "sql",
      "roles": ["portal_reader", "portal_writer"]
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-106"
  }
}
```

Riferimenti
- Output contract: `Wiki/EasyWayData.wiki/output-contract.md`



## Vedi anche

- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [DB User Rotate (WHAT)](./db-user-rotate.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [IAM Provision Access (WHAT)](./iam-provision-access.md)
- [DB Migrate (Flyway) (WHAT)](./db-migrate.md)

