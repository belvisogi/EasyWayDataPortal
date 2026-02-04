---
id: ew-etl-governance-sla
title: ETL – Governance & SLA
summary: Policy di SLA/SLO/SLI per pipeline ETL/ELT, error budget, alerting, fallback ed escalation, in stile agent‑first.
status: active
owner: team-data
tags: [etl, domain/datalake, layer/spec, audience/ops, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
updated: '2026-01-05'
next: TODO - definire next step.
type: guide
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/datalake|datalake]] > 

# ETL – Governance & SLA
Breadcrumb: Home / Datalake / ETL Governance & SLA

Scopo
- Definire standard di servizio e governo per le pipeline: SLA/SLO/SLI, error budget, alerting, fallback ed escalation, aderenti a EasyWayDataPortal.

Principi (EasyWay / agent‑first)
- As‑Code: target e policy nel repo, versionati e tracciati (spec → gate → audit).
- WhatIf‑Ready: dry‑run e validazioni prima dei cambi (no sorprese in prod).
- Output Contract: eventi operativi uniformi (status, tempi, KPI) per dashboard e audit.
- Guardrail di costo: scelte tecniche che evitano sprechi (autoscaling, spegnimento notturno in dev).

Definizioni
- SLI: indicatori misurati (es. latenze, puntualità, throughput, % scarti, success rate).
- SLO: obiettivi sugli SLI (es. T+60m consegna 99%, success >= 99.5%).
- SLA: impegno contrattuale (interna/esterna) e penali/processi.
- RTO/RPO: tempi di ripristino e perdita dati accettabile.

Tiering (target suggeriti)
- Tier 1 (critico): puntualità T+15/30m 99.9%, success 99.9%, RTO 1h, RPO < 15m.
- Tier 2 (alto): T+60/120m 99.5%, success 99.5%, RTO 4h, RPO < 1h.
- Tier 3 (normale): T+24h 99%, success 99%, RTO 24h, RPO < 24h.

SLI minimi per pipeline
- Puntualità consegna (delta atteso vs effettivo per finestra)
- Success rate (run success / totale)
- Throughput (rows_out per finestra)
- Data Quality (tasso scarti, regole top violated)
- Latency end‑to‑end (inizio estrazione → disponibilità target)

Error Budget & Release
- Ogni SLO ha un “budget di errore” (es. 0.5%/mese): al superamento, congelare cambi non urgenti e lavorare su resilienza.
- Collegare gating: Doc Alignment + Output Validation + WhatIf obbligatorio per modifiche.

Alerting & Escalation (matrice)
- Severity 1 (Tier 1): paging immediato (Ops on‑call), escalation entro 15’ a owner pipeline e team‑data.
- Severity 2: notifica canale #data‑alerts, presa in carico entro 1h.
- Severity 3: digest giornaliero.
- Canali: Teams/Email + integrazione con incident management (ticket, post‑mortem sintetico).

Fallback & Runbook
- Retry/backoff automatici; reprocess window definita per ogni pipeline.
- Quarantena file “sospetti” in `technical/` con ticket.
- Runbook per: reset stato, ri‑submit job, rigenerazione partizioni, ripristino credenziali.

Audit & Logging (minimi)
- Log in `portal-audit/etl-execution-logs/` con campi: workflow_key, status, started_at, ended_at, duration_s, rows_in/out, error_message, env, correlation_id.
- Conservazione coerente con “Datalake – Set Retention”.

Dashboard & KPI
- Vista per workflow: ultimo run, stato, latenze, throughput, SLO trend, breaches.
- Vista incident: fallimenti 24h, cause principali, tempo medio di ripristino (MTTR).

Allineamento Agentico
- Intents (roadmap): `etl-slo:define`, `etl-slo:validate`, `etl-alerts:simulate`.
- Ogni azione produce Output Contract con `summary`, counts e anteprime (WhatIf) o stato applicato.

Spec SLO (bozza)
- JSON consigliato per validazione automatica: `agents/agent_datalake/templates/slo/slo.sample.json` (campi minimi: `pipeline_key`, `tier`, `slos[]`, `runbook_url`).
- Intent di validazione (stub): `pwsh scripts/ewctl.ps1 --engine ps --intent etl-slo-validate`.

Quick Checklist
- [ ] SLI/SLO per pipeline definiti e versionati
- [ ] Tier assegnato; RTO/RPO documentati
- [ ] Alerting/escalation mappati a tier e severity
- [ ] Runbook fallback pubblici; test periodici
- [ ] Dashboard KPI operative; audit consolidato

Riferimenti
- ETL/ELT Playbook; ETL/ELT Template
- ETL – Table Log Model; ETL – DQ Framework
- Doc Alignment Gate; Output Contract










