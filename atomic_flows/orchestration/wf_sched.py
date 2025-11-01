from __future__ import annotations

import io
from datetime import datetime

import yaml
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.utils.dates import days_ago
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook


default_args = {
    "owner": "data-platform",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
}


def _build_wf_all_config(execution_date: str) -> dict:
    # Example config; customize how you scan landing, etc.
    # You can discover prefixes dynamically and inject here.
    return {
        "landing": {
            "container": "landing-container",
            "prefix": "landing/path/",
            "poke_interval": 60,
            "timeout": 60 * 30,
        },
        "children": {
            "lnd_to_dq": {"dag_id": "lnd_to_dq_template", "conf": {"batch_date": execution_date}},
            "dq_to_stg": {"dag_id": "dq_to_stg_template", "conf": {"batch_date": execution_date}},
            "stg_to_ref": {"dag_id": "stg_to_ref_template", "conf": {"batch_date": execution_date}},
        },
    }


def _upload_yaml(container: str, blob_path: str, data: dict) -> str:
    hook = WasbHook()
    client = hook.get_conn()
    blob_client = client.get_blob_client(container=container, blob=blob_path)
    buf = io.BytesIO(yaml.safe_dump(data, sort_keys=False).encode("utf-8"))
    blob_client.upload_blob(buf.getvalue(), overwrite=True)
    return f"wasb://{container}/{blob_path}"


with DAG(
    dag_id="wf_sched_template",
    description="Scheduler/Scanner that builds wf_all YAML and triggers wf_all",
    schedule_interval=None,
    catchup=False,
    start_date=days_ago(1),
    default_args=default_args,
) as dag:
    def _produce_and_upload_config(**context):
        ds = context["ds"]
        ts = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        config = _build_wf_all_config(ds)
        # where to store config
        container = "orchestration-configs"
        blob_path = f"wf_all/config_{ds}_{ts}.yaml"
        return _upload_yaml(container, blob_path, config)

    produce_config = PythonOperator(
        task_id="produce_config",
        python_callable=_produce_and_upload_config,
        do_xcom_push=True,
    )

    run_wf_all = TriggerDagRunOperator(
        task_id="run_wf_all",
        trigger_dag_id="wf_all_template",
        conf={"config_uri": "{{ ti.xcom_pull(task_ids='produce_config') }}"},
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        failed_states=["failed"],
    )

    produce_config >> run_wf_all

