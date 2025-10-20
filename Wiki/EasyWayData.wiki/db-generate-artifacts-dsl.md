---
title: Generare DDL+SP da mini-DSL (agent-aware)
tags: [db, dsl, generator, flyway]
status: draft
---

Obiettivo
- Partendo da un JSON mini-DSL, generare DDL tabella e SP (insert/update/delete) conformi agli standard EasyWay, pronti per Flyway.

Esempio DSL (salva in `dsl/user.json`)
```json
{
  "entity": "USERS",
  "schema": "PORTAL",
  "columns": [
    {"name": "user_id", "type": "NVARCHAR(50)", "constraints": ["NOT NULL", "UNIQUE"]},
    {"name": "tenant_id", "type": "NVARCHAR(50)", "constraints": ["NOT NULL"]},
    {"name": "email", "type": "NVARCHAR(255)", "constraints": ["NOT NULL"]}
  ],
  "sp": {
    "insert": {"name": "sp_insert_user"},
    "update": {"name": "sp_update_user"},
    "delete": {"name": "sp_delete_user"}
  }
}
```

Comando generatore
- `node agents/core/generate-db-artifacts.js --in dsl/user.json --out db/flyway/sql`

Output atteso
- Un file in `db/flyway/sql` con nome tipo: `VYYYYMMDDHHMMSS__PORTAL_users_generated.sql` che contiene:
  - DDL tabella (idempotente, `IF OBJECT_ID ... IS NULL`)
  - SP `sp_insert_*`, `sp_update_*`, `sp_delete_*` con logging su `PORTAL.STATS_EXECUTION_LOG`

Prossimi passi
- Completare i blocchi `-- TODO` (parametri e logica specifica) prima dell’esecuzione.
- Eseguire validazione:
  - CI: job `FlywayValidateAny` (automatico se `FLYWAY_ENABLED=true`).
  - Locale: `cd db/flyway && flyway -configFiles=flyway.conf validate`.
- Aggiornare la KB con una ricetta se si introduce una nuova procedura rilevante.

Troubleshooting
- Se il file non compare: verificare Node installato e percorso `--out`.
- Se `flyway validate` fallisce: correggere syntax o naming e rigenerare.

Riferimenti
- `agents/core/generate-db-artifacts.js`
- `docs/agentic/templates/ddl/template_table.sql`
- `docs/agentic/templates/sp/...`
- `docs/agentic/AGENTIC_READINESS.md`

