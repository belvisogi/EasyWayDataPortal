---
id: argos-quality-gates
title: ARGOS – Quality Gates (v1.1)
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  include: true
  chunk_hint: 5000
---
[Home](../../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

title: ARGOS – Quality Gates (v1.1)
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, data-quality]
status: active
updated: '2026-01-16'
redaction: [email, phone]
id: ew-argos-gates
chunk_hint: 250-400
entities: []
include: true
summary: Definizione dei Quality Gates di ARGOS: esiti (PASS/DEFER/FAIL), matrici decisionali, severity dinamica, hysteresis e explainability.
llm: 
  pii: none
owner: team-platform
---

# ARGOS – Quality Gates (v1.1)

## Domande a cui risponde
1. Qual è la differenza tra esito DEFER e FAIL?
2. Come funziona l'isteresi (hysteresis) per evitare il flapping?
3. Cosa contiene una Decision Trace?

## 0) Principi
1) Outcome standard: PASS | DEFER | FAIL (quarantine è zona, non outcome).
2) Explainability: ogni decisione produce una Decision Trace.
3) Severity dinamica: pesata da IMPACT_SCORE e consumo di Error/Noise Budget.
4) Anti-flapping: hysteresis/cool-down per evitare oscillazioni.
5) Safe-ops: DEFER preferito a FAIL quando impatto basso o esistono safe-actions.
6) Compatibilità: moduli M1 ma consumano segnali M2/M3 quando disponibili.

---

## 1) Tipi di Gate
- INGRESS GATE — Deterministico (contract)
- DQ GATE — Contenuto (policy + budget)
- ROLLOUT GATE — Change (shadow/canary/A-B)
- PROFILING GATE (soft) — segnali di M3

---

## 2) Input minimi
- Correlation: RUN_ID, INSTANCE_ID, FLOW_ID, DOMAIN_ID, REFERENCE_DATE, RUN_DATE.
- Policy: RULE_VERSION attive e severità base.
- Esiti: RUN_RULE_RESULT con conteggi OK/WARN/KO deduplicati.
- Budget: SLO_TARGET, Error/Noise Budget residuo.
- Impatto: IMPACT_SCORE.
- Profiling (M3): eventi drift/health.
- Esperimenti (M2): stato canary/A-B.
- Override: deroghe attive.

---

## 3) Esiti & semantica
- PASS: promozione verso reference.
- DEFER: promozione differita in Quarantine; possibili safe-actions.
- FAIL: promozione bloccata; ticket e playbook obbligatori.

---

## 4) Matrici decisionali (estratto)
Ingress: Contract KO grave → FAIL; KO minori + safe-action → DEFER; Maintenance → DEFER.

DQ: Blocking+IMPACT alto → FAIL; Noise esaurito → DEFER; Conformity_Wo sotto critico → FAIL; drift HIGH su campo chiave → DEFER.

Rollout: Shadow → monitor; Canary con success criteria → PROMOTE; Early stop → BACKOUT.

---

## 5) Severity dinamica (esempi)
`IMPACT_SCORE ≥ 0.7` e `error_budget_residuo ≤ 20%` ⇒ escalate.
`IMPACT_SCORE ≤ 0.3` e `noise_budget_residuo ≤ 0%` ⇒ de‑escalate.

---

## 6) Hysteresis & Cool-down
- WARN→OK richiede K run consecutivi (default K=2).
- DEFER→PASS: 2 PASS di fila o canary riuscito.
- FAIL→PASS: 1 PASS + ticket chiuso.
- Cool-down tuning: bloccare nuovi tuning per X giorni (default 7).

---

## 7) Override & Backout
Override a tempo con risk acceptance; backout plan obbligatorio per MAJOR; audit in Decision Trace.

---

## 8) Decision Trace (contenuto minimo)
DECISION_TRACE_ID, gate_type, outcome, reason_code, signals_json, policy_version_set, budget_before/after, severity_after_weighting, override_ref?, experiment_ref?, created_at, actor.

---

## 9) Quarantine & re-processing
Quarantine con TTL e retention; re‑processing programmato; safe-actions solo con playbook AUTO_SAFE.

---

## 10) KPI dei Gates
GPR, Blocking Rate, False PASS sample rate, Quarantine Dwell Time, Decision Trace coverage, override/backout rate, Time‑to‑decision p95.








