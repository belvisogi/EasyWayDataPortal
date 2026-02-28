from __future__ import annotations

from typing import Mapping, Any

from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator


def mssql_log_row_task(
    task_id: str,
    table: str,
    row: Mapping[str, Any],
    mssql_conn_id: str = "mssql_default",
    dag=None,
) -> MsSqlOperator:
    cols = ", ".join(f"[{c}]" for c in row.keys())
    vals = ", ".join(
        [
            f"'{str(v).replace("'", "''")}'" if v is not None else "NULL"
            for v in row.values()
        ]
    )
    sql = f"INSERT INTO {table} ({cols}) VALUES ({vals});"
    return MsSqlOperator(task_id=task_id, mssql_conn_id=mssql_conn_id, sql=sql, dag=dag)

