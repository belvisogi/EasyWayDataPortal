from __future__ import annotations

from airflow.providers.microsoft.azure.sensors.wasb import WasbPrefixSensor


def blob_prefix_sensor(
    task_id: str,
    container_name: str,
    prefix: str,
    wasb_conn_id: str = "wasb_default",
    poke_interval: int = 60,
    timeout: int = 60 * 60,
    soft_fail: bool = False,
    mode: str = "poke",
    dag=None,
):
    return WasbPrefixSensor(
        task_id=task_id,
        dag=dag,
        container_name=container_name,
        prefix=prefix,
        wasb_conn_id=wasb_conn_id,
        poke_interval=poke_interval,
        timeout=timeout,
        soft_fail=soft_fail,
        mode=mode,
    )

