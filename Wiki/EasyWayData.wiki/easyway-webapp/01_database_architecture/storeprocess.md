---
id: ew-db-storeprocess
title: Store Procedure – Standard e catalogo (overview)
summary: Struttura TRY/CATCH + TRAN, logging e output uniformato
status: active
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

[[start-here|Home]] > [[domains/db|db]] > [[Layer - Reference|Reference]]

Standard SP
- Parametri chiari (in/out), `@created_by` obbligatorio
- Transazione + TRY/CATCH
- Logging: `PORTAL.sp_log_stats_execution` (+ `sp_log_stats_table` ove utile)
- Output JSON-friendly: `status`, `id/code`, `error_message`, `rows_*`
- Versione `sp_debug_*` per ambienti test

Source of truth (repo)
- DDL canonico (corrente): `db/flyway/sql/` (migrazioni incrementali)
- Bootstrap dev/local (debug/utility): `db/provisioning/apply-flyway.ps1` (wrapper; applica Flyway con conferma)
- Archivio storico: `old/db/` (non canonico)
- Inventario (Wiki): `easyway-webapp/01_database_architecture/ddl-inventory.md`
- SP per area (Wiki): `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/index.md`

Categorie principali
- Setup/Utility, Tenant, Users, ACL/Profile Domains, Section Access, Config/Subscription, Notifications, Audit/Masking/RLS, Stats/Monitoring, Debug/Diagnostics

Prossimi passi
- Migrazioni dedicate per SP core e versioni debug







