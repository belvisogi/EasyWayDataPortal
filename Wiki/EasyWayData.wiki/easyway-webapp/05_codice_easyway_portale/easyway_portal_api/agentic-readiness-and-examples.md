---
id: ew-agentic-readiness-examples
title: Agentic Readiness & Esempi (Users/Onboarding)
summary: Linee guida agentiche e esempi pratici per generare DDL/SP e integrarli con l'API.
status: active
owner: team-api
created: '2025-10-18'
updated: '2025-10-18'
tags: [artifact-agentic, domain/frontend, layer/spec, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
next: TODO - definire next step.
---
# Agentic Readiness & Esempi (Users/Onboarding)

## Scopo
Rendere il Portale 100% agentico: agenti (LLM/tooling) devono poter proporre, generare e applicare DDL/SP in modo sicuro e idempotente, rispettando gli standard EasyWay, con test e pipeline.

## Linee guida agentiche
- Riferimento centrale: `docs/agentic/AGENTIC_READINESS.md:1`
  - Principi: idempotenza, solo SP per DML, logging obbligatorio, variante `_DEBUG`, naming, sicurezza.
  - Mini‑DSL JSON per generare DDL e SP dai template.
  - Guardrail e processo PR/migrazioni.
- Template SQL:
  - DDL tabella: `docs/agentic/templates/ddl/template_table.sql:1`
  - SP produzione: `docs/agentic/templates/sp/template_sp_insert.sql:1`, `template_sp_update.sql:1`, `template_sp_delete.sql:1`
  - SP debug: `docs/agentic/templates/sp/template_sp_debug_insert.sql:1`

## Esempio 1 — USERS (CRUD via SP)
Obiettivo: eliminare DML diretti dalle API e passare a SP coerenti con il DDL standard `PORTAL.USERS`.

1) Mini‑DSL JSON proposto all’agente
```json
{
  "entity": "USERS",
  "schema": "PORTAL",
  "columns": [
    {"name": "user_id", "type": "NVARCHAR(50)", "constraints": ["UNIQUE", "NOT NULL"]},
    {"name": "tenant_id", "type": "NVARCHAR(50)", "constraints": ["NOT NULL"]},
    {"name": "email", "type": "NVARCHAR(255)", "constraints": ["NOT NULL"]},
    {"name": "profile_code", "type": "NVARCHAR(50)", "constraints": ["NOT NULL"]},
    {"name": "status", "type": "NVARCHAR(50)", "constraints": []}
  ],
  "ndg": {"sequence": "SEQ_USER_ID", "prefix": "CDI", "width": 9},
  "sp": {
    "insert": {"name": "sp_insert_user"},
    "update": {"name": "sp_update_user"},
    "delete": {"name": "sp_delete_user"},
    "debug":  {"name": "sp_debug_insert_user"}
  }
}
```sql

2) Output atteso (generato dai template)
- SP produzione: `PORTAL.sp_insert_user`, `PORTAL.sp_update_user`, `PORTAL.sp_delete_user`
- SP debug: `PORTAL.sp_debug_insert_user`
- Tutte con TRY/CATCH, TRANSACTION e scrittura su `PORTAL.STATS_EXECUTION_LOG`.

3) Integrazione API
- Il controller `easyway-portal-api/src/controllers/usersController.ts:1` deve invocare solo SP (`pool.request().execute('PORTAL.sp_update_user')`, ecc.).
- Validatori Zod aggiornati al modello DDL: `profile_code`, `status` (e/o mapping documentato da `display_name/profile_id`).

4) Test
- REST Client: `tests/api/rest-client/users.http:1`
- Checklist agentica: `tests/agentic/README.md:1`

## Esempio 2 — ONBOARDING (Tenant + Admin User)
Obiettivo: confermare il pattern SP + variante DEBUG per onboarding.

1) SP di riferimento (Wiki)
- Produzione: `PORTAL.sp_register_tenant_and_user` (vedi `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure.md:2798`)
- Debug: `PORTAL.sp_debug_register_tenant_and_user` (`.../stored-procedure.md:2901`)

2) Mini‑DSL JSON (per generare/aggiornare le SP da template)
```json
{
  "entity": "tenant_and_user",
  "schema": "PORTAL",
  "sp": {
    "insert": {"name": "sp_register_tenant_and_user"},
    "debug":  {"name": "sp_debug_register_tenant_and_user"}
  },
  "ndg": {
    "tenant": {"sequence": "SEQ_TENANT_ID", "prefix": "TEN", "width": 9},
    "user":   {"sequence": "SEQ_USER_ID",   "prefix": "CDI", "width": 9}
  }
}
```sql

3) Integrazione API
- Controller: `easyway-portal-api/src/controllers/onboardingController.ts:1` già invoca la SP debug via `.execute("PORTAL.sp_debug_register_tenant_and_user")`.
- Input validato: `easyway-portal-api/src/validators/onboardingValidator.ts:1`

4) Test
- REST Client: `tests/api/rest-client/onboarding.http:1`
- Log conversazionali/agent-aware: presenti nel controller con `logger.info/error`.

## Processo PR/Migrazioni (riassunto)
1. L'agente propone mini-DSL JSON e genera i file SQL dai template (`docs/agentic/templates/...`).
2. I file vanno versionati come migrazioni Flyway in `db/flyway/sql/` con naming Flyway (`V<ts>__...sql`).
3. Aggiornare la Wiki (questa pagina) con i riferimenti a nuove SP/tabelle.
4. Pipeline: applica migrazioni in `test`, esegue smoke test (`tests/api/rest-client/...`).
5. Approvazione e promozione verso UAT/PROD.









