---
id: ew-etl-elt-technology-choices
title: ETL/ELT – Scelte Tecnologiche
summary: Opzioni di orchestrazione/esecuzione (Airflow, Databricks, ADF) e linee guida di adozione in EasyWayDataPortal.
status: draft
owner: team-data
tags: [etl, datalake, domain/datalake, layer/spec, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
---

# ETL/ELT – Scelte Tecnologiche
Breadcrumb: Home / Datalake / ETL-ELT Technology

Obiettivo
- Descrivere alternative e criteri: quando usare Airflow/Databricks/ADF, con guardrail di costo/governance.

Alternative (sintesi)
- Airflow (managed): orchestrazione DAG, integrazione ampia, plugin
- Databricks: trasformazioni/ELT scalabili, notebooks, job clusters
- ADF: ingestion/copy “drag&drop”, connettori gestiti, mapping data flows

Criteri di scelta
- Complessità pipeline, skill team, SLA/volumi, costi e governance

Guardrail comuni
- GitOps (spec/template/codice)
- WhatIf/dry-run dove possibile
- Audit/log e retry policy
- Secrets in Key Vault/Variable Groups

Riferimenti
- ETL/ELT Playbook
- Datalake Ensure/ACL/Retention

## Decisioni Minime (provvisorie)
- Ambiente sviluppo (dev):
  - Orchestrazione: Managed Airflow (Small), accensione in fascia oraria (es. 7–19) per contenere i costi.
  - Esecuzione trasformazioni: Databricks job cluster piccolo con auto-terminate (15').
  - Ingestion semplice (copy CSV/Blob→ADLS/SQL): ADF opzionale per connettori nativi, oppure Airflow+adattatore.
- Ambienti test/prod:
  - Taglie adeguate, HA per orchestratore, alerting e backup abilitati.
  - Policy di costo: autoscaling, no all-purpose cluster, spegnimento notturno dove possibile.

## Quando usare cosa (regola pratica)
- Solo copy/ingestion standard, poca logica: ADF (attività Copy / Mapping Data Flow).
- Orchestrazione multi-step, dipendenze e integrazioni eterogenee: Airflow.
- Trasformazioni dati compute-intensive o notebook-driven (ELT su lakehouse): Databricks.

## Mappatura agentica (prossimi step)
- Intent pipeline (spec): `etl-spec:create`, `etl-spec:validate`, `etl:dry-run`, `etl:deploy` (stub).
- Logging comune: `portal-audit/etl-execution-logs/` con chiavi minime (workflow_key, status, started_at, ended_at, rows_*).
- Ogni azione agente produce Output Contract (JSON) con `summary` + `changesPreview` (WhatIf) o `stateAfter` (apply).





