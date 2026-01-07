---
title: Contratto Intent (Mini‑DSL)
summary: Schema JSON degli intent che gli agenti accettano. Esempi e campi comuni.
tags: [agents, governance, contracts, domain/docs, layer/reference, audience/dev, privacy/internal, language/it]
id: ew-intent-contract
status: draft
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

# Contratto Intent (Mini‑DSL)
Breadcrumb: Home / Metodo Agent‑First / Contratto Intent

Scopo
- Definire un formato minimo, leggibile da umani e agenti, per descrivere un’azione.

Campi comuni
- action (string) — nome azione es. `db-user:create`, `wiki:normalize`
- params (object) — parametri specifici azione
- whatIf (bool, opz.) — esecuzione a secco
- nonInteractive (bool, opz.) — niente prompt
- correlationId (string, opz.) — tracciabilità

Schema (bozza)
{
  "type": "object",
  "required": ["action", "params"],
  "properties": {
    "action": { "type": "string", "minLength": 3 },
    "params": { "type": "object" },
    "whatIf": { "type": "boolean" },
    "nonInteractive": { "type": "boolean" },
    "correlationId": { "type": "string" }
  }
}

Esempio — Creazione utente DB
{
  "action": "db-user:create",
  "params": {
    "mode": "sql-contained",
    "db": "EasyWayDataPortal",
    "username": "svc_tenant01_writer",
    "roles": ["portal_reader", "portal_writer"],
    "expires_hours": 72,
    "storeInKeyVault": true,
    "keyvault": { "name": "kv-easyway-dev", "secretName": "sql-user-svc_tenant01_writer" }
  },
  "whatIf": false,
  "nonInteractive": true,
  "correlationId": "op-2025-10-21-001"
}

Flusso standard (n8n.dispatch)
Obiettivo: tutti i nuovi intent passano dall'orchestratore n8n come entrypoint unico.

Esempio - Dispatch verso agente
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "db-user:create",
    "params": {
      "mode": "sql-contained",
      "database": "EasyWayDataPortal",
      "username": "svc_tenant01_writer",
      "roles": ["portal_reader", "portal_writer"],
      "storeInKeyVault": true,
      "keyvault": { "name": "kv-easyway-dev", "secretName": "sql-user-svc_tenant01_writer" }
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-06-001",
    "decision_trace_id": "trace-001"
  }
}
```
Note
- Ogni azione documenta i propri params nella pagina Wiki dedicata.
- I manifest degli agent elencano le azioni supportate.









