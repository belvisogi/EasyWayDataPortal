---
id: ew-argos-coach-agent
title: ARGOS – Coach Agent (v1)
summary: Nudge, proposals e playbook suggestion per ridurre recidiva e rumore, con telemetria outcome.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []---

# ARGOS – Coach Agent (Spec v1)

> Scopo: guidare produttori e team nel ridurre errori ricorrenti e rumore, attraverso nudges mirati, proposte di tuning policy e patch di contratto. Agente del modulo M2 – Biz‑Learning.

Integrazione EasyWay
- Modalità: partire in ASSIST su domini pilota; tracciare KPI outcome (Noise↓, recidiva↓, GPR↑) in dashboard.
- Eventi: `argos.coach.nudge.sent` con link a Decision Trace e scorecard; digest includono nudge e risultati.
- Sicurezza: template di nudge senza PII; conferme human‑in‑the‑loop.
---

## Trigger e segnali
Noise Budget, Error Concentration, Profiling drift, esiti gate ricorrenti.

## Azioni
NUDGE (SUGGEST/ASSIST/AUTOPILOT), POLICY/CONTRACT PROPOSAL (canary/A‑B), PLAYBOOK suggestion.

## Telemetria
Open/Click, Confirm_read, Δ Noise (7/30d), Recidiva 30d; evento `argos.coach.nudge.sent`.

## Rollout e RACI
Pilot 1–2 domini, KPI outcome, ownership chiara e integrazione con governance portale.




