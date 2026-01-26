---
id: ew-db-portal
title: Schema PORTAL – Struttura e convenzioni
summary: Tabelle core multi-tenant (tenant, users, configuration, audit, stats)
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

[Home](../../../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/db|db]] > [[Layer - Reference|Reference]]

Obiettivo
- Definire struttura, regole e best practice per le tabelle core del portale.

Source of truth (repo)
- DDL canonico (corrente): `db/flyway/sql/` (migrazioni incrementali)
- Bootstrap dev/local: `db/provisioning/apply-flyway.ps1` (wrapper; applica Flyway con conferma)
- Archivio storico: `old/db/` (non canonico)
- Inventario (Wiki): `easyway-webapp/01_database_architecture/ddl-inventory.md`

Colonne standard
- id (INT IDENTITY, PK), tenant_id (NVARCHAR(50), NOT NULL), created_by/created_at/updated_at (default), status (NVARCHAR(50)), ext_attributes (NVARCHAR(MAX)).

Tabelle principali
- TENANT: anagrafica clienti (tenant_id univoco, plan_code, estensioni JSON)
- USERS: utenti multi-tenant (user_id univoco per tenant, email univoca per tenant, ACL, is_active)
- CONFIGURATION: parametri runtime (univocità per tenant+section+key, enabled)
- LOG_AUDIT: eventi sistema/API/job (payload JSON)
- STATS_EXECUTION_LOG: log di esecuzione SP, righe affette, esito
- STATS_EXECUTION_TABLE_LOG: dettaglio per tabella (FK → execution_id)

Indice & performance
- Unicità: TENANT(tenant_id), USERS(tenant_id,user_id), USERS(tenant_id,email)
- Filtri tipici: (tenant_id), (status), (created_at)

Note
- RLS e funzioni predicate verranno aggiunte in una migrazione dedicata.








