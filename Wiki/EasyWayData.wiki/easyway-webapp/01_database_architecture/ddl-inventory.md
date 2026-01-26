---
id: ew-db-ddl-inventory
title: DB PORTAL - Inventario DDL (canonico)
summary: Inventario DB (canonico) estratto dalle migrazioni SQL in db/migrations/ (source-of-truth) per mantenere allineata la Wiki.
status: active
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-18'
next: Automatizzare rigenerazione inventario da db/migrations/ con tool AI-friendly (db/db-deploy-ai/).
---

[Home](../../../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/db|db]] > [[Layer - Reference|Reference]]

# DB PORTAL - Inventario DDL (canonico)

## Obiettivo
- Rendere esplicito l'elenco di tabelle e stored procedure usando **solo** le fonti canoniche del repo.
- Ridurre ambiguità: un agente (o un umano) può verificare rapidamente cosa esiste e dove è documentato.

## Domande a cui risponde
- Quali tabelle/procedure esistono nello schema `PORTAL` secondo le fonti canoniche?
- Quali file sono la fonte e come posso rigenerare questo inventario?

## Source of Truth (Repo)

**Canonico**: Migrazioni SQL in `db/migrations/`

**Approccio**: Git + SQL diretto (senza Flyway)

**Perché NON Flyway**: Dopo valutazione, Flyway è stato dismesso per questo progetto. Vedi [why-not-flyway.md](./why-not-flyway.md) per dettagli.

**Applicazione**: Deploy operativo tramite sqlcmd, Azure Portal Query Editor, o SSMS. Vedi [db-migrations.md](./db-migrations.md) per guida completa.

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

```powershell
# Rigenera inventario da db/migrations/ (canonico)
pwsh scripts/db-ddl-inventory.ps1 -WriteWiki

# Include provisioning (dev/local)
pwsh scripts/db-ddl-inventory.ps1 -IncludeProvisioning -WriteWiki

# Include snapshot DDL (legacy, solo audit)
pwsh scripts/db-ddl-inventory.ps1 -IncludeSnapshot -WriteWiki

# Include legacy export (archivio storico)
pwsh scripts/db-ddl-inventory.ps1 -IncludeLegacy -WriteWiki
```sql

**Nota**: Lo script è stato aggiornato per leggere da `db/migrations/` invece di `db/flyway/`.

## Riferimenti

- [db-migrations.md](./db-migrations.md) - Guida gestione migrazioni (Git + SQL diretto)
- [why-not-flyway.md](./why-not-flyway.md) - Perché NON usiamo Flyway
- [portal.md](./portal.md) - Overview schema PORTAL
- [db/README.md](file:///c:/old/EasyWayDataPortal/db/README.md) - README database



