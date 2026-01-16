---
title: Template Data Dictionary (DB Table) - Excel
tags: [db, blueprint, data-dictionary, templates, agentic, language/it, privacy/internal]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-blueprint-db-table-dictionary-template
chunk_hint: 200-300
entities: []
include: true
summary: Template Excel per compilare in modo umano le specifiche di una nuova tabella DB e generare l'intent per agent_dba.
llm: 
pii: none
owner: team-platform
---

# Template Data Dictionary (DB Table) - Excel

## Contesto (repo)
- Obiettivo: rendere la richiesta tabella compilabile da umani e convertibile in intent `db.table.create`.
- Source of truth:
  - Template Excel: `docs/agentic/templates/sheets/db-table-create.template.xlsx`
  - CSV canonici: `docs/agentic/templates/sheets/db-table-create.table.csv`, `docs/agentic/templates/sheets/db-table-create.columns.csv`, `docs/agentic/templates/sheets/db-table-create.indexes.csv`
  - Generator intent: `scripts/db-table-intent-from-sheet.ps1`
  - Agent DBA: `scripts/agent-dba.ps1`
  - Goals agentici: `agents/goals.json`
  - KB: `agents/kb/recipes.jsonl`
  - Log eventi: `agents/logs/events.jsonl`
  - Entrypoint orchestrazione: `scripts/ewctl.ps1`

## Cosa contiene il template
Workbook con 4 fogli:
- `Table`: 1 riga con metadati tabella.
- `Columns`: N righe, una per colonna.
- `Indexes`: opzionale, indici.
- `Istruzioni`: guida rapida e path placeholder per Datalake.

## Come usarlo (happy path)
1. Compila `Table`, `Columns`, `Indexes` (se servono).
2. Esporta ogni foglio in CSV con gli stessi header.
3. Genera l'intent:
```powershell
pwsh scripts/db-table-intent-from-sheet.ps1 `
  -TableCsv <table.csv> `
  -ColumnsCsv <columns.csv> `
  -IndexesCsv <indexes.csv> `
  -OutIntent out/intents/intent.db-table-create.generated.json
```sql
4. Lancia l'agent:
```powershell
pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath out/intents/intent.db-table-create.generated.json -LogEvent
```sql

## Datalake (placeholder)
Usa questo path come placeholder fino alla definizione finale:
`abfss://<filesystem>@<storage>.dfs.core.windows.net/portal-assets/templates/db/`

## Come rigenerare (idempotente)
```powershell
pwsh scripts/db-table-template-xlsx.ps1
```sql

## Verify
- Il file Excel esiste e ha 4 fogli.
- L'intent generato e' valido e il lint DB passa.
- Eventi loggati in `agents/logs/events.jsonl` se `-LogEvent`.


## Vedi anche

- [Blueprint - DB Table Create (Excel/CSV -> Intent)](./db-table-create-sheet.md)
- [n8n-db-table-create](../orchestrations/n8n-db-table-create.md)
- [Esempi Notifiche & Template Email Configurabili](../easyway-webapp/02_logiche_easyway/notifiche-gestione/esempi-notifiche-and-template-email-configurabili.md)
- [Orchestrations – Intents Catalog (Use Case Excel/CSV)](../orchestrations/intents-catalog.md)
- [db-howto-create-table](../easyway-webapp/01_database_architecture/howto-create-table.md)


