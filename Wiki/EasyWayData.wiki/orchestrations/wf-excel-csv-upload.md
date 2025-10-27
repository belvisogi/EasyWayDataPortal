---
id: ew-orch-wf-excel-csv-upload
title: Orchestrazione – wf.excel-csv-upload (WHAT)
summary: Manifesto del workflow Excel/CSV→Dashboard in logica WHAT-first, con stati, esiti, contratti e diario di bordo.
status: active
owner: team-platform
tags: [orchestration, use-case, argos, agents, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# Orchestrazione – wf.excel-csv-upload (WHAT)

Principio
- WHAT-first: definire cosa fare (obiettivo, stati, esiti, contratti, messaggi) prima del come. L’implementazione degli agenti arriverà dopo, aderendo a questo contratto.

Scopo
- Da file Excel/CSV a dashboard pronta + chat, con tracciabilità (Decision Trace), qualità (ARGOS) e diario di bordo comprensibile a tutti (One‑Button UX).

Manifest JSON
- Percorso: `docs/agentic/templates/orchestrations/wf.excel-csv-upload.manifest.json`
- Contiene: scope, ruoli, feature flags, pre/post‑condizioni, stages, transizioni, osservabilità, riferimenti a policy/mapping, messaggi UX standard.

Stati canonici (diario)
- uploaded → parsed → dq_evaluated → mapped → staged → merged → materialized → completed (+ failed/deferred)

Gates & decisioni
- DQ Gate (minimo): formato, obbligatori, tipi, domini chiave; duplicati e outlier come warn. PASS/DEFER avanzano; FAIL mostra correzioni.

Eventi & trace
- `argos.run.completed` (upload/parsing), `argos.gate.decision` (DQ), opz. `argos.ticket.opened` su FAIL critico. `decision_trace_id` propagato.

UX One‑Button
- Copioni semplici per OK/Warn/Error ad ogni stato (in manifest `ux_prompts`).
- Percorso Base sempre disponibile; Pro sblocca mapping/tuning.

SLO esperienza
- file→dashboard ≤ 2 min; first‑try success ≥ 85%.

Prossimi passi (HOW in seguito)
- Implementare gli agent aderendo al manifest: Ingestion, DQ (ARGOS), Mapper, ETL, Analytics, Orchestrator.
- Aggiungere test su flussi interni e diari di bordo reali.

Riferimenti
- Use Case – Entrate/Uscite: `use-cases/entrate-uscite.md`
- ARGOS – Quality Gates: `argos/argos-quality-gates.md`
- Governance DQ: `governance-dq.md`

