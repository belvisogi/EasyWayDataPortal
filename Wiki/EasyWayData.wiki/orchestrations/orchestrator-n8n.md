---
id: ew-orch-n8n-dispatch
title: Orchestratore n8n (WHAT)
summary: Manifesto WHAT dell'orchestratore n8n per instradare intent agentici verso workflow dichiarati.
status: active
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, privacy/internal, language/it, orchestration, n8n, agents]
llm:
  include: true
  pii: none
  chunk_hint: 250-350
  redaction: []
entities: []
---

# Orchestratore n8n (WHAT)
Principio
- Instradare intent JSON (vedi `intent-contract`) verso workflow n8n dichiarati, applicando pre-check di governance e propagando metadati (`correlationId`, `whatIf`, `decision_trace_id`).

Scopo
- Esporre un punto unico per esecuzioni agentiche via n8n (locale/server), riusabile da UI/CLI/agent.
- Garantire coerenza con i manifest WHAT-first e i gate (Checklist/DB Drift/KB Consistency, Doc Alignment).

Input (contratto)
- `action` (string) es. `wf.excel-csv-upload`, `doc-alignment`.
- `params` (object) conforme all'intent specifico.
- `whatIf` (bool, default true), `nonInteractive` (bool), `correlationId` (string), `decision_trace_id` (string, opz.).
- Schema: `docs/agentic/templates/intents/orchestrator.n8n.dispatch.intent.json`.

Output (standard)
- `workflow_id`, `run_id`, `dispatch_ok`, `gate_precheck` (risultati sintetici dei gate opzionali).
- Struttura conforme a `output-contract` (action-result), arricchita con `diary_log_fields` ove presenti.

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




