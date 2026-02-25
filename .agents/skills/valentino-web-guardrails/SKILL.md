---
name: valentino-web-guardrails
description: Review UI code using both EasyWay Valentino guardrails and Vercel web design guidelines. Use when asked to audit agent-console, check anti-fragility, validate PRODUCT vs OPS boundaries, or run a mixed design+ops review.
---

# Valentino + Web Design Guardrails

Run a combined review for `EasyWayDataPortal` using:
- Valentino architecture/ops rules from repo docs
- Latest Vercel web interface guidelines

## When To Use
- User asks for a mixed review: Valentino + web design guidelines
- User asks to check `agent-console` quality and anti-fragility
- User asks for guardrail compliance before merge/release

## Required Sources
Read these first when they exist:
- `docs/ops/VALENTINO_SITE_APP_CONSOLE_PLAYBOOK.md`
- `docs/ops/VALENTINO_ANTIFRAGILE_GUARDRAILS.md`

Fetch latest UI guidelines before each review:
- `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`

## Review Workflow
1. Identify scope files (from user input; otherwise ask for file(s) or pattern).
2. Load Valentino docs above and extract non-negotiable checks.
3. Fetch latest Vercel guideline document.
4. Review code against both rule sets.
5. Output findings first, ordered by severity.

## Valentino Checks (Must Cover)
- No hardcoded runtime metrics in UI markup/JS.
- PRODUCT vs OPS boundary is respected.
- `agent-console` remains ops-first (not a second product UI).
- Routing/state structure is maintainable (no uncontrolled global logic growth).
- Evidence of reliability hooks (`health`, `correlationId`, degraded handling) where relevant.

## Output Format
- Findings first, with `file:line` references.
- For each finding: severity, why it matters, minimal fix.
- If no findings: explicitly state "No critical findings", then list residual risks/gaps.

## Notes
- Prefer concrete, patchable recommendations over abstract style advice.
- If a rule conflict appears, prioritize security/reliability and explicit product boundaries.
