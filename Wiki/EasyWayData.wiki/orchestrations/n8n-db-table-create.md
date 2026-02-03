---
id: ew-n8n-db-table-create
title: n8n-db-table-create
summary: Orchestrazione n8n per creare una tabella (WHAT-first): generare migrazione SQL + pagina Wiki tabella via agent_dba, con gates e approvazioni per apply.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, audience/dba, privacy/internal, language/it, n8n, db]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-18'
next: Modellare workflow in n8n (Webhook -> Validate -> Gate precheck -> Generate artifacts -> (optional) Apply -> Log).
---

[[../start-here.md|Home]] > [[../control-plane/index.md|Control-Plane]] > Orchestration

# n8n-db-table-create

## Contesto

**Source-of-truth DB (DDL)**: Migrazioni SQL in `db/migrations/`.

**Approccio**: Git + SQL diretto (senza Flyway). Vedi [why-not-flyway.md](../easyway-webapp/01_database_architecture/why-not-flyway.md) per motivazioni.

**Input strutturato**: Intent `db.table.create` (WHAT) oppure sheet Excel/CSV convertito in intent (vedi blueprint).

## Scopo

Creare una nuova tabella DB in modo deterministico e agentico:
- Input strutturato (intent `db.table.create`)
- Generazione artefatti (migrazione SQL + pagina Wiki tabella)
- Apply su DB solo con gates/approvazioni (opzionale)

## Domande a cui risponde

- Come chiedo a n8n di creare una nuova tabella in modo governato?
- Dove finiscono gli artefatti (migrations/Wiki) e qual è la source-of-truth?
- Quali parti sono automatiche e quali restano manuali (ERwin/data model)?

## Retrieval bundle
- Bundle: `n8n.db.table.create` (vedi `docs/agentic/templates/docs/retrieval-bundles.json`)

## Intent (WHAT)
- Schema: `docs/agentic/templates/intents/db.table.create.intent.json`
- Esempio intent agent: `agents/agent_dba/templates/intent.db-table-create.sample.json`
 - Blueprint sheet (Excel/CSV -> intent): `Wiki/EasyWayData.wiki/blueprints/db-table-create-sheet.md`

## Esecuzione (CLI, senza n8n)
- Genera artefatti (WhatIf):
  - `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath agents/agent_dba/templates/intent.db-table-create.sample.json -WhatIf -NonInteractive`
- Genera artefatti (scrive file):
  - `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath agents/agent_dba/templates/intent.db-table-create.sample.json -NonInteractive`

## Variante "Excel-friendly" (CSV)
Se l'utente compila un foglio (Excel/CSV), convertilo in intent e poi esegui l'agent:
- Template: `docs/agentic/templates/sheets/`
- Conversione: `pwsh scripts/db-table-intent-from-sheet.ps1 -TableCsv <table.csv> -ColumnsCsv <columns.csv> -IndexesCsv <indexes.csv> -OutIntent out/intents/intent.db-table-create.generated.json`


## Output atteso

- Migrazione: `db/migrations/Vxx__create_<schema>_<table>.sql`
- Pagina Wiki tabella: `Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/01b_schema_structure/<SCHEMA>/tables/<schema>-<table>.md`
- Artifact JSON: `db-table-create*.json` (machine-readable)

**Nota**: Il numero versione (Vxx) viene assegnato sequenzialmente in base all'ultima migrazione esistente.




