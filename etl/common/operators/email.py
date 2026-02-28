from __future__ import annotations

from typing import Sequence, Optional

from airflow.operators.email import EmailOperator


def email_notify_task(
    task_id: str,
    to: Sequence[str],
    subject: str,
    html_content: str,
    cc: Optional[Sequence[str]] = None,
    bcc: Optional[Sequence[str]] = None,
    dag=None,
) -> EmailOperator:
    return EmailOperator(
        task_id=task_id,
        to=list(to),
        subject=subject,
        html_content=html_content,
        cc=list(cc) if cc else None,
        bcc=list(bcc) if bcc else None,
        dag=dag,
    )

