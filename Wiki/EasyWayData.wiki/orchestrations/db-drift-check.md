---
id: ew-orch-db-drift-check
title: DB Drift Check (WHAT)
summary: Verifica la conformità degli oggetti database (tabelle, stored procedure) rispetto alla configurazione attesa, generando un report delle discrepanze (drift). Utile per gate di governance.
status: active
owner: team-data
tags: [domain/db, layer/orchestration, audience/dba, privacy/internal, language/it, quality, drift]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-16'
next: Integrare il report nel Quest Board DQ.
---

[[../start-here.md|Home]] > [[../domains/db.md|db]] > Orchestration

# DB Drift Check (WHAT)

## Domande a cui risponde
1. Come faccio a verificare se il DB di produzione è allineato con il codice?
2. Quale action n8n devo lanciare per controllare il drift?
3. Dove trovo le specifiche degli oggetti "Required"?

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
```sql

Riferimenti
- Governance gates: `Wiki/EasyWayData.wiki/agents-governance.md`



## Vedi anche

- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB Migrate (Flyway) (WHAT)](./db-migrate.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [KB Assessment (WHAT)](./kb-assessment.md)





