---
id: ew-db-table-portal-users
title: db-table-portal-users
summary: Anagrafica utenti (identità, profilo, stato) in contesto multi-tenant.
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
next: Compilare colonne (PII), policy RLS e link alle SP CRUD utenti.
---

[[start-here|Home]] > [[domains/db|db]] > [[Layer - Reference|Reference]]

# PORTAL.USERS — Users

## Contesto
- Source-of-truth DB: `db/flyway/sql/`.
- Operazioni DML: via stored procedure (audit/logging), non via DML diretto da API.

## Scopo
- TODO: descrivere come sono modellati utenti, profili/ruoli e relazione col tenant.


