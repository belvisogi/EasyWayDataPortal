---
id: ew-plan-diary-contract
title: Contratto Plan + Diario di Bordo (Machine-readable)
summary: Standard JSON per plan (task list) e diario di bordo (timeline) usati da orchestrator/n8n e indicizzati nel RAG.
status: active
owner: team-platform
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, orchestration, n8n, agentic]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

# Contratto Plan + Diario di Bordo (Machine-readable)

Scopo
- Rendere **ripetibile** e **indicizzabile** la logica “task list + timeline” che gli agent e n8n producono prima/durante una run.
- Consentire a UI e workflow di mostrare cosa sta succedendo e di fare human-in-the-loop in modo standard.

Schema (source of truth)
- Plan JSON Schema: `docs/agentic/templates/plans/plan.schema.json`
- Diary JSON Schema: `docs/agentic/templates/plans/diary.schema.json`

Esempi (sample)
- Plan sample: `docs/agentic/templates/plans/samples/release.preflight.security.plan.sample.json`
- Diary sample: `docs/agentic/templates/plans/samples/release.preflight.security.diary.sample.json`

Regole minime (canonico)
- Ogni run deve avere:
  - `correlationId` stabile end-to-end
  - `intent` coerente con lo schema WHAT dell'intent
  - Plan con step e stati (`pending|in_progress|waiting_approval|completed|failed`)
  - Diario di bordo con entry per ogni stage (`timestamp, stage, outcome, reason, next, decision_trace_id, artifacts[]`)
- I messaggi UI devono derivare dai `ux_prompts` (IT/EN) quando disponibili.
- In caso di errore ricorrente: aggiornare doc + KB (vedi `docs-agentic-audit`).

Riferimenti
- Metodo WHAT-first: ``
- Output contract: `Wiki/EasyWayData.wiki/output-contract.md`
- Intent contract: `Wiki/EasyWayData.wiki/intent-contract.md`
- Orchestrator n8n: `Wiki/EasyWayData.wiki/orchestrations/orchestrator-n8n.md`


## Vedi anche

- [Control Plane - Panoramica](./control-plane/index.md)
- [UX & API Spec — Plan Viewer, Wizard e WhatIf (bozza)](./UX/agentic-ux.md)
- [Agents Registry (owner, domini, intent)](./control-plane/agents-registry.md)
- [Orchestratore n8n (WHAT)](./orchestrations/orchestrator-n8n.md)
- [Orchestrazione – wf.excel-csv-upload (WHAT)](./orchestrations/wf-excel-csv-upload.md)




