---
name: valentino-backoffice-architect
description: Plan and scope the real EasyWay backoffice sections (Agents Console, Appointments, CRM) inside the live frontend. Use for route map, module boundaries, API contracts, and MVP sequencing.
---

# Valentino Backoffice Architect

Use this skill to define architecture before coding.

## Goal
Design backoffice modules in the real site (`http://80.225.86.168/`) with clear boundaries:
- `/backoffice/agents`
- `/backoffice/appointments`
- `/backoffice/crm`

## Required Inputs
- `docs/ops/VALENTINO_SITE_APP_CONSOLE_PLAYBOOK.md`
- `docs/ops/VALENTINO_ANTIFRAGILE_GUARDRAILS.md`
- `docs/ops/templates/FRAMEWORK_DECISION_TEMPLATE.md`
- `docs/ops/templates/FRONTEND_FEATURE_BOUNDARY_TEMPLATE.md`

## Workflow
1. Classify requested feature as `OPS` or `PRODUCT`.
2. Define route and module owner.
3. Define minimal API contract (runtime data only, no hardcoded metrics).
4. Produce MVP slice with 1-week deliverable.
5. List risks and Go/No-Go criteria.

## Output
- Architecture decision (short)
- Route map
- Contract draft
- Ordered backlog (high -> low value)
