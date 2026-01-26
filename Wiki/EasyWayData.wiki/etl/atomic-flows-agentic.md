---
title: Atomic Flows – Orchestrazione Agent‑First
tags: [domain/datalake, layer/spec, audience/dev, privacy/internal, language/it, etl, airflow, azure, agents]
status: active
updated: 2026-01-16
redaction: [email]
id: ew-atomic-flows-agentic
chunk_hint: 350-500
entities: []
include: true
summary: Standard EasyWay per workflow ETL atomici (landing→DQ→STG→REF) gestiti da agente, con YAML, DAG Airflow e integrazione ARGOS.
llm: 
pii: none
owner: team-data

llm:
  include: true
  chunk_hint: 5000---

[Home](../../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/datalake|datalake]] > [[Layer - Spec|Spec]]

# Atomic Flows – Orchestrazione Agent‑First

Scopo
- Definire un approccio atomico e riusabile per flussi ETL su Azure orchestrati da Airflow e gestiti da un agente.
- Standardizzare configurazione (YAML), naming, logging e integrazione con ARGOS (DQ/Alerting).

Architettura (sintesi)
- DAG padre `wf_all` legge uno YAML e orchestra i 3 figli: `lnd_to_dq` → `dq_to_stg` → `stg_to_ref`.
- DAG `wf_sched` (o “wf_scan”) genera lo YAML e triggera `wf_all`.
- Figli atomici: ognuno fa una sola cosa (waiting/copy/DQ, gate+load STG, merge REF).

Repository e Path
- Package: `atomic_flows` (codice nel repo EasyWayDataPortal)
  - `atomic_flows/templates/` – DAG figli atomici
  - `atomic_flows/orchestration/` – DAG padre e scheduler, esempio YAML `atomic_flows/orchestration/wf_all.config.sample.yaml`
  - `atomic_flows/common/` – operator/sensor/utils (Blob, MSSQL, Databricks, config)

Workflow YAML (wf_all)
- Caricato da Blob o filesystem; passato a `wf_all` via `dag_run.conf.config_uri`.
- Struttura minima:
  - `landing.container/prefix/poke_interval/timeout`
  - `children.{lnd_to_dq|dq_to_stg|stg_to_ref}.dag_id` e `conf` (es. `batch_date`)
- Vedi esempio: `atomic_flows/orchestration/wf_all.config.sample.yaml`

Ruolo dell’Agente
- Intents (proposta): `etl-spec:create`, `etl-spec:validate`, `etl:dry-run`, `etl:deploy`.
- Compiti:
  1) Generare/aggiornare YAML (con naming e path landing/dq/stg/ref coerenti).
  2) Validare (schema e connessioni), simulare (dry-run su un batch) e creare PR.
  3) Eseguire `wf_sched` o triggerare `wf_all` con `config_uri`.
  4) Registrare output (contract JSON), log e—se integrato—eventi ARGOS.

Best Practice EasyWay
- Scelte tecnologiche: vedere “ETL/ELT – Scelte Tecnologiche” (Airflow per orchestrazione; Databricks per trasformazioni; ADF opzionale ingestion semplice).
- ARGOS: esiti DQ PASS/DEFER/FAIL, payload standard, dedup/suppression e digest (vedi “ARGOS – Alerting & Notifications”).
- GitOps: YAML e DAG in repo; secrets via Connections/Key Vault; nessuna PII nei messaggi/eventi.

Linee Guida Naming & Logging
- DAG id: `{domain}_{flow}_{purpose}`; task id verbo_nome.
- Tabelle: `dq_*`, `stg_*`, `ref_*` con stored procedure dedicate.
- Log esecuzione: tabella SQL `dbo.etl_logs` (chiavi minime: dag_id, run_id, status, started_at, ended_at, rows_*, error_code).

Integrazione ARGOS (M1 – Gating)
- `lnd_to_dq` produce outcome DQ; mappare in PASS/DEFER/FAIL con `decision_trace_id`.
- Emissione eventi:
  - `argos.gate.decision` (per ogni gate principale)
  - `argos.run.completed` (per run aggregata) con correlazione.
- Alert: CRITICAL/WARN/INFO secondo mapping; rispetto quiet hours/digest.

Onboarding Nuovo Flusso (checklist)
1) Definisci landing/container/prefix e convenzioni batch.
2) Crea SP/SQL per DQ, load STG, merge REF.
3) Genera YAML wf_all e validalo (schema + connessioni).
4) PR con DAG parametrizzati e YAML; pipeline ADO valida e rilascia.
5) Esegui dry‑run; verifica log/eventi/alert.
6) Pianifica schedule e cost-guardrails (cluster Databricks auto‑terminate, orari orchestratore).

Appendice – Connessioni Airflow
- `wasb_default`, `mssql_default`, `databricks_default` (opzionale), SMTP.







## Vedi anche

- [ETL/ELT - Scelte Tecnologiche](../etl-elt-technology-choices.md)
- [ETL/ELT Template (Per-Pipeline)](../etl-elt-template.md)
- [ETL - Data Quality Framework](../etl-dq-framework.md)
- [ETL - Governance & SLA](../etl-governance-sla.md)
- [ARGOS - Alerting & Notifications (v1.1)](../argos/argos-alerting.md)
- [Agents Registry (owner, domini, intent)](../control-plane/agents-registry.md)
- [Agent - DQ Blueprint (Spec v0)](../agents/agent-dq-blueprint.md)





