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
    dag_id="stg_to_ref_template",
    description="STG to REF: merge/update reference tables from staging",
    schedule_interval=None,
    catchup=False,
    start_date=days_ago(1),
    default_args=default_args,
) as dag:
    merge_ref = mssql_query_task(
        task_id="merge_ref",
        sql=(
            "-- Merge into reference from staging\n"
            "EXEC ref.usp_merge_from_stg @batch_date = '{{ ds }}';"
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

    merge_ref >> log_row >> notify
