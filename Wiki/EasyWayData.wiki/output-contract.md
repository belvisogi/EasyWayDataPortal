---
title: Output Contract (JSON)
summary: Struttura standard degli output degli agenti EasyWay, comune a tutti i domini. Chiavi e significato per LLM e umani.
tags: [agents, contracts, domain/docs, layer/reference, audience/dev, privacy/internal, language/it]
id: ew-output-contract
status: active
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# Output Contract (JSON)
Breadcrumb: Home / Metodo Agent‑First / Output Contract
Badge: WhatIf‑Ready ✅

Scopo
- Definire una struttura minima, consistente e parsabile per gli output degli agenti (per LLM e persone).

Struttura base (comune)
- action (string) — nome azione es. `db-user:create`, `dlk-ensure-structure`
- ok (bool) — esito logico dell’azione/valutazione
- whatIf (bool) — true se pre‑check/anteprima a secco
- nonInteractive (bool) — true se eseguito senza prompt
- correlationId (string|null) — ID correlazione
- startedAt / finishedAt (ISO 8601)
- output (object) — payload dominio‑specifico (vedi sotto)
- error (string|null) — messaggio d’errore sintetico, se presente
- contractId (string) — id dello standard di output (es. `action-result`)
- contractVersion (string) — versione (es. `1.0`)

Domini: chiavi output principali
- DBA (db-user:create/rotate/revoke)
  - server, database, username, auth (`sql|aad`)
  - roles[] (create), executed, keyVaultSet
  - passwordMasked, tsqlPreview
  - stateBefore/stateAfter (bools: readerExists, writerExists, userExists, memberReader, memberWriter)
  - preCheck (WhatIf): risultato `scripts/db-verify-connect.ps1`
- Datalake ensure‑structure
  - filesystem, tenantId, expectedPaths[], changesPreview[] (es. `{ type: "create-path", path: "landing/tenant01/" }`)
- Datalake apply‑acl
  - path, proposedAcl[], diff[] (es. `{ path, current, proposed, principal }`)
- Datalake set‑retention
  - policies[] (es. `{ path, days, change }`)

Schema (JSON Schema)
- Base: `agents/core/schemas/action-result.schema.json`
- Nota: gli attributi specifici di dominio non sono vincolati rigidamente (permette evoluzione), ma le chiavi comuni sono stabili.

Validazione (rapida)
- Script PS: `scripts/validate-action-output.ps1 -InputJson (cat out.json)`
- Restituisce JSON con `ok=true|false`, elenco `missing` e `schema`.

Linee guida
- Output conciso, senza testo superfluo. Preferire enum semplici e booleani.
- In WhatIf, non mutare lo stato: usare `changesPreview`/`diff`/`policies` come anteprima.
- In esecuzione reale, valorizzare `executed=true` e `stateAfter` quando applicabile.

Riferimenti
- `agent-first-method.md`
- `intent-contract.md`
- Pagine dominio (DBA, Datalake) e relative ricette KB (con `example_output`).







