---
id: ew-db-table-portal-configuration
title: db-table-portal-configuration
summary: Configurazioni applicative per tenant/feature (valori e chiavi configurazione).
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, audience/non-expert, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Compilare data dictionary (colonne, PII, tenanting) e link alle SP CRUD.
---

# PORTAL.CONFIGURATION — Configuration

## Contesto
- Source-of-truth DB: `db/flyway/sql/` (vedi inventario `easyway-webapp/01_database_architecture/ddl-inventory.md`).
- Doc logica (questa pagina): descrizioni e policy.

## Scopo
- TODO: descrivere chi legge/scrive configurazioni, chiavi principali e granularità (tenant/section/key).

## Domande a cui risponde
- Quali configurazioni esistono e come sono versionate/attivate?
- Quali campi contengono dati sensibili (PII) o segreti (da evitare)?

