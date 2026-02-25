# Valentino Component Template (Static-First)

Use this template for new `agent-console` UI pieces.

## 1) Component Metadata
- Name:
- View route:
- Owner:

## 2) Purpose
- Ops outcome this component supports:
- Why this is OPS (not PRODUCT):

## 3) File Structure
- HTML target:
- CSS target:
- JS module(s): `api`, `state`, `views`, `events`

## 4) Data Binding
- Data source (API/config):
- Required fields:
- Refresh strategy: polling | SSE | websocket
- [ ] No hardcoded runtime values

## 5) Reliability Hooks
- Health state handled (`ok|degraded|down`):
- Error state rendered:
- Correlation ID visible where relevant:

## 6) Interaction Rules
- User actions:
- Confirmation required actions:
- Fallback when API unavailable:

## 7) Done Criteria
- [ ] Works on target route
- [ ] Uses runtime data only
- [ ] Keeps logic modular (no global sprawl)
- [ ] Smoke test passed

