from __future__ import annotations

from typing import Dict, Any, List
from urllib.parse import urlparse

import yaml
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook


def _load_local(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def _load_wasb(uri: str) -> Dict[str, Any]:
    # accepted: wasb://<container>/<blob_path>
    parsed = urlparse(uri)
    container = parsed.netloc or parsed.path.split("/", 1)[0]
    # support both wasb://container/blob and wasb:///container/blob
    if parsed.netloc:
        blob_path = parsed.path.lstrip("/")
    else:
        # wasb:///container/blob
        parts = parsed.path.lstrip("/").split("/", 1)
        container = parts[0]
        blob_path = parts[1] if len(parts) > 1 else ""

    hook = WasbHook()
    client = hook.get_conn()
    blob_client = client.get_blob_client(container=container, blob=blob_path)
    content = blob_client.download_blob().readall().decode("utf-8")
    return yaml.safe_load(content)


def load_config_from_uri(config_uri: str) -> Dict[str, Any]:
    if not config_uri:
        raise ValueError("config_uri is required in dag_run.conf")

    if config_uri.startswith("wasb://") or config_uri.startswith("wasbs://"):
        return _load_wasb(config_uri)
    # treat everything else as local path
    return _load_local(config_uri)


def validate_config(cfg: Dict[str, Any]) -> Dict[str, Any]:
    """
    Minimal validator: enforce small, pointer-style YAML.
    Required:
      - landing: { container:str, prefix:str, poke_interval?:int, timeout?:int }
      - children: { lnd_to_dq, dq_to_stg, stg_to_ref } each with { dag_id:str, conf:dict }
    Optional:
      - options: { notify_to?:list[str], log_table?:str, procedures?:{dq_check?,stg_load?,ref_merge?} }
    """
    errors: List[str] = []

    landing = cfg.get("landing")
    if not isinstance(landing, dict):
        errors.append("landing must be a dict")
    else:
        if not isinstance(landing.get("container"), str) or not landing.get("container"):
            errors.append("landing.container is required (str)")
        if not isinstance(landing.get("prefix"), str) or not landing.get("prefix"):
            errors.append("landing.prefix is required (str)")
        for k in ("poke_interval", "timeout"):
            if k in landing and not isinstance(landing[k], int):
                errors.append(f"landing.{k} must be int if provided")

    children = cfg.get("children")
    if not isinstance(children, dict):
        errors.append("children must be a dict")
    else:
        for key in ("lnd_to_dq", "dq_to_stg", "stg_to_ref"):
            item = children.get(key)
            if not isinstance(item, dict):
                errors.append(f"children.{key} must be a dict")
                continue
            if not isinstance(item.get("dag_id"), str) or not item.get("dag_id"):
                errors.append(f"children.{key}.dag_id is required (str)")
            if "conf" in item and not isinstance(item["conf"], dict):
                errors.append(f"children.{key}.conf must be a dict if provided")

    options = cfg.get("options")
    if options is not None and not isinstance(options, dict):
        errors.append("options must be a dict if provided")
    else:
        if options:
            if "notify_to" in options and not isinstance(options["notify_to"], list):
                errors.append("options.notify_to must be a list of emails")
            if "log_table" in options and not isinstance(options["log_table"], str):
                errors.append("options.log_table must be a string")
            if "procedures" in options and not isinstance(options["procedures"], dict):
                errors.append("options.procedures must be a dict")

    if errors:
        raise ValueError("Invalid wf_all config: " + "; ".join(errors))

    return cfg
