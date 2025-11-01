from __future__ import annotations

import json
from datetime import datetime
from typing import Any, Dict, Optional

from airflow.utils.email import send_email
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook


def _build_run_event(context: Dict[str, Any], status: str) -> Dict[str, Any]:
    dag = context.get("dag")
    ti = context.get("task_instance")
    run_id = ti.run_id if ti else None
    dag_id = dag.dag_id if dag else None
    ts = context.get("ts") or datetime.utcnow().isoformat()
    conf = (context.get("dag_run") or {}).conf if context.get("dag_run") else {}
    decision_trace_id = conf.get("decision_trace_id")

    return {
        "event": "argos.run.completed",
        "producer": "atomic_flows.orchestrator",
        "dag_id": dag_id,
        "run_id": run_id,
        "status": status,
        "ts": ts,
        "decision_trace_id": decision_trace_id,
    }


def _insert_log_row_if_configured(context: Dict[str, Any], status: str) -> None:
    conf = (context.get("dag_run") or {}).conf if context.get("dag_run") else {}
    log_table = None
    # allow passing options via conf or via wf_all YAML merged into conf.options
    options = conf.get("options") or {}
    if isinstance(options, dict):
        log_table = options.get("log_table")
    if not log_table:
        return

    dag = context.get("dag")
    ti = context.get("task_instance")
    dag_id = dag.dag_id if dag else None
    run_id = ti.run_id if ti else None
    started_at = str(context.get("data_interval_start") or context.get("ts"))
    ended_at = datetime.utcnow().isoformat()

    sql = (
        f"INSERT INTO {log_table} (dag_id, run_id, status, started_at, ended_at) "
        f"VALUES ('{dag_id}','{run_id}','{status}','{started_at}','{ended_at}');"
    )
    try:
        MsSqlHook(mssql_conn_id="mssql_default").run(sql)
    except Exception as e:
        # Fallback to log only
        print(f"[atomic_flows] log insert failed: {e}")


def _notify_if_configured(context: Dict[str, Any], status: str) -> None:
    conf = (context.get("dag_run") or {}).conf if context.get("dag_run") else {}
    options = conf.get("options") or {}
    recipients = []
    if isinstance(options, dict):
        recipients = options.get("notify_to") or []
    if not recipients:
        return
    dag = context.get("dag")
    dag_id = dag.dag_id if dag else None
    ts = context.get("ts") or datetime.utcnow().isoformat()
    subject = f"[{status}] {dag_id}"
    html = f"<p>DAG {dag_id} status={status} at {ts}</p>" \
           f"<pre>{json.dumps(_build_run_event(context, status), indent=2)}</pre>"
    try:
        send_email(to=recipients, subject=subject, html_content=html)
    except Exception as e:
        print(f"[atomic_flows] email send failed: {e}")


def on_dag_success(context: Dict[str, Any]) -> None:
    status = "success"
    print(json.dumps(_build_run_event(context, status)))
    _insert_log_row_if_configured(context, status)
    _notify_if_configured(context, status)


def on_dag_failure(context: Dict[str, Any]) -> None:
    status = "failed"
    print(json.dumps(_build_run_event(context, status)))
    _insert_log_row_if_configured(context, status)
    _notify_if_configured(context, status)

