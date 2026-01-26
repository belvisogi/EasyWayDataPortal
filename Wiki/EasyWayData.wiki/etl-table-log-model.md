---
id: ew-etl-table-log-model
title: ETL – Table Log Model
summary: Modello log tabellare per esecuzioni pipeline (run logs, task logs, metriche, allarmi) e query operative.
status: active
owner: team-data
tags: [etl, logging, audit, domain/datalake, layer/reference, audience/dev, audience/ops, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/datalake|datalake]] > [[Layer - Reference|Reference]]

# ETL – Table Log Model
Breadcrumb: Home / Datalake / ETL Table Log

Obiettivo
- Definire tabelle/file log per run ETL: campi minimi, pattern di query e retention.

Tabelle/File (bozza)
- etl_workflow (id, key, engine, owner, sla)
- etl_run (workflow_id, run_uid, status, started_at, ended_at, duration_s, rows_in, rows_out, bytes_in, bytes_out, error_code, error_message, env)
- etl_task_run (run_id, task_key, status, started_at, ended_at, duration_s, rows_in, rows_out, error_message)
- etl_run_metric (run_id, name, value)
- etl_run_alert (run_id, severity, message, created_at)

Access patterns
- Ultimo stato per workflow; fallimenti ultime 24h; runs stuck; breaches SLA; throughput giornaliero.

Integrazione con agenti
- Gli agenti registrano start/end run con Output Contract minimo (summary, stato, tempi, KPI) e link a Log Analytics.
- Dashboard leggono queste tabelle/file per viste operative.

Riferimenti
- ETL/ELT Inspirations (Table Log)
- Datalake – Ensure Structure / portal-audit








