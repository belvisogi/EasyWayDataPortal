---
id: ew-orch-db-user-rotate
title: DB User Rotate (WHAT)
summary: Ruota le credenziali di un utente DB (password) in modo governato, sincronizzando opzionalmente il nuovo segreto su Key Vault.
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

# DB User Rotate (WHAT)

## Domande a cui risponde
1. Come eseguo la rotazione password periodica per un'utenza applicativa?
2. La nuova password viene salvata automaticamente nel Vault?
3. Cosa succede se la rotazione fallisce a metà?

Contratto
- Intent: `docs/agentic/templates/intents/db-user-rotate.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-user-rotate.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-user-rotate`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-user-rotate",
    "params": {
      "server": "<server>",
      "database": "<db>",
      "username": "svc_tenant01_writer",
      "auth": "sql"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-107"
  }
}
```sql



## Vedi anche

- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [IAM Provision Access (WHAT)](./iam-provision-access.md)
- [DB Migrate (Flyway) (WHAT)](./db-migrate.md)

