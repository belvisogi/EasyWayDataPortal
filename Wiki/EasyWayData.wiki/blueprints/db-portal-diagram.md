---
id: ew-blueprint-db-portal-diagram
title: Blueprint - DB PORTAL Diagram (internal viewer)
summary: Modello di diagramma (JSON) derivato da Flyway + viewer statico interno per visualizzare tabelle/relazioni senza tool esterni.
status: draft
owner: team-platform
tags: [domain/db, layer/blueprint, audience/non-expert, audience/dev, audience/dba, privacy/internal, language/it, diagram, viewer, agentic]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Estendere le relazioni esplicite (FK) quando presenti e migliorare le euristiche di inferenza.
type: guide
---

[Home](./start-here.md) > [[domains/db|db]] > [[Layer - Blueprint|Blueprint]]

# Blueprint - DB PORTAL Diagram (internal viewer)

## Contesto
- Source-of-truth DB: migrazioni Flyway in `db/flyway/sql/`.
- Il blueprint CSV è derivabile e già disponibile (`scripts/db-export-portal-blueprint-csv.ps1`).
- Obiettivo: avere un visualizzatore interno "tipo dbdiagram" per non esperti, senza dipendenze esterne o SaaS.

## Cosa abbiamo implementato (MVP)
- Script che genera un modello di diagramma machine-readable: `scripts/db-export-portal-diagram.ps1`
  - Output runtime: `out/db/portal-diagram.json`
  - Include: tabelle, colonne (nome/tipo/null), relazioni
  - Relazioni:
    - `kind=explicit`: FK fisiche presenti nel DDL (quando esistono)
    - `kind=inferred`: relazioni da convenzione (es. `tenant_id` -> `PORTAL.TENANT.tenant_id`)
- Pubblicazione enterprise (API):
  - Artefatto runtime (versionabile nel deploy): `portal-api/easyway-portal-api/data/db/portal-diagram.json`
  - Endpoint protetto (JWT): `GET /api/db/diagram?schema=PORTAL`
  - Viewer “prodotto” nel portale: `GET /portal/tools/db-diagram`
- Viewer statico interno: `portal-api/easyway-portal-frontend/static/db-diagram-viewer.html`
  - Può caricare un JSON locale (file input) o un mock.

## Uso (local workflow)
1. Genera il JSON diagramma:
   - (Repo root) `pwsh scripts/db-export-portal-diagram.ps1 -FlywaySqlDir db/flyway/sql -Schema PORTAL -OutJson out/db/portal-diagram.json`
2. Pubblica l'artefatto enterprise (API runtime):
   - `cd portal-api/easyway-portal-api`
   - `npm run db:diagram:refresh`
3. Avvia l'API e usa il viewer "prodotto":
   - `npm run dev`
   - Apri `http://localhost:3000/portal/tools/db-diagram`

## Note di governance (evitare ambiguità)
- Il viewer è una vista derivata: la fonte unica resta Flyway.
- Le relazioni `inferred` vanno considerate "ipotesi": sono utili per orientare, non sostituiscono vincoli DB.
- Se/Quando aggiungiamo FK fisiche nelle migrazioni, il viewer le mostrerà come `explicit`.


## Vedi anche

- [Blueprint - DB PORTAL Tables (previste)](./db-portal-tables.md)
- [Blueprint - DB Table Create (Excel/CSV -> Intent)](./db-table-create-sheet.md)
- [db-portal-tables-index](../easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/tables/index.md)
- [DB Generate Docs (WHAT)](../orchestrations/db-generate-docs.md)
- [db-table-portal-log-audit](../easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/tables/portal-log-audit.md)




