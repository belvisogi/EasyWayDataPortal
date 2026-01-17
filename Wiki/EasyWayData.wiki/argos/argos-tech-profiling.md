[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

title: ARGOS – Tech Profiling & Reliability (v1)
tags: [argos, dq, agents, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it, profiling]
status: active
updated: '2026-01-16'
redaction: [email, phone]
id: ew-argos-tech-profiling
chunk_hint: 250-400
entities: []
include: true
summary: Modulo M3 di ARGOS dedicato al profiling tecnico, monitoraggio drift e IT health (file/table/job), con supporto per "Soft Gates".
llm: 
  pii: none
owner: team-platform
---

# ARGOS – Tech Profiling & Reliability (v1)

## Domande a cui risponde
1. Quali metriche traccia il modulo Tech Profiling (M3)?
2. Che cos'è un "Soft Gate" di profiling?
3. Come vengono monitorati i file piccoli (Small Files)?

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






