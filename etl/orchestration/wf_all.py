from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.operators.python import PythonOperator

from atomic_flows.common.sensors import blob_prefix_sensor
from atomic_flows.common.utils.config import load_config_from_uri, validate_config
from atomic_flows.common.callbacks import on_dag_success, on_dag_failure


default_args = {
    "owner": "data-platform",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
}


with DAG(
    dag_id="wf_all_template",
    description=(
        "Parent workflow orchestrator: wait landing, then run lnd_to_dq -> dq_to_stg -> stg_to_ref"
    ),
    schedule_interval=None,
    catchup=False,
    start_date=days_ago(1),
    default_args={**default_args, "on_success_callback": on_dag_success, "on_failure_callback": on_dag_failure},
) as dag:
    # 0) Load configuration produced by wf_sched/wf_scan (supports wasb:// or local file path)
    load_config = PythonOperator(
        task_id="load_config",
        python_callable=load_config_from_uri,
        op_kwargs=dict(config_uri="{{ dag_run.conf.get('config_uri') }}"),
        do_xcom_push=True,
    )

    def _validate_and_pass(ti, **_):
        cfg = ti.xcom_pull(task_ids="load_config")
        validate_config(cfg)
        return cfg

    validate = PythonOperator(
        task_id="validate_config",
        python_callable=_validate_and_pass,
        do_xcom_push=True,
    )

    # 1) Wait for landing files (parametric)
    wait_landing = blob_prefix_sensor(
        task_id="wait_landing",
        container_name="{{ ti.xcom_pull(task_ids='validate_config')['landing']['container'] }}",
        prefix="{{ ti.xcom_pull(task_ids='validate_config')['landing']['prefix'] }}",
        poke_interval={{ ti.xcom_pull(task_ids='validate_config')['landing'].get('poke_interval', 60) }},
        timeout={{ ti.xcom_pull(task_ids='validate_config')['landing'].get('timeout', 60 * 30) }},
    )

    # 2) Trigger child: lnd_to_dq and wait for completion (parametric conf)
    run_lnd_to_dq = TriggerDagRunOperator(
        task_id="run_lnd_to_dq",
        trigger_dag_id="{{ ti.xcom_pull(task_ids='validate_config')['children']['lnd_to_dq']['dag_id'] }}",
        conf={"batch_date": "{{ ds }}"},
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        failed_states=["failed"],
    )

    # 3) Trigger child: dq_to_stg and wait for completion
    run_dq_to_stg = TriggerDagRunOperator(
        task_id="run_dq_to_stg",
        trigger_dag_id="{{ ti.xcom_pull(task_ids='validate_config')['children']['dq_to_stg']['dag_id'] }}",
        conf={"batch_date": "{{ ds }}"},
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        failed_states=["failed"],
    )

    # 4) Trigger child: stg_to_ref and wait for completion
    run_stg_to_ref = TriggerDagRunOperator(
        task_id="run_stg_to_ref",
        trigger_dag_id="{{ ti.xcom_pull(task_ids='validate_config')['children']['stg_to_ref']['dag_id'] }}",
        conf={"batch_date": "{{ ds }}"},
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        failed_states=["failed"],
    )

    load_config >> validate >> wait_landing >> run_lnd_to_dq >> run_dq_to_stg >> run_stg_to_ref
