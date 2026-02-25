---
name: valentino-backoffice-builder
description: Implement minimal, production-focused frontend slices for EasyWay backoffice modules (agents, appointments, CRM) while respecting Valentino guardrails and boundary rules.
---

# Valentino Backoffice Builder

Use this skill when implementing code, not just reviewing.

## Rules
1. Patch minimum first.
2. Keep `OPS` and `PRODUCT` separated.
3. No hardcoded runtime values in UI.
4. Prefer stable, readable modules over clever patterns.

## Required Inputs
- `docs/ops/VALENTINO_L3_AGENT_PROFILE.md`
- `docs/ops/VALENTINO_ANTIFRAGILE_GUARDRAILS.md`
- `docs/ops/templates/VALENTINO_COMPONENT_TEMPLATE.md`

## Build Workflow
1. Select one thin vertical slice (single route/view).
2. Implement UI + data wiring with runtime contract.
3. Add basic error/degraded handling.
4. Run guardrail review (`valentino-web-guardrails`).
5. Return patch summary and residual risk.

## Definition of Done
- Route works
- Data is runtime-driven
- No boundary violation
- Findings high=0 for touched files
