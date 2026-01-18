---
id: argos-modular-interop
title: ARGOS – Modular Architecture & Interop (v1)
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  include: true
  chunk_hint: 5000
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

title: ARGOS – Modular Architecture & Interop (v1)
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it]
status: active
updated: '2026-01-16'
redaction: [email, phone]
id: ew-argos-modular-interop
chunk_hint: 250-400
entities: []
include: true
summary: Architettura modulare ARGOS (M1 Fast-Ops, M2 Biz-Learning, M3 Tech-Profiling), Correlation Fabric ed eventi canonici.
llm: 
  pii: none
owner: team-platform
---

# ARGOS – Modular Architecture & Interop (v1)

## Domande a cui risponde
1. Quali sono i tre moduli architetturali di ARGOS?
2. A cosa serve il Correlation Fabric?
3. Quali sono gli identificativi chiave per la correlazione (es. RUN_ID)?

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







