---
id: ew-db-studio
title: EasyWay DB Studio – ERD & SP Catalog
summary: Generazione automatica di documentazione DB (ERD Mermaid + Catalogo SP)
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: [email]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

Obiettivo
- Generare documentazione aggiornata dal DB (schema attuale) in pochi secondi, pronta per wiki e agenti.

Output
- `out/db-docs/ERD.md` – ER diagram (Mermaid) generato automaticamente
- `out/db-docs/SP_CATALOG.md` – Catalogo Stored Procedure e parametri

Come si esegue
```sql
cd EasyWay-DataPortal/easyway-portal-api
npm run db:generate-docs
```sql
Env richieste (come per API): `DB_CONN_STRING` (o `DB_AAD=true` con `DB_HOST/DB_NAME`).

Pipeline
- Può essere invocato in uno stage dedicato (DB-Docs) per aggiornare la documentazione.

Note
- Gli script leggono INFORMATION_SCHEMA/sys.* e producono output idempotente.
- Estensioni future: relazioni by columns, extended properties come descrizioni.






