---
id: ew-argos-policy-dsl
title: ARGOS – Policy DSL & Registry (v1.1)
summary: DSL di policy DQ (deterministiche/probabilistiche) e Registry, con SemVer, linter e integrazioni.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it, policy, data-quality]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []---

# ARGOS – Policy DSL & Registry Specification (v1.1)

> Scopo: definire un linguaggio di policy agnostico (DSL) e il Registry per ciclo di vita, versioning e promozione delle regole di data quality. Allineato a Quality Gates v1.1, Event Schema, KPI & SLO, Tech Profiling e Interop.

Integrazione EasyWay
- Repository: mantenere esempi Policy/Policy Set in JSON/YAML versionati e convalidati in CI (schema check).
- Linter: esporre un comando agente che valida naming, efficacy/noise/flapping, privacy; pubblicare risultato nel Run Hub.
- SemVer: usare PATCH/MINOR/MAJOR coerente con il Rollout Gate; MAJOR richiede dual‑read/dual‑write e backout.
---

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




