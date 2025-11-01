Atomic Flows (Azure-first, product-agnostic)

Overview
- Package: `atomic_flows` — DAG template e utilità atomiche per orchestrare landing→DQ→STG→REF su Azure (Blob, Azure SQL, Databricks opzionale).
- Agent-first: pensato per essere pilotato da un agente che genera la configurazione YAML, valida e lancia i workflow.

Structure
- `templates/` — DAG figli atomici: `dag_lnd_to_dq.py`, `dag_dq_to_stg.py`, `dag_stg_to_ref.py`.
- `orchestration/` — DAG padre e scheduler: `wf_all.py` (legge YAML), `wf_sched.py` (genera YAML e lancia `wf_all`).
- `common/` — operator/sensor utils per Blob/MSSQL/Databricks/Log/Config.

Connections (Airflow)
- `wasb_default` (Azure Blob/ADLS), `mssql_default` (Azure SQL), `databricks_default` (opzionale), SMTP/Email.

wf_all Config (YAML)
- Vedi `atomic_flows/orchestration/wf_all.config.sample.yaml`.
- Passare a `wf_all` via `dag_run.conf`: `{ "config_uri": "wasb://<container>/<blob>.yaml" }` oppure path locale.

Quickstart
- Deploy i DAG di `atomic_flows` in Airflow.
- Esegui `wf_sched` (o crea e carica lo YAML in Blob) per lanciare `wf_all`.
- Personalizza gli step SQL/SP nei DAG figli e i container/prefix in YAML.

Best Practice EasyWayDataPortal
- GitOps: YAML e codice nel repo, nessun dato sensibile in chiaro, segreti via Connections/Key Vault.
- ARGOS DQ/Alerting: standardizza outcome PASS/DEFER/FAIL, invio eventi/alert (vedi Wiki).
- Audit: log esecuzione centralizzato (SQL/Blob) e payload eventi `argos.run.completed`.
