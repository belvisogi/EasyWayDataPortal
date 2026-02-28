from __future__ import annotations

from pathlib import Path
from typing import Optional, Mapping, Any

from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator


def mssql_query_task(
    task_id: str,
    sql: str,
    mssql_conn_id: str = "mssql_default",
    parameters: Optional[Mapping[str, Any]] = None,
    autocommit: bool = True,
    dag=None,
) -> MsSqlOperator:
    return MsSqlOperator(
        task_id=task_id,
        mssql_conn_id=mssql_conn_id,
        sql=sql,
        parameters=parameters,
        autocommit=autocommit,
        dag=dag,
    )


def mssql_query_file_task(
    task_id: str,
    sql_path: str,
    mssql_conn_id: str = "mssql_default",
    parameters: Optional[Mapping[str, Any]] = None,
    autocommit: bool = True,
    dag=None,
) -> MsSqlOperator:
    sql_text = Path(sql_path).read_text(encoding="utf-8")
    return mssql_query_task(
        task_id=task_id,
        sql=sql_text,
        mssql_conn_id=mssql_conn_id,
        parameters=parameters,
        autocommit=autocommit,
        dag=dag,
    )

