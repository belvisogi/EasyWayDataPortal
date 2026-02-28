from __future__ import annotations

from typing import Optional, Dict, Any

from airflow.providers.databricks.operators.databricks import DatabricksRunNowOperator


def databricks_run_now_task(
    task_id: str,
    job_id: int,
    notebook_params: Optional[Dict[str, Any]] = None,
    databricks_conn_id: str = "databricks_default",
    dag=None,
) -> DatabricksRunNowOperator:
    return DatabricksRunNowOperator(
        task_id=task_id,
        job_id=job_id,
        notebook_params=notebook_params or {},
        databricks_conn_id=databricks_conn_id,
        dag=dag,
    )

