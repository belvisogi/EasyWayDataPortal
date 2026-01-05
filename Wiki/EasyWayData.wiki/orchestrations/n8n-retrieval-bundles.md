---
id: ew-n8n-retrieval-bundles
title: n8n Retrieval Bundles (riduzione token)
summary: Mappa machine-readable bundle→scope per far caricare a n8n solo la doc necessaria a un intent, riducendo token e ambiguità.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, privacy/internal, language/it, n8n, retrieval, retrieval-bundles]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# n8n Retrieval Bundles

Obiettivo: dare a n8n (o ad altri agenti) un modo **deterministico** per decidere *quali pagine Wiki caricare* per un intent, senza “rileggere tutto” e senza includere duplicati/obsolete.

## Source of truth (machine-readable)

- `docs/agentic/templates/docs/retrieval-bundles.json`
- Scope list: `docs/agentic/templates/docs/tag-taxonomy.scopes.json`

## Regole operative

1. n8n risolve `intent` → `bundle_id` (o riceve direttamente `bundle_id`).
2. Legge `retrieval-bundles.json` e ottiene `scopes[]`.
3. Per ogni scope, recupera la lista file da `tag-taxonomy.scopes.json`.
4. Applica `default_exclude_globs` (attachments/logs/old/backup).
5. Carica solo quelle pagine nel contesto del workflow.

## Anti-duplicati (zero ambiguità)

- Pagine “shim/redirect compat” devono avere `status: deprecated` e idealmente `llm.include: false` per non essere caricate dagli agenti.
- La pagina canonica resta l’unica fonte: le altre rimandano (con `canonical:` o `redirect_to:`).

