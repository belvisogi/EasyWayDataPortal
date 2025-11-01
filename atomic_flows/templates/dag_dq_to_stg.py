from airflow import DAG
from airflow.utils.dates import days_ago

from atomic_flows.common.operators import mssql_query_task, email_notify_task
from atomic_flows.common.utils import mssql_log_row_task
from atomic_flows.common.callbacks import on_dag_success, on_dag_failure


default_args = {
    "owner": "data-platform",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "on_success_callback": on_dag_success,
    "on_failure_callback": on_dag_failure,
}


with DAG(
    dag_id="dq_to_stg_template",
    description="DQ to STG: gate on DQ results and load staging",
    schedule_interval=None,
    catchup=False,
    start_date=days_ago(1),
    default_args=default_args,
) as dag:
    dq_gate = mssql_query_task(
        task_id="dq_gate",
        sql=(
            "-- Raise error if DQ failed for the batch\n"
            "EXEC dq.usp_gate_batch @batch_date = '{{ ds }}';"
        ),
        mssql_conn_id="mssql_default",
    )

    load_stg = mssql_query_task(
        task_id="load_stg",
        sql=(
            "-- Load data from dq to stg\n"
            "EXEC stg.usp_load_from_dq @batch_date = '{{ ds }}';"
        ),
        mssql_conn_id="mssql_default",
    )

    log_row = mssql_log_row_task(
        task_id="log_row",
        table="dbo.etl_logs",
        row={
            "dag_id": "{{ dag.dag_id }}",
            "task_id": "{{ task_instance.task_id }}",
            "ts": "{{ ts }}",
            "status": "completed",
        },
    )

    notify = email_notify_task(
        task_id="notify",
        to=["data-team@example.org"],
        subject="{{ dag.dag_id }} completed",
        html_content="<p>DAG {{ dag.dag_id }} finished at {{ ts }}.</p>",
    )

    dq_gate >> load_stg >> log_row >> notify
