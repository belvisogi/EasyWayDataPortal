---
id: ew-blueprint-db-portal-tables
title: Blueprint - DB PORTAL Tables (previste)
summary: Blueprint delle tabelle attualmente previste nello schema PORTAL (fisico da Flyway) e dove si trovano le pagine canoniche di data dictionary.
status: draft
owner: team-platform
tags: [domain/db, layer/blueprint, audience/non-expert, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Popolare logical_name/descrizioni colonne e collegare SP/endpoint per ogni tabella.
---

# Blueprint - DB PORTAL Tables (previste)

## Contesto
- Source-of-truth DB (fisico): `db/flyway/sql/` (Flyway).
- Inventario derivato (rigenerabile): `easyway-webapp/01_database_architecture/ddl-inventory.md`.
- Data dictionary (vista logica): pagine tabella sotto `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/tables/`.

## Dove leggere il blueprint (Wiki)
- Indice tabelle PORTAL: `easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/tables/index.md`

## Export CSV (Excel-friendly)
Per estrarre un CSV compilabile (tables/columns/indexes) derivato da Flyway:
- `pwsh scripts/db-export-portal-blueprint-csv.ps1 -FlywaySqlDir db/flyway/sql -OutDir out/db -Schema PORTAL`

Output:
- `out/db/portal-blueprint.tables.csv`
- `out/db/portal-blueprint.columns.csv`
- `out/db/portal-blueprint.indexes.csv`

## Diagramma ER (visualizzatore interno)
Contesto: abbiamo già un blueprint derivabile da Flyway, quindi possiamo generare un JSON di diagramma e visualizzarlo internamente (senza dipendenze esterne).
- Generazione modello diagramma: `pwsh scripts/db-export-portal-diagram.ps1 -FlywaySqlDir db/flyway/sql -Schema PORTAL -OutJson out/db/portal-diagram.json`
- Viewer (prototype statico): `EasyWay-DataPortal/easyway-portal-frontend/static/db-diagram-viewer.html` (carica `out/db/portal-diagram.json`)
- Specifica/uso: `blueprints/db-portal-diagram.md`

## Come mantenerlo allineato
- Se cambiano le migrazioni Flyway, rigenera l'inventario: `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki -SummaryOut out/db/db-ddl-inventory.json`
- Per nuove tabelle usa il workflow sheet->intent->agent: `blueprints/db-table-create-sheet.md`
