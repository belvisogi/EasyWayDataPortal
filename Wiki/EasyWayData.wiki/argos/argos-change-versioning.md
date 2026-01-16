---
id: ew-argos-change-versioning
title: ARGOS – Change & Versioning (v1)
summary: Guida al versionamento SemVer e al rollout controllato (Shadow/Canary/A-B) per le policy e i componenti ARGOS.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it, versioning]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone]
entities: []
updated: '2026-01-16'
next: Dettagliare workflow di promozione.
---

# ARGOS – Change & Versioning Guide (v1)

## Domande a cui risponde
1. Come si applica il SemVer alle policy di data quality?
2. Quali sono le strategie di rollout supportate (es. Canary)?
3. Cosa succede in caso di rollback (backout)?

> Nota: capitolo da ampliare. Obiettivo: governare cambi con SemVer, rollout controllato (shadow/canary/A‑B), backout e audit, misurandone gli effetti sui KPI/SLO.

Best practice EasyWay
- SemVer: PATCH (meta), MINOR (tuning/additivo), MAJOR (semantica/severità). MAJOR richiede dual‑read/dual‑write e viste di compatibilità.
- Rollout Gate: usare canary/A‑B con success criteria (Noise, Conformity_Wo, GPR); early stop/backout codificati.
- Pipeline: PR template con sezione “Change Type & Backout”; gate di governance (`ewctl`) prima del merge.

Da dettagliare
- Workflow di promozione, freeze window, pattern compatibilità, checklist e RACI.





