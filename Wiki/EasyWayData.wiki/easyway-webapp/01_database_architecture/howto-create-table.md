---
id: ew-db-howto-create-table
title: db-howto-create-table
summary: Procedura per creare una nuova tabella in modo agentico (spec -> DDL/migrazione -> doc Wiki), senza duplicare la source-of-truth.
status: draft
owner: team-data
tags: [domain/db, layer/howto, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: Definire policy su snapshot DDL in DataBase/ e su integrazione ERwin.
---

# HowTo: creare una tabella

## Regola base (razionalizzazione)
- Source-of-truth tecnica: migrazioni in `db/flyway/` (deploy controllato).
- Source-of-truth documentale: Wiki sotto `easyway-webapp/01_database_architecture/`.
- `DataBase/` resta un riferimento/snapshot se e solo se la policy lo richiede (evitare duplicazioni non governate).

## Passi (WHAT-first)
1. Compila un intent WHAT `db.table.create` (schema, table, columns, indici, privacy/PII, tenanting).
2. Esegui in WhatIf per vedere cosa verrebbe generato.
3. Genera artefatti (Flyway + pagina Wiki tabella).
4. (Opzionale) Apply su DB solo con gates verdi e approvazione.
5. Aggiorna/rigenera inventario DDL (`ddl-inventory.md`) se la policy di inventory lo richiede.

## Comandi
- Esempio intent: `agents/agent_dba/templates/intent.db-table-create.sample.json`
- Generazione (WhatIf):
  - `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath agents/agent_dba/templates/intent.db-table-create.sample.json -WhatIf -NonInteractive`
- Generazione (scrive file):
  - `pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath agents/agent_dba/templates/intent.db-table-create.sample.json -NonInteractive`

## Domande a cui risponde
- Qual e' la pipeline corretta per aggiungere una tabella senza ambiguita?
- Dove finiscono i file (Flyway, Wiki) e cosa e' canonico?
- Come gestire PII/tenanting/RLS in modo governato?
