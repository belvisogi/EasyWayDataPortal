---
id: argos-policy-dsl
title: ARGOS – Policy DSL & Registry (v1.1)
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  pii: none
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
entities: []
type: guide
---
[Home](./start-here.md) >  > 

title: ARGOS – Policy DSL & Registry (v1.1)
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it, policy, data-quality]
updated: '2026-01-16'
status: active
redaction: [email, phone]
id: ew-argos-policy-dsl
chunk_hint: 250-400
entities: []
include: true
summary: Linguaggio di policy agnostico (DSL) e Registry per il ciclo di vita delle regole DQ, incluso versioning SemVer e Linter.
llm: 
  pii: none
owner: team-platform
---

# ARGOS – Policy DSL & Registry (v1.1)

## Domande a cui risponde
1. Come definisco una regola di Data Quality nel DSL?
2. Quali sono gli stati del ciclo di vita di una policy nel Registry?
3. Il linter controlla la privacy delle policy?

## Principi
Chiarezza vs potenza, deterministic+probabilistic, severity base distinta da severity dinamica, explainability, compatibilità, privacy‑first.

## Oggetto Policy (schema logico)
- Meta e chiavi: RULE_ID, RULE_VERSION, TITLE, DESCRIPTION, CATEGORY, OWNER, TAGS.
- Scope & grana: SCOPE (DOMAIN|FLOW|INSTANCE|ELEMENT), ELEMENT_REF, WHERE, ROW_KEY.
- Valutazione: POLICY_TYPE, CHECK, MOSTLY, WINDOW, SEVERITY_BASE, DISCARD_MODE, IMPACT_SCORE, NOISE_BUDGET_HINT, EXPLAIN_TRACE_REQUIRED.
- Esecuzione & output: SAMPLE_SIZE_MAX, INVALID_ROWS_PATH, METRICS_HINT.
- Governance: STATE, CHANGE_TYPE, ADR_REF, SECURITY_REVIEW_REF, EXPERIMENT (CANARY|AB …).

## CHECK – costrutti DSL (estratti)
- Deterministiche: FORMAT, DOMAIN, COMPLETENESS, FRESHNESS, UNIQUENESS, REFERENTIAL, CONSISTENCY.
- Probabilistiche: DISTRIBUTION/PATTERN DRIFT (PSI/KS/Z), SHAPE/VOLUME, CO‑OCCURRENCE.

## Esempi (descrittivo)
- Dominio valori con ALERT_WITH_DISCARD e IMPACT 0.8.
- Drift distribuzionale con MOSTLY 0.9 e canary.

## Linter & pre‑check
Naming/stile; Efficacy/Noise/Flapping; Performance; Privacy (no PII nei valori). Integrato con Gate INGRESS.

## Registry – stati, workflow, versioning
Stati DRAFT→PROPOSED→APPROVED→DEPRECATED→RETIRED; SemVer per policy e Policy Set.

## Integrazioni
Gates (severity dinamica/trace), Tech Profiling (soglie), Biz‑Learning (proposals), eventi & audit.

## DoD (v1.1)
Schema Policy completo + linter; workflow & semver; integrazioni; esempi; privacy ok.









