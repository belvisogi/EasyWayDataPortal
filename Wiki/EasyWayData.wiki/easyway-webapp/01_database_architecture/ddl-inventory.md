---
id: ew-db-ddl-inventory
title: DB PORTAL - Inventario DDL (canonico)
summary: Inventario DB (canonico) estratto da DDL_EASYWAY + provisioning per mantenere allineata la Wiki 01_database_architecture.
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
next: Rendere Flyway (`db/flyway/`) la fonte incrementale e rigenerare periodicamente il DDL canonico (snapshot) se necessario; mantenere i legacy export fuori dal retrieval.
---

# DB PORTAL - Inventario DDL (canonico)

## Obiettivo
- Rendere esplicito l'elenco di tabelle e stored procedure usando **solo** le fonti canoniche del repo.
- Ridurre ambiguità: un agente (o un umano) può verificare rapidamente cosa esiste e dove è documentato.

## Domande a cui risponde
- Quali tabelle/procedure esistono nello schema PORTAL secondo le fonti canoniche?
- Quali file sono la fonte e come posso rigenerare questo inventario?

## Source of truth (repo)
- DDL canonico: `DataBase/DDL_EASYWAY_DATAPORTAL.sql`

Deploy operativa: usare migrazioni Flyway in `db/flyway/` (apply controllato). Il DDL canonico resta la fonte primaria.

## Tabelle (PORTAL) - canonico
_Nessuna tabella elencata (eseguire rigenerazione inventory per aggiornare)._

## Stored procedure (PORTAL) - canonico
_Nessuna stored procedure elencata (eseguire rigenerazione inventory per aggiornare)._

<!--
## Sezione legacy
I file DDL_PORTAL_* sono mantenuti solo come export storici/audit e non più utilizzati come fonte officiale per l'inventario.
-->

## Dove è documentato (Wiki)
- Overview schema/tabelle: `easyway-webapp/01_database_architecture/portal.md`
- Overview SP: `easyway-webapp/01_database_architecture/storeprocess.md`
- SP per area: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/index.md`
- Logging: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md`

## Rigenerazione (idempotente)
- Solo canonico: `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki`
