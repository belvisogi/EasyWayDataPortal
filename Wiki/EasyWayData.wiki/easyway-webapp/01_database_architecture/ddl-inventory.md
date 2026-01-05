---
id: ew-db-ddl-inventory
title: DB PORTAL - Inventario DDL (source-of-truth)
summary: Elenco tabelle e stored procedure estratto dai DDL sotto DataBase/, per mantenere allineata la Wiki 01_database_architecture.
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - validare quale file DDL e' canonico (DataBase/ vs db/flyway/sql/) e automatizzare il sync.
---

# DB PORTAL - Inventario DDL (source-of-truth)

## Obiettivo
- Rendere esplicito l'elenco corretto di tabelle e stored procedure del PORTAL DB usando come fonte i DDL sotto DataBase/.
- Ridurre ambiguita: un agente (o un umano) puo verificare rapidamente cosa esiste e dove e documentato.

## Domande a cui risponde
- Quali tabelle esistono nello schema PORTAL secondo i DDL del repo?
- Quali stored procedure esistono nello schema PORTAL secondo i DDL del repo?
- Quali file DDL sono la fonte e come posso rigenerare questo inventario?
- Dove trovo la documentazione umana (01_database_architecture) per ciascun gruppo di SP?

## Source of truth (repo)
- Tabelle: `DataBase/DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql`
- Stored procedure: `DataBase/DDL_PORTAL_STOREPROCES_EASYWAY_DATAPORTAL.sql`
- Logging SP: `DataBase/DDL_STATLOG_STOREPROCES_EASYWAY_DATAPORTAL.sql`

Nota: la deploy operativa tende a usare migrazioni Flyway in db/flyway/sql/. Questo inventario serve a mantenere la Wiki allineata alla lista dichiarata in DataBase/.

## Tabelle (PORTAL)
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

## Stored procedure (PORTAL)
- `PORTAL.sp_debug_insert_configuration`
- `PORTAL.sp_debug_insert_profile_domain`
- `PORTAL.sp_debug_insert_section_access`
- `PORTAL.sp_debug_insert_subscription`
- `PORTAL.sp_debug_insert_tenant`
- `PORTAL.sp_debug_insert_user`
- `PORTAL.sp_debug_insert_user_notification_setting`
- `PORTAL.sp_delete_configuration`
- `PORTAL.sp_delete_profile_domain`
- `PORTAL.sp_delete_section_access`
- `PORTAL.sp_delete_subscription`
- `PORTAL.sp_delete_tenant`
- `PORTAL.sp_delete_user`
- `PORTAL.sp_delete_user_notification_setting`
- `PORTAL.sp_insert_configuration`
- `PORTAL.sp_insert_profile_domain`
- `PORTAL.sp_insert_section_access`
- `PORTAL.sp_insert_subscription`
- `PORTAL.sp_insert_tenant`
- `PORTAL.sp_insert_user`
- `PORTAL.sp_insert_user_notification_setting`
- `PORTAL.sp_update_configuration`
- `PORTAL.sp_update_profile_domain`
- `PORTAL.sp_update_section_access`
- `PORTAL.sp_update_subscription`
- `PORTAL.sp_update_tenant`
- `PORTAL.sp_update_user`
- `PORTAL.sp_update_user_notification_setting`
- `PORTAL.sp_log_stats_execution`

## Dove e' documentato (Wiki)
- Overview schema/tabelle: `easyway-webapp/01_database_architecture/portal.md`
- Overview SP: `easyway-webapp/01_database_architecture/storeprocess.md`
- SP per area: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/index.md`
- Logging: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md`

## Rigenerazione (idempotente)
- `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki`


