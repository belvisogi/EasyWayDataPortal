---
id: ew-easyway-webapp-01-database-architecture-index
title: database-architecture-index
tags: [domain/db, layer/index, audience/dev, audience/dba, privacy/internal, language/it, database-architecture]
owner: team-platform
summary: Indice della documentazione DB (setup, struttura schema, inventario DDL).
status: active
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: Aggiornare quando cambiano DDL o struttura.
---

# Indice

- Nota per autori: per nuove pagine usare `./_template.md`.


Breadcrumb: Home / EasyWay WebApp / Database Architecture

## Contesto
- Source-of-truth DB (canonico): migrazioni Flyway in `db/flyway/sql/`.
- Provisioning dev/local: wrapper `db/provisioning/apply-flyway.ps1` (human-in-the-loop).
- Artefatti storici (non canonici): `old/db/` (ex `DataBase/` e export `DDL_PORTAL_*`).

- [01a-db-setup.md](./01a-db-setup.md) - Setup DB (prerequisiti, ruoli, connessioni).
- [01b-schema-structure.md](./01b-schema-structure.md) - Struttura schema e naming.
- [ddl-inventory.md](./ddl-inventory.md) - Inventario tabelle/SP (rigenerato da Flyway: `db/flyway/sql/`).
- [howto-create-table.md](./howto-create-table.md) - HowTo: creare una tabella (agentico, WHAT-first).

## Domande a cui risponde
- Quali documenti devo leggere per installare e configurare il DB?
- Dove trovo la struttura degli schemi e le regole di naming?
- Qual è la lista “source-of-truth” di tabelle e stored procedure (da DDL)?
- Quali sono i link canonici da usare nelle altre pagine DB?

