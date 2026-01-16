---
title: Generare DDL+SP da mini-DSL (agent-aware)
tags: [db, dsl, generator, flyway, domain/db, layer/howto, audience/dev, audience/dba, privacy/internal, language/it]
status: active
id: ew-db-generate-artifacts-dsl
summary: 'Documento su Generare DDL+SP da mini-DSL (agent-aware).'
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
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
```sql

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


## Domande a cui risponde
- Qual e' l'obiettivo di questa procedura e quando va usata?
- Quali prerequisiti servono (accessi, strumenti, permessi)?
- Quali sono i passi minimi e quali sono i punti di fallimento piu comuni?
- Come verifico l'esito e dove guardo log/artifact in caso di problemi?

## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.



## Vedi anche

- [Gestione Accessi DB (Contained Users & Ruoli PORTAL)](./db-user-access-management.md)
- [Datalake - Set Retention (Stub)](./datalake-set-retention.md)
- [LLM READINESS CHECKLIST](./llm-readiness-checklist.md)
- [Datalake - Ensure Structure (Stub)](./datalake-ensure-structure.md)
- [Datalake - Apply ACL (Stub)](./datalake-apply-acl.md)

