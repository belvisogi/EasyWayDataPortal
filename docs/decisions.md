# EasyWay Core — Decisions (ADR Lite)

## 2026-02-01 — Antifragile UI Governance
Decision:
- Adopt the model: framework + audit + docs.

Why:
- Docs alone are not enforceable.
- Framework encodes the rules; audit blocks regressions; docs keep humans/agents aligned.

Scope:
- Frontend now.
- To be extended to Data Lake, DB, Security, Agents, and infra.

## 2026-02-01 — Manifesto Rendering
Decision:
- Keep manifesto as static HTML (`/manifesto.html`) and redirect `/manifesto`.

Why:
- Long-form content is stable and better served as static.
- Less runtime fragility and lower maintenance cost.

## 2026-02-01 — Cache Strategy (Frontend)
Decision:
- HTML + config no-store; assets immutable.

Why:
- Fast updates for content; stable caching for assets.

## 2026-02-01 — Demo as Runtime Page
Decision:
- Move Demo to runtime routing (`/demo`) and keep `/demo.html` as redirect fallback.

Why:
- Removes full reload flicker and keeps single-shell consistency.
- Aligns with antifragile UI governance.
