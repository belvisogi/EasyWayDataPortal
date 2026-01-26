---
id: argos-coach-agent
title: ARGOS – Coach Agent (v1)
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  include: true
  chunk_hint: 5000
---
[Home](../../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

title: ARGOS – Coach Agent (v1)
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it]
status: active
updated: '2026-01-16'
redaction: [email, phone]
id: ew-argos-coach-agent
chunk_hint: 250-400
entities: []
include: true
summary: Agente "Coach" (Modulo M2) per nudging operativo e proposte di tuning policy; guida gli utenti per ridurre recidiva e rumore.
llm: 
  pii: none
owner: team-platform
---

# ARGOS – Coach Agent (v1)

## Domande a cui risponde
1. Qual è lo scopo del Coach Agent?
2. Cosa sono i "nudge" inviati dall'agente?
3. Quali metriche o segnali attivano il Coach (es. Noise Budget)?

## Trigger e segnali
Noise Budget, Error Concentration, Profiling drift, esiti gate ricorrenti.

## Azioni
NUDGE (SUGGEST/ASSIST/AUTOPILOT), POLICY/CONTRACT PROPOSAL (canary/A‑B), PLAYBOOK suggestion.

## Telemetria
Open/Click, Confirm_read, Δ Noise (7/30d), Recidiva 30d; evento `argos.coach.nudge.sent`.

## Rollout e RACI
Pilot 1–2 domini, KPI outcome, ownership chiara e integrazione con governance portale.








