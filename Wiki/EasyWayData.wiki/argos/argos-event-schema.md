---
id: ew-argos-event-schema
title: ARGOS – Event Schema Addendum (v1)
summary: Specifica degli eventi canonici emessi da ARGOS (es. argos.run.completed, argos.gate.decision) per l'integrazione nel Correlation Fabric.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, event]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone]
entities: []
updated: '2026-01-16'
next: Definire JSON Schema formale.
---

[Home](./start-here.md) >  > 

# ARGOS – Event Schema Addendum (v1)

## Domande a cui risponde
1. Quali sono gli eventi principali emessi da ARGOS?
2. Dove vengono pubblicati gli schemi JSON degli eventi?
3. Come vengono gestiti i dati personali (PII) negli eventi?

> Nota: documento placeholder da completare con JSON Schema e esempi payload per tutti gli eventi elencati sotto. Integrare con il Correlation Fabric del portale e con la pipeline di validazione.

Eventi canonici (da definire con schema/policy)
- `argos.run.completed`
- `argos.gate.decision`
- `argos.profile.drift`
- `argos.coach.nudge.sent`
- `argos.policy.proposal`
- `argos.contract.proposal`
- `argos.ticket.opened`

Integrazione EasyWay
- Repository: pubblicare gli schema JSON in `docs/agentic/templates/events/` e validare in CI.
- QoS/Delivery: DLQ e retry policy allineate al bus eventi del portale.
- Privacy/Retention: campi PII esclusi o sanificati; retention hint per topic.








