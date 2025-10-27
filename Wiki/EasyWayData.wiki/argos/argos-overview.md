---
id: ew-argos-overview
title: ARGOS – Overview e Integrazione
summary: Integrazione ARGOS in EasyWay (gates, DSL, playbook, profiling, coach, eventi) con best practice del portale.
status: active
owner: team-platform
tags: [argos, dq, agents, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# ARGOS – Overview e Integrazione con EasyWayDataPortal

Scopo
- Integrare il framework di Data Quality “ARGOS” all’interno di EasyWayDataPortal in modo agent‑first, mantenendo documentazione e operatività coerenti con le best practice del portale.

Moduli ARGOS
- M1 – Fast‑Ops (Gating): Ingress/DQ/Rollout Gates con Decision Trace, severity dinamica, hysteresis/cool‑down, quarantine e backout.
- M2 – Biz‑Learning (Coach): nudges, policy/contract proposals, playbook suggestion, riduzione recidiva e noise.
- M3 – Tech‑Profiling (IT Health): profiling, drift, file/partition/process health, suggerimenti soglie/contratti e digest IT.

Integrazione EasyWay (best practice)
- Pipeline ADO: abilitare `USE_EWCTL_GATES=true` per Checklist/DB Drift/KB Consistency; usare `scripts/ewctl.ps1 --engine ps|ts` per orchestrazione.
- Doc viva: aggiungere/aggiornare pagine Wiki e ricette `agents/kb/recipes.jsonl` per ogni evoluzione ARGOS (policy, gates, profiling, alerting, playbook).
- Manifest & allowed paths: ogni agente (es. Coach/Policy) deve dichiarare `manifest.json` e rispettare `allowed_paths` (vedi `AGENTS.md`).
- Privacy & sicurezza: sanitizzare sample/attachments e usare RBAC per viste IT; nessuna PII nelle policy/registry/events.
- Eventi: definire JSON Schema per `argos.*` ed emettere eventi con `DECISION_TRACE_ID` per correlazione end‑to‑end.

Mappa contenuti
- Quality Gates: `./argos-quality-gates.md`
- Policy DSL & Registry: `./argos-policy-dsl.md`
- Alerting & Notifications: `./argos-alerting.md`
- Playbook Catalog: `./argos-playbook-catalog.md`
- Modular Architecture & Interop: `./argos-modular-interop.md`
- Tech Profiling & Reliability: `./argos-tech-profiling.md`
- Coach Agent: `./argos-coach-agent.md`
- Event Schema Addendum: `./argos-event-schema.md`
- Change & Versioning Guide: `./argos-change-versioning.md`
- Glossario Unificato: `./argos-glossario.md`
