---
type: guide
status: draft
---

---
title: ARGOS – Overview e Integrazione
tags: [argos, dq, agents, domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, data-quality]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-argos-overview
chunk_hint: 250-400
entities: []
include: true
summary: Panoramica dell'integrazione del framework di Data Quality ARGOS in EasyWay, inclusi i moduli Fast-Ops (Gates), Biz-Learning (Coach) e Tech-Profiling.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, data-quality]
updated: '2026-01-16'
redaction: [email, phone]
id: ew-argos-overview
chunk_hint: 250-400
entities: []
include: true
llm: 
  pii: none

llm:
  include: true
  chunk_hint: 5000---

[Home](./start-here.md) >  > 

# ARGOS – Overview e Integrazione con EasyWayDataPortal

## Domande a cui risponde
1. Quali sono i tre moduli principali di ARGOS?
2. Come abilito i gate di Data Quality nella pipeline?
3. Dove trovo la documentazione sui Quality Gates?

Scopo
- Integrare il framework di Data Quality “ARGOS” all’interno di EasyWayDataPortal in modo agent‑first, mantenendo documentazione e operatività coerenti con le best practice del portale.

Moduli ARGOS
- M1 – Fast‑Ops (Gating): Ingress/DQ/Rollout Gates con Decision Trace, severity dinamica, hysteresis/cool‑down, quarantine e backout.
- M2 – Biz‑Learning (Coach): nudges, policy/contract proposals, playbook suggestion, riduzione recidiva e noise.
- M3 – Tech‑Profiling (IT Health): profiling, drift, file/partition/process health, suggerimenti soglie/contratti e digest IT.

Integrazione EasyWay (best practice)
- Pipeline ADO: abilitare `USE_EWCTL_GATES=true` per Checklist/DB Drift/KB Consistency; usare `scripts/ewctl.ps1 --engine ps|ts` per orchestrazione.
- Doc viva: aggiungere/aggiornare pagine Wiki e ricette `agents/kb/recipes.jsonl` per ogni evoluzione ARGOS (policy, gates, profiling, alerting, playbook).
- Manifest & allowed paths: ogni agente (es. Coach/Policy) deve dichiarare `agents/<agent>/manifest.json` e rispettare `allowed_paths` (vedi ``).
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










