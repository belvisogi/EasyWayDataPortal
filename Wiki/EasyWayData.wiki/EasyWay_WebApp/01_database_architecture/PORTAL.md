---
id: ew-db-portal
title: Schema PORTAL – Struttura e convenzioni
summary: Tabelle core multi-tenant (tenant, users, configuration, audit, stats)
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
---

Obiettivo
- Definire struttura, regole e best practice per le tabelle core del portale.

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

