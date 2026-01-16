---
id: ew-argos-change-versioning
title: ARGOS – Change & Versioning (v1)
summary: SemVer, rollout (shadow/canary/A‑B), backout e audit con best practice di pipeline.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it, versioning]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# ARGOS – Change & Versioning Guide (v1)

> Nota: capitolo da ampliare. Obiettivo: governare cambi con SemVer, rollout controllato (shadow/canary/A‑B), backout e audit, misurandone gli effetti sui KPI/SLO.

Best practice EasyWay
- SemVer: PATCH (meta), MINOR (tuning/additivo), MAJOR (semantica/severità). MAJOR richiede dual‑read/dual‑write e viste di compatibilità.
- Rollout Gate: usare canary/A‑B con success criteria (Noise, Conformity_Wo, GPR); early stop/backout codificati.
- Pipeline: PR template con sezione “Change Type & Backout”; gate di governance (`ewctl`) prima del merge.

Da dettagliare
- Workflow di promozione, freeze window, pattern compatibilità, checklist e RACI.





