---
id: ew-n8n-retrieval-bundles
title: n8n Retrieval Bundles (riduzione token)
summary: Mappa machine-readable bundle→scope per far caricare a n8n solo la doc necessaria a un intent, riducendo token e ambiguità.
status: active
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, privacy/internal, language/it, n8n, retrieval, retrieval-bundles]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-18'
next: TODO - definire next step.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Orchestration|Orchestration]]

# n8n Retrieval Bundles

Obiettivo: dare a n8n (o ad altri agenti) un modo **deterministico** per decidere *quali pagine Wiki caricare* per un intent, senza "rileggere tutto" e senza includere duplicati/obsolete.

## Domande a cui risponde
- Qual è la source of truth dei bundle (file) e qual è il suo formato?
- Come n8n risolve `intent`/`bundle_id` e quali `scopes[]` deve caricare?
- Quali directory/file vengono esclusi di default (attachments/logs/old/backup) per ridurre token?
- Come mantenere gli scope `*-all` nel tempo quando la Wiki cresce o cambia struttura?
- Come evitare ambiguità dovute a pagine duplicate (status deprecated, canonical, `llm.include: false`)?
- Come verifico che un intent sia coperto da un bundle (e cosa fare se manca)?

## Source of truth (machine-readable)

- `docs/agentic/templates/docs/retrieval-bundles.json`
- Scope list: `docs/agentic/templates/docs/tag-taxonomy.scopes.json`

## Bundle per Codex (sviluppo codice)

Quando GPT-5.2 Codex deve implementare sotto `portal-api/`, usa il bundle:
- `codex.dev.core`  contesto minimo (governance + portal + security) + entrypoints del codice.

## Bundle DB (n8n)

Quando n8n deve fare operazioni sul DB (es. rigenerare inventario DDL e aggiornare la Wiki DB), usa:
- `n8n.db.core` → contesto DB (Wiki) + root tecnico `db/migrations/` (source-of-truth canonico dei DDL).

Per la creazione di nuove tabelle (artefatti migrazioni SQL + pagina Wiki tabella), usa:
- `n8n.db.table.create`

Nota: di default i bundle servono a caricare **Wiki**; `old/db/` e `db/README.md` sono solo per audit/compat (non doc canonica).

## Regole operative

1. n8n risolve `intent` → `bundle_id` (o riceve direttamente `bundle_id`).
2. Legge `retrieval-bundles.json` e ottiene `scopes[]`.
3. Per ogni scope, recupera la lista file da `tag-taxonomy.scopes.json`.
4. Applica `default_exclude_globs` (attachments/logs/old/backup).
5. Carica solo quelle pagine nel contesto del workflow.

## Nota sugli scope (*-20 vs *-all)

- `*-20`: blocchi da 20 pagine per **adozione a fasi** (CI/gates).
- `*-all`: scope **stabili per retrieval** (es. n8n) basati su directory/prefix; vanno mantenuti nel tempo.

## Anti-duplicati (zero ambiguità)

- Pagine "shim/redirect compat" devono avere `status: deprecated` e idealmente `llm.include: false` per non essere caricate dagli agenti.
- La pagina canonica resta l'unica fonte: le altre rimandano (con `canonical:` o `redirect_to:`).



## Vedi anche

- [n8n-db-ddl-inventory](./n8n-db-ddl-inventory.md)
- [n8n-db-table-create](./n8n-db-table-create.md)
- [Orchestratore n8n (WHAT)](./orchestrator-n8n.md)
- [n8n API Error Triage](./n8n-api-error-triage.md)
- [Agents Registry (owner, domini, intent)](../control-plane/agents-registry.md)


