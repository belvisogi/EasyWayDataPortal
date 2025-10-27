---
id: ew-argos-modular-interop
title: ARGOS – Modular Architecture & Interop (v1)
summary: Tre moduli (M1/M2/M3) con Correlation Fabric, eventi canonici e feature flags per EasyWay.
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

# ARGOS – Modular Architecture & Interop (v1)

> Scopo: definire ARGOS come 3 moduli autonomi ma correlabili: M1 Fast‑Ops (Gating), M2 Biz‑Learning (Coach), M3 Tech‑Profiling (IT Health). Ogni modulo può vivere separatamente, condivide uno strato di correlazione.

Integrazione EasyWay
- Correlation Fabric: usare chiavi canoniche (RUN_ID, INSTANCE_ID, FLOW_ID, DOMAIN_ID, RULE_VERSION_ID, PRODUCER_ID, DECISION_TRACE_ID) in DB/API/Events.
- Eventi canonici: `argos.run.completed`, `argos.gate.decision`, `argos.profile.drift`, `argos.coach.nudge.sent`, `argos.policy.proposal`, `argos.contract.proposal`, `argos.ticket.opened`.
- Feature flags: attivazione graduale moduli e funzioni in pipeline/portal.

---

## Principi di modularità
Indipendenza, interoperabilità by‑design (eventi+chiavi), opt‑in progressivo, explainability, privacy‑first.

## I tre moduli (estratto)
- M1 – enforcement PASS/DEFER/FAIL con Decision Trace.
- M2 – nudges/proposte con KPI outcome.
- M3 – profiling/drift/health con viste e digest.

## Strato di correlazione
Chiavi, role dates, eventi canonici, tabelle/viste condivise (Run Hub, Registry).

## Boundary & contratti
Storage separato per modulo; interfacce in lettura; versioning con compatibilità forward.

## Packaging & deployment
Solo M1; M1+M3; M1+M2; Full. Feature flags e NFR (latency, backpressure, RBAC & privacy).

## RACI e roadmap modulare
Attivazione progressiva 1) M1 2) M3 3) M2 4) Full.
