# Sheet templates (Excel-friendly)

Questi template sono CSV apribili in Excel e servono per compilare in modo semplice (flag standard) una richiesta di creazione tabella.

## File
- `db-table-create.table.csv`: metadati tabella (1 riga).
- `db-table-create.columns.csv`: elenco colonne (N righe).
- `db-table-create.indexes.csv`: indici (opzionale).
- `db-table-create.template.xlsx`: versione Excel con 3 fogli (Table/Columns/Indexes) + foglio Istruzioni.
- `access-registry.csv`: censimento accessi tecnici (audit, non segreti).
- `access-registry.template.xlsx`: versione Excel del censimento accessi + foglio Istruzioni.

## Campi logici consigliati (data dictionary)
I template includono campi "logici" (es. `logical_name`, `description`, `domain`, `classification`) che l'agente usa per:
- arricchire la pagina Wiki tabella/colonne;
- mantenere coerenza tra naming logico e fisico;
- (opz.) generare una migrazione Flyway dedicata per `MS_Description` / `Description` a partire dal Data Dictionary.

## Colonne standard (generate da flag)
Per evitare ridondanze nei CSV e mantenere lo standard coerente, alcune colonne vengono generate automaticamente:
- `include_audit=true` → `created_by`, `created_at`, `updated_at`
- `include_soft_delete=true` → `is_deleted`, `deleted_at`, `deleted_by`

## Conversione in intent JSON
Genera un intent compatibile con `agent_dba`:

```powershell
pwsh scripts/db-table-intent-from-sheet.ps1 `
  -TableCsv docs/agentic/templates/sheets/db-table-create.table.csv `
  -ColumnsCsv docs/agentic/templates/sheets/db-table-create.columns.csv `
  -IndexesCsv docs/agentic/templates/sheets/db-table-create.indexes.csv `
  -OutIntent out/intents/intent.db-table-create.generated.json
```

Poi:
- WhatIf: `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath out/intents/intent.db-table-create.generated.json -WhatIf -NonInteractive`
- Write: `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath out/intents/intent.db-table-create.generated.json -NonInteractive`

## Rigenerare il template Excel
```powershell
pwsh scripts/db-table-template-xlsx.ps1
```

## Rigenerare il template Access Registry
```powershell
pwsh scripts/access-registry-template-xlsx.ps1
```
