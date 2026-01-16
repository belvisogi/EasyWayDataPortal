---
title: Orchestrazione – wf.excel-csv-upload (WHAT)
tags: [orchestration, use-case, argos, agents, domain/control-plane, layer/orchestration, audience/non-expert, audience/dev, privacy/internal, language/it]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-orch-wf-excel-csv-upload
chunk_hint: 250-400
entities: []
include: true
summary: Manifesto del workflow Excel/CSV→Dashboard in logica WHAT-first, con stati, esiti, contratti e diario di bordo.
llm: 
pii: none
owner: team-platform
---

# Orchestrazione – wf.excel-csv-upload (WHAT)

Principio
- WHAT-first: definire cosa fare (obiettivo, stati, esiti, contratti, messaggi) prima del come. L’implementazione degli agenti arriverà dopo, aderendo a questo contratto.

Scopo
- Da file Excel/CSV a dashboard pronta + chat, con tracciabilità (Decision Trace), qualità (ARGOS) e diario di bordo comprensibile a tutti (One‑Button UX).

## Domande a cui risponde
- Qual è l'obiettivo end-to-end del workflow e quali stati canonici usa nel diario?
- Quali gate di qualità (ARGOS/DQ) vengono applicati e quali esiti fanno avanzare/bloccare?
- Quali eventi vengono emessi e come si propaga/usa `decision_trace_id`?
- Dove sta il manifest JSON e cosa contiene (stati, transizioni, `ux_prompts`, osservabilità)?
- Quali output e messaggi devono finire nel diario di bordo per essere “one-button” e auditabile?
- Quali sono i prossimi passi HOW (agenti da implementare) aderendo al contratto WHAT?

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


