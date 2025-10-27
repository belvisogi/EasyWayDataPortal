---
id: ew-argos-event-schema
title: ARGOS – Event Schema Addendum (v1)
summary: Elenco eventi canonici argos.* e note per pubblicare JSON Schema e validarli in CI.
status: draft
owner: team-platform
tags: [argos, dq, agents, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone]
entities: []
---

# ARGOS – Event Schema Addendum (v1)

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
