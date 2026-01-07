---
id: ew-db-table-portal-tenant
title: db-table-portal-tenant
summary: Anagrafica tenant (identità, stato e metadati di onboarding).
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, audience/non-expert, privacy/internal, language/it, multi-tenant]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Compilare colonne e policy (RLS, PII) e link alle SP di onboarding tenant.
---

# PORTAL.TENANT — Tenant

## Contesto
- Source-of-truth DB: `db/flyway/sql/`.
- Onboarding: tenant viene creato/aggiornato via stored procedure (vedi sezione programmability).

## Scopo
- TODO: descrivere i campi minimi del tenant e come viene usato come boundary multi-tenant.

