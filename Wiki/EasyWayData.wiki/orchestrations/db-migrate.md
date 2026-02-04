---
id: ew-orch-db-migrate
title: DB Migrate (SQL Diretto) (WHAT)
summary: Esegue migrazione database su target in modo governato (con approvazione human-in-the-loop per produzione) usando approccio Git + SQL diretto e produce esito strutturato per audit.
status: active
owner: team-data
tags: [domain/db, layer/orchestration, audience/dba, privacy/internal, language/it, migration, sql]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-18'
next: Collegare al workflow n8n reale (validate/apply) e allegare evidenze.
type: guide
---

[[../start-here.md|Home]] > [[../domains/db.md|db]] > Orchestration

> [!NOTE]
> **Approccio Migrazione Database**
> 
> Questo progetto usa **Git + SQL diretto** invece di Flyway.
> 
> **Perché**: Dopo valutazione, Flyway è stato dismesso. Vedi [why-not-flyway.md](../easyway-webapp/01_database_architecture/why-not-flyway.md) per dettagli.
> 
> **Guida completa**: [db-migrations.md](../easyway-webapp/01_database_architecture/db-migrations.md)

# DB Migrate (SQL Diretto) (WHAT)

## Domande a cui risponde

1. Come lancio una migrazione database tramite orchestratore n8n?
2. Posso eseguire solo la validazione senza applicare?
3. Quali file di configurazione servono per l'azione `validate`?

## Contratto

- Intent: `docs/agentic/templates/intents/db-migrate.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/db-migrate.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `db-migrate`)

## Entrypoint (n8n.dispatch)

```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-migrate",
    "params": {
      "action": "validate",
      "migrationFile": "db/migrations/V15__add_notifications.sql",
      "dryRun": true
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-18-001"
  }
}
```sql

## Workflow (Alto Livello)

1. **Validate** - Verifica sintassi SQL e idempotenza
2. **Gate Precheck** - Controlli governance (naming, audit, logging)
3. **Human Approval** - Richiesta approvazione per produzione
4. **Apply** - Esecuzione via sqlcmd/Azure Portal
5. **Log** - Registrazione esito in `agents/logs/events.jsonl`

## Esecuzione Diretta (CLI)

### Validate (Dry Run)

```powershell
# Verifica sintassi SQL
sqlcmd -S $server -d $database -U $user -P $password `
       -i db/migrations/V15__add_notifications.sql `
       -n  # dry run mode
```sql

### Apply (Esecuzione Reale)

```powershell
# Applica migrazione
sqlcmd -S $server -d $database -U $user -P $password `
       -i db/migrations/V15__add_notifications.sql
```sql

## Riferimenti

- [db-migrations.md](../easyway-webapp/01_database_architecture/db-migrations.md) - Guida gestione migrazioni
- [why-not-flyway.md](../easyway-webapp/01_database_architecture/why-not-flyway.md) - Perché NON Flyway
- [ddl-inventory.md](../easyway-webapp/01_database_architecture/ddl-inventory.md) - Inventario DDL

## Vedi anche

- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB Drift Check (WHAT)](./db-drift-check.md)
- [n8n-db-ddl-inventory](./n8n-db-ddl-inventory.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)



