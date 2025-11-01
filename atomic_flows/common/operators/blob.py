from __future__ import annotations

from typing import List

from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook


def _list_with_prefix(container: str, prefix: str) -> List[str]:
    hook = WasbHook()
    client = hook.get_conn()
    container_client = client.get_container_client(container)
    return [b.name for b in container_client.list_blobs(name_starts_with=prefix)]


def _copy_blobs(
    source_container: str,
    source_blobs: List[str],
    destination_container: str,
    destination_prefix: str,
    delete_source: bool = False,
) -> List[str]:
    hook = WasbHook()
    client = hook.get_conn()
    src_container_client = client.get_container_client(source_container)
    dst_container_client = client.get_container_client(destination_container)

    results: List[str] = []
    for blob_name in source_blobs:
        src_blob = src_container_client.get_blob_client(blob_name)
        data = src_blob.download_blob().readall()
        dest_name = f"{destination_prefix}{blob_name.rsplit('/', 1)[-1]}"
        dst_blob = dst_container_client.get_blob_client(dest_name)
        dst_blob.upload_blob(data, overwrite=True)
        if delete_source:
            src_blob.delete_blob()
        results.append(dest_name)
    return results


def blob_move_or_copy_task(
    task_id: str,
    source_container: str,
    source_blobs: List[str],
    destination_container: str,
    destination_prefix: str,
    move: bool = False,
    dag=None,
):
    return PythonOperator(
        task_id=task_id,
        dag=dag,
        python_callable=_copy_blobs,
        op_kwargs=dict(
            source_container=source_container,
            source_blobs=source_blobs,
            destination_container=destination_container,
            destination_prefix=destination_prefix,
            delete_source=move,
        ),
    )


def blob_prefix_copy_task(
    task_id: str,
    source_container: str,
    source_prefix: str,
    destination_container: str,
    destination_prefix: str,
    move: bool = False,
    dag=None,
):
    def _resolve_and_copy(**_):
        blobs = _list_with_prefix(source_container, source_prefix)
        return _copy_blobs(
            source_container=source_container,
            source_blobs=blobs,
            destination_container=destination_container,
            destination_prefix=destination_prefix,
            delete_source=move,
        )

    return PythonOperator(task_id=task_id, dag=dag, python_callable=_resolve_and_copy)

