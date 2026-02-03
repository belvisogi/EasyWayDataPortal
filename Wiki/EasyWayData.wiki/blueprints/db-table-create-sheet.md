---
id: ew-blueprint-db-table-create-sheet
title: Blueprint - DB Table Create (Excel/CSV -> Intent)
summary: Specifica dei campi/flag del template Excel/CSV per creare tabelle (mappatura deterministica verso l'intent db.table.create usato da agent_dba).
status: draft
owner: team-platform
tags: [domain/db, layer/blueprint, audience/non-expert, audience/dev, audience/dba, privacy/internal, language/it, excel, csv, agentic]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Stabilizzare convenzioni (tenanting/RLS/PII) e aggiungere validazioni (lint) sui CSV.
---

[Home](./start-here.md) > [[domains/db|db]] > [[Layer - Blueprint|Blueprint]]

# Blueprint - DB Table Create (Excel/CSV -> Intent)

## Contesto
- Standard agentico: i flag `include_audit/include_soft_delete` generano colonne fisiche standard e (opz.) una migrazione Flyway dedicata per le descrizioni (`MS_Description`/`Description`) derivata dal Data Dictionary (logical_name/description).
- Source-of-truth DB (DDL): migrazioni Flyway in `db/flyway/sql/`.
- L'input "facile" per non esperti è un foglio Excel (CSV) compilabile.
- L'agente trasforma il CSV in un intent `db-table:create` e genera artefatti (Flyway + Wiki); l'apply su DB è uno step separato (human-in-the-loop).

## Source of truth (template)
- Template CSV (apribili in Excel): `docs/agentic/templates/sheets/`
  - `docs/agentic/templates/sheets/db-table-create.table.csv`
  - `docs/agentic/templates/sheets/db-table-create.columns.csv`
  - `docs/agentic/templates/sheets/db-table-create.indexes.csv`
- Converter: `scripts/db-table-intent-from-sheet.ps1`
- Intent schema (WHAT): `docs/agentic/templates/intents/db.table.create.intent.json`

## Flusso operativo (deterministico)
1. Compila i CSV (Excel-friendly).
2. Genera intent JSON: `pwsh scripts/db-table-intent-from-sheet.ps1 ...`
3. Lint semantico (naming/tipi/PII/RLS): `pwsh scripts/db-table-lint.ps1 -IntentPath out/intents/intent.db-table-create.generated.json -OutJson out/db/db-table-lint.json`
4. WhatIf: `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath out/intents/intent.db-table-create.generated.json -WhatIf -NonInteractive`
5. Write: `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath out/intents/intent.db-table-create.generated.json -NonInteractive`
6. (Opzionale) Apply: `pwsh db/provisioning/apply-flyway.ps1 -Action migrate` (con conferma).

## Filesystem locale (contratto)
- Input: i CSV possono stare ovunque (es. download/desktop), ma per standard si consiglia una cartella di lavoro locale (es. `in/` o una cartella progetto dedicata).
- Output runtime: usare `out/` per intent generati, summary JSON e runlog.
  - `out/` e' ignorata da git (salvo `out/README.md`) e quindi e' sicura per artefatti temporanei.
- Output canonico (versionato): solo in `db/flyway/sql/` e `Wiki/EasyWayData.wiki/` (creati quando esegui lo step "Write").

## (Opzionale) Upload artifact su Datalake/Blob
Se vuoi pubblicare i soli artifact runtime (lint/summary/intent) fuori da git, puoi caricare `out/` su Storage:
- Script: `scripts/out-upload-datalake.ps1`
- Esempio (WhatIf): `pwsh scripts/out-upload-datalake.ps1 -StorageAccount <name> -Container <container> -Prefix "<env>/<tenant>/<correlationId>" -WhatIf`

## File 1: `db-table-create.table.csv` (1 riga)
Colonne:
- `schema`: schema target (es. `PORTAL`).
- `table`: nome tabella (snake_case consigliato).
- `logical_name`: nome logico/business della tabella (human-friendly).
- `description`: 1-3 frasi di scopo (finisce nella pagina Wiki, se `writeWiki=true`).
- `owner`: owner della documentazione (es. `team-data`).
- `domain`: dominio funzionale (es. onboarding/config/security) per classificare la tabella.
- `classification`: classificazione (es. public/internal/confidential).
- `tags`: tag (separati da `;` o `,`) per la pagina Wiki.
- `tenant_column`: nome colonna tenant (es. `tenant_id`) se multi-tenant.
- `rls_required`: `true/false` (se prevedi RLS per questa tabella).
- `include_audit`: `true/false` (flag per aggiungere colonne audit standard).
- `include_soft_delete`: `true/false` (flag per aggiungere colonne soft delete standard).
- `writeWiki`: `true/false` (default `true`).
- `writeFlyway`: `true/false` (default `true`).
- `correlationId`: id correlazione (log/eventi/trace).
- `summaryOut`: path output JSON (artifact machine-readable).
  - Consigliato sotto `out/` (es. `out/db/db-table-create.<schema>.<table>.json`).

## File 2: `db-table-create.columns.csv` (N righe)
Ogni riga = 1 colonna della tabella.
Nota: se `include_audit=true` / `include_soft_delete=true`, non serve inserire le colonne standard nei CSV: l'agente le genera coerenti (ed eventualmente valida che non ci siano override inconsistenti).
Colonne:
- `name`: nome colonna.
- `logical_name`: nome logico/business della colonna (human-friendly).
- `description`: descrizione umana (finisce in Wiki e nelle extended properties, se abilitate).
- `sql_type`: tipo SQL (fisico) (es. `int`, `nvarchar(200)`, `datetime2(3)`).
- `nullable`: `true/false`.
- `default`: default SQL (es. `sysutcdatetime()`), opzionale.
- `pk`: `true/false` (se fa parte della primary key).
- `identity`: `true/false` (IDENTITY), opzionale.
- `pii`: `none|low|high`.
- `classification`: classificazione (es. public/internal/confidential).
- `masking`: livello masking (es. none/partial/full), se adottato.
- `example_value`: esempio valore (solo per doc; non deve contenere dati reali).
- `ref_schema`, `ref_table`, `ref_column`: FK (tutti e 3 richiesti se valorizzi una FK).

## File 3: `db-table-create.indexes.csv` (opzionale)
Ogni riga = 1 indice.
Colonne:
- `name`: nome indice (opzionale; se vuoto viene generato automaticamente).
- `columns`: lista colonne (separate da `;` o `,`).
- `unique`: `true/false`.

## Regole di compilazione (per evitare ambiguità)
- Compila sempre `schema`, `table`, almeno 1 riga in `columns.csv`.
- Se usi FK: compila sempre `ref_schema/ref_table/ref_column` tutti e tre.
- Usa `pii=high` per dati sensibili (email, telefono, codice fiscale) e valuta masking/RLS nel design.

## Colonne standard (generate automaticamente)
- `include_audit=true`:
  - `created_by nvarchar(255) NOT NULL DEFAULT ('MANUAL')`
  - `created_at datetime2 NOT NULL DEFAULT (SYSUTCDATETIME())`
  - `updated_at datetime2 NOT NULL DEFAULT (SYSUTCDATETIME())`
- `include_soft_delete=true`:
  - `is_deleted bit NOT NULL DEFAULT (0)`
  - `deleted_at datetime2 NULL`
  - `deleted_by nvarchar(255) NULL`

## Extended properties (opzionale, da Data Dictionary)
Se `writeFlyway=true` e sono presenti `logical_name`/`description` per tabella o colonne, l'agente genera una seconda migrazione Flyway dedicata per:
- `MS_Description` (standard SSMS)
- `Description` (compatibilità con artefatti esistenti in questo repo)


## Vedi anche

- [Blueprint - DB PORTAL Diagram (internal viewer)](./db-portal-diagram.md)
- [Blueprint - DB PORTAL Tables (previste)](./db-portal-tables.md)
- [db-howto-create-table](../easyway-webapp/01_database_architecture/howto-create-table.md)
- [db-portal-tables-index](../easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/tables/index.md)
- [Template Data Dictionary (DB Table) - Excel](./db-table-dictionary-template.md)




