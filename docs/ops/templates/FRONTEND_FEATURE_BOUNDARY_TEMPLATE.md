# Frontend Feature Boundary Template

Use this template before implementing any new frontend feature.

## 1) Feature
- Name:
- Request source:
- Owner:

## 2) Classification (choose one)
- [ ] `OPS` (`apps/agent-console`)
- [ ] `PRODUCT` (`apps/portal-frontend`)

## 3) Why this classification
- Primary users:
- Business/operational goal:
- Why it does NOT belong to the other area:

## 4) Data Contract
- API/config source:
- Schema version:
- Runtime fields used:
- [ ] No hardcoded runtime metrics in UI

## 5) UI/UX Impact
- Views/components touched:
- Accessibility/performance considerations:

## 6) Risk Check
- [ ] No overlap with existing feature in other area
- [ ] No boundary violation
- [ ] No hidden dependency lock-in

## 7) Test/Verification
1. Smoke test:
2. Boundary check:
3. Regression check:

## 8) Merge Gate
- [ ] Approved by boundary owner
- [ ] Guardrail review complete
- [ ] Ready to merge

