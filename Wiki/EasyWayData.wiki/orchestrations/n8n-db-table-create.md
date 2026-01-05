---
id: ew-n8n-db-table-create
title: n8n-db-table-create
summary: Orchestrazione n8n per creare una tabella (WHAT-first): generare migrazione Flyway + pagina Wiki tabella via agent_dba, con gates e approvazioni per apply.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, audience/dba, privacy/internal, language/it, n8n, db]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: Modellare workflow in n8n (Webhook -> Validate -> Gate precheck -> Generate artifacts -> (optional) Apply -> Log).
---

# n8n-db-table-create

## Scopo
Creare una nuova tabella DB in modo deterministico e agentico:
- input strutturato (intent `db.table.create`)
- generazione artefatti (migrazione Flyway + pagina Wiki tabella)
- apply su DB solo con gates/approvazioni (opzionale)

## Domande a cui risponde
- Come chiedo a n8n di creare una nuova tabella in modo governato?
- Dove finiscono gli artefatti (Flyway/Wiki) e qual e' la source-of-truth?
- Quali parti sono automatiche e quali restano manuali (ERwin/data model)?

## Retrieval bundle
- Bundle: `n8n.db.table.create` (vedi `docs/agentic/templates/docs/retrieval-bundles.json`)

## Intent (WHAT)
- Schema: `docs/agentic/templates/intents/db.table.create.intent.json`
- Esempio intent agent: `agents/agent_dba/templates/intent.db-table-create.sample.json`

## Esecuzione (CLI, senza n8n)
- Genera artefatti (WhatIf):
  - `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath agents/agent_dba/templates/intent.db-table-create.sample.json -WhatIf -NonInteractive`
- Genera artefatti (scrive file):
  - `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath agents/agent_dba/templates/intent.db-table-create.sample.json -NonInteractive`

## Output atteso
- Migrazione: `db/flyway/VYYYYMMDDHHMMSS__create_<schema>_<table>.sql`
- Pagina Wiki tabella: `Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/01b_schema_structure/<SCHEMA>/tables/<schema>-<table>.md`
- Artifact JSON: `db-table-create*.json` (machine-readable)
