---
id: ew-etl-elt-template
title: ETL/ELT Template (Per-Pipeline)
summary: Template standard per documentare una pipeline ETL/ELT: sorgente, mapping, DQ, naming, schedule, monitoraggio e audit.
status: active
owner: team-data
tags: [artifact-pipeline, etl, datalake, domain/datalake, layer/spec, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
updated: '2026-01-05'
next: TODO - definire next step.
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/datalake|datalake]] > 

# ETL/ELT – [nome-pipeline]
Breadcrumb: Home / Datalake / Pipelines / [nome-pipeline]

Scopo
- Cosa fa la pipeline? Per quale dominio? Chi ne è owner?

Prerequisiti
- Datalake structure/ACL/retention allineati (vedi playbook).
- Credenziali sorgente sicure (Key Vault / Variable Group).

Sorgente
- Tipo: API/CSV/DB/Altro
- Endpoint/Connessione: …
- Autenticazione: …
- Frequenza: oraria/giornaliera/settimanale

Naming & Partizionamento
- file: `dataset-<tenant>-<yyyyMMddHHmm>.csv`
- path: `landing/<tenant>/yyyy=YYYY/mm=MM/dd=DD/`

Schema & Mapping
- Tabella (colonna, tipo, null, default, note)
- Trasformazioni/derivazioni

Data Quality (DQ)
- Regole minime: chiavi, formati, range, domini
- Esito: `OK/BLOCKED`; scarti → `invalidrows/` (con motivazione)

Flusso (sintesi)
- landing → staging (arricchimento, DQ) → invalidrows/official → SQL (BRONZE/SILVER/GOLD)

Schedule & Orchestrazione
- Finestra: cron/ADF/Databricks/Airflow
- Dipendenze: …

Monitoraggio & Fallback
- Metriche: throughput, latenze, scarti
- Allarmi: soglie + canali
- Fallback: retry/backoff, reprocess window

Audit & Logging
- `portal-audit/etl-execution-logs/...`
- Correlazione: job id, tenant, dataset, finestra

Output & Contratti a Valle
- Tabella/dataset target, SLAs, schema

Allineamento Agentico
- Intents: `dlk-ensure-structure`, `dlk-apply-acl`, `dlk-set-retention`
- Output Contract: JSON con summary

Quick Checklist
- [ ] Sorgente/autenticazione definite
- [ ] Naming/partizioni conformi
- [ ] Mapping e DQ documentati
- [ ] Retention/ACL allineati
- [ ] Schedule/allarmi configurati
- [ ] Audit/log attivi











