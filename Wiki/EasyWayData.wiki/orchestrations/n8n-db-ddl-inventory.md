---
id: ew-n8n-db-ddl-inventory
title: n8n-db-ddl-inventory
summary: Orchestrazione n8n per rigenerare l'inventario DB da migrazioni SQL (`db/migrations/`) e aggiornare la pagina Wiki ddl-inventory (agent_dba).
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
next: Implementare workflow n8n e collegare webhook.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Orchestration|Orchestration]]

# n8n-db-ddl-inventory

## Contesto

**Source-of-truth DB (canonico)**: Migrazioni SQL in `db/migrations/`.

**Approccio**: Git + SQL diretto (senza Flyway). Vedi [why-not-flyway.md](../easyway-webapp/01_database_architecture/why-not-flyway.md) per motivazioni.

**Artefatti storici** (non canonici): `old/db/` (ex `DataBase/`, export `DDL_PORTAL_*`).

## Scopo

Workflow n8n che, a partire dalle migrazioni in `db/migrations/`, rigenera l'inventario DB e aggiorna la pagina canonica:
- `easyway-webapp/01_database_architecture/ddl-inventory.md`

## Domande a cui risponde
- Come rigenero l'elenco tabelle e stored procedure in modo deterministico?
- Qual è la fonte unica (DDL) e qual è la doc canonica (Wiki)?
- Qual è il comando da eseguire e che output machine-readable produce?

## Retrieval bundle
- Bundle: `n8n.db.core` (vedi `docs/agentic/templates/docs/retrieval-bundles.json`)

## Workflow (alto livello)
1. Webhook (trigger)
2. Validate input (schema intent `db.ddl-inventory`)
3. (Opzionale) Gate precheck (docs/CI policy)
4. Dispatch: esegui `agent_dba` action `db-doc:ddl-inventory`
5. Log: append evento + artifact (JSON inventory)

## Comandi (CLI)
Esecuzione diretta (senza n8n):
- `pwsh scripts/db-ddl-inventory.ps1 -WriteWiki -SummaryOut db-ddl-inventory.json`

Esecuzione via agent:
- `pwsh scripts/agent-dba.ps1 -Action db-doc:ddl-inventory -IntentPath agents/agent_dba/templates/intent.db-ddl-inventory.sample.json -NonInteractive`


## Vedi anche

- [n8n-db-table-create](./n8n-db-table-create.md)
- [n8n Retrieval Bundles (riduzione token)](./n8n-retrieval-bundles.md)
- [Orchestratore n8n (WHAT)](./orchestrator-n8n.md)
- [n8n API Error Triage](./n8n-api-error-triage.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)


