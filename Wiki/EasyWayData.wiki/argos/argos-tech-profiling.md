---
id: ew-argos-tech-profiling
title: ARGOS – Tech Profiling & Reliability (v1)
summary: Profiling tecnico, drift e IT health con viste/gate soft e KPI/SLO, integrato con EasyWay.
status: active
owner: team-platform
tags: [argos, dq, agents, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# ARGOS – Tech Profiling & Reliability (Spec v1)

> Scopo: definire il Tech Loop dedicato a profiling tecnico, drift e affidabilità IT (file/table/job). Fornisce segnali per il Gating (Fast Loop) e il Learning (Slow Loop).

Integrazione EasyWay
- DB: creare entità/viste RUN_PROFILE_RESULT, PROFILE_BASELINE, PROFILE_DRIFT_EVENT, FILE_HEALTH, PARTITION_HEALTH, PROCESS_METRICS + viste VW_*.
- Gate soft: collegare segnali di drift/health ai DQ Gates (severity dinamica, DEFER) e tracciare in Decision Trace.
- Privacy: profili con valori hash/sanitizzati e RBAC per viste IT.

---

## Estensioni LDM (estratto)
- RUN_PROFILE_RESULT: distribuzioni, null rate, cardinalità, quantili, pattern.
- PROFILE_BASELINE: bound/target e DRIFT_TEST.
- PROFILE_DRIFT_EVENT: tipo/severità/statistica/threshold/decisione/azione.
- FILE_HEALTH: size, record, compression, encoding, delimiter, small_file_flag.
- PARTITION_HEALTH: lateness, skew, dup, completeness.
- PROCESS_METRICS: durata, throughput, retry, bytes.

## Viste consigliate
VW_PROFILE_SUMMARY, VW_PROFILE_DRIFT, VW_FILE_HEALTH, VW_PARTITION_HEALTH, VW_PROCESS_EFFICIENCY.

## Gate «Profiling» (soft)
Warn/Defer su drift severo o small‑files rate elevato; routing verso RCA/Coach/Policy.

## KPI & SLO IT (indicativi)
Schema Stability ≥ 99,5%; Small Files Rate ≤ 5%; Late Partition Rate ≤ 1%; Job Success ≥ 99,9%; Throughput p95 ≥ baseline−10%.
