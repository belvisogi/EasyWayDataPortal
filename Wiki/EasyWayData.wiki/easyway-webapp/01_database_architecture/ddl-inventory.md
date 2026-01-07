---
id: ew-db-ddl-inventory
title: DB PORTAL - Inventario DDL (canonico)
summary: Inventario DB (canonico) estratto dalle migrazioni Flyway (source-of-truth) per mantenere allineata la Wiki 01_database_architecture.
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Rendere Flyway (`db/flyway/`) la fonte incrementale e rigenerare periodicamente il DDL canonico (snapshot) se necessario; mantenere i legacy export fuori dal retrieval.
---

# DB PORTAL - Inventario DDL (canonico)

## Obiettivo
- Rendere esplicito l'elenco di tabelle e stored procedure usando **solo** le fonti canoniche del repo.
- Ridurre ambiguita: un agente (o un umano) puo verificare rapidamente cosa esiste e dove e documentato.

## Domande a cui risponde
- Quali tabelle/procedure esistono nello schema `PORTAL` secondo le fonti canoniche?
- Quali file sono la fonte e come posso rigenerare questo inventario?

## Source of truth (repo)
- Flyway migrations (canonico, corrente): `db/flyway/sql`

Deploy operativa: usare migrazioni Flyway in `db/flyway/` (apply controllato).

## Tabelle (PORTAL) - canonico
- `PORTAL.CONFIGURATION`
- `PORTAL.LOG_AUDIT`
- `PORTAL.MASKING_METADATA`
- `PORTAL.PROFILE_DOMAINS`
- `PORTAL.RLS_METADATA`
- `PORTAL.SECTION_ACCESS`
- `PORTAL.STATS_EXECUTION_LOG`
- `PORTAL.STATS_EXECUTION_TABLE_LOG`
- `PORTAL.SUBSCRIPTION`
- `PORTAL.TENANT`
- `PORTAL.USER_NOTIFICATION_SETTINGS`
- `PORTAL.USERS`

## Stored procedure (PORTAL) - canonico
- `PORTAL.SP_DEBUG_REGISTER_TENANT_AND_USER`
- `PORTAL.SP_DELETE_CONFIGURATION`
- `PORTAL.SP_DELETE_PROFILE_DOMAIN`
- `PORTAL.SP_DELETE_TENANT`
- `PORTAL.SP_DELETE_USER`
- `PORTAL.SP_INSERT_CONFIGURATION`
- `PORTAL.SP_INSERT_PROFILE_DOMAIN`
- `PORTAL.SP_INSERT_TENANT`
- `PORTAL.SP_INSERT_USER`
- `PORTAL.SP_LOG_STATS_EXECUTION`
- `PORTAL.SP_LOG_STATS_TABLE`
- `PORTAL.SP_SEND_NOTIFICATION`
- `PORTAL.SP_UPDATE_CONFIGURATION`
- `PORTAL.SP_UPDATE_PROFILE_DOMAIN`
- `PORTAL.SP_UPDATE_TENANT`
- `PORTAL.SP_UPDATE_USER`

## Dove e' documentato (Wiki)
- Overview schema/tabelle: `easyway-webapp/01_database_architecture/portal.md`
- Data dictionary tabelle (blueprint): `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/tables/index.md`
- Overview SP: `easyway-webapp/01_database_architecture/storeprocess.md`
- SP per area: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/index.md`
- Logging: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md`

## Rigenerazione (idempotente)
- Solo Flyway (canonico): `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki`
- Include provisioning (dev/local): `pwsh scripts/db-ddl-inventory.ps1 -IncludeProvisioning -WriteWiki`
- Include snapshot DDL (legacy): `pwsh scripts/db-ddl-inventory.ps1 -IncludeSnapshot -WriteWiki`
- Include legacy export (audit): `pwsh scripts/db-ddl-inventory.ps1 -IncludeLegacy -WriteWiki`


