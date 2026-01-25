---
title: Orchestratore n8n (WHAT)
tags: [domain/control-plane, layer/orchestration, audience/dev, privacy/internal, language/it, orchestration, n8n, agents]
status: active
updated: 2026-01-16
redaction: []
id: ew-orch-n8n-dispatch
chunk_hint: 250-350
entities: []
include: true
summary: Manifesto WHAT dell'orchestratore n8n per instradare intent agentici verso workflow dichiarati.
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000
---

[[../start-here.md|Home]] > [[../control-plane/index.md|Control-Plane]] > Orchestration

# Orchestratore n8n (WHAT)
Principio
- Instradare intent JSON (vedi `intent-contract`) verso workflow n8n dichiarati, applicando pre-check di governance e propagando metadati (`correlationId`, `whatIf`, `decision_trace_id`).

Scopo
- Esporre un punto unico per esecuzioni agentiche via n8n (locale/server), riusabile da UI/CLI/agent.
- Garantire coerenza con i manifest WHAT-first e i gate (Checklist/DB Drift/KB Consistency, Doc Alignment).

Policy (canonico)
- Tutti i nuovi intent devono passare da `orchestrator.n8n.dispatch` come entrypoint unico.
- Motivazione: coerenza, audit, log uniformi e facilità di retrieval/RAG.

Esempio: preflight go-live (security/compliance/audit)
- Intent: `release.preflight.security`
- Wiki: `orchestrations/release-preflight-security.md`

## Domande a cui risponde
- Qual è il contratto di input (campi obbligatori) per dispatchare un intent via n8n?
- Quali gate vengono eseguiti pre-dispatch e come funziona `whatIf` (default e override)?
- Come viene invocato `ewctl` e come si propagano `correlationId` e `decision_trace_id`?
- Qual è il formato di output atteso e come viene validato/parso dal workflow?
- Dove finiscono log ed eventi (events.jsonl/Activity Log) e quali KPI minimi conviene tracciare?
- Come gestire azioni potenzialmente distruttive (approval/whatIf/guardrail)?

Input (contratto)
- `action` (string) es. `wf.excel-csv-upload`, `doc-alignment`.
- `params` (object) conforme all'intent specifico.
- `whatIf` (bool, default true), `nonInteractive` (bool), `correlationId` (string), `decision_trace_id` (string, opz.).
- Schema: `docs/agentic/templates/intents/orchestrator.n8n.dispatch.intent.json`.

Output (standard)
- `workflow_id`, `run_id`, `dispatch_ok`, `gate_precheck` (risultati sintetici dei gate opzionali).
- Struttura conforme a `output-contract` (action-result), arricchita con `diary_log_fields` ove presenti.

Esempio (intent -> n8n.dispatch -> agent)
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
    "correlationId": "op-2026-01-06-001"
  }
}
```sql

Gates e controlli
- Pre-dispatch: Doc Alignment + Checklist opzionale in WhatIf; DB Drift/KB Consistency se rilevanti.
- WhatIf-by-default: le azioni pericolose richiedono esplicito `whatIf=false`.
- Audit: log in `agents/logs/events.jsonl` e (opz.) forwarding verso Activity Log.

Nodi standard n8n (raccomandati)
- Receive Intent (Webhook/API Key) → Validate Intent (JSON Schema) → Gate Precheck (`ewctl`/script) → Dispatch (Command node: `pwsh scripts/ewctl.ps1 --engine ps --intent <action> --params <json> --noninteractive`) → Parse Output/Validate → Log → Notify (Teams/Email opz.).

Osservabilità
- Propagare `decision_trace_id` se presente nel payload (es. DQ Gate) e includerlo nel log eventi.
- KPI minimi: time_to_dispatch_ms, gate_failures, first_try_success.

Riferimenti
- Intent: `docs/agentic/templates/intents/orchestrator.n8n.dispatch.intent.json`
- Manifest esempio: `docs/agentic/templates/orchestrations/wf.excel-csv-upload.manifest.json`
- Contratti: `Wiki/EasyWayData.wiki/intent-contract.md`, `Wiki/EasyWayData.wiki/output-contract.md`
- Governance/gates: `Wiki/EasyWayData.wiki/agents-governance.md`, `doc-alignment-gate.md`







