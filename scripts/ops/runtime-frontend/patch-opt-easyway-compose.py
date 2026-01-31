#!/usr/bin/env python3
import datetime
import os
import re
import shutil
import sys


def die(msg: str) -> None:
    print(f"[patch-compose] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


compose_path = "/opt/easyway/docker-compose.yml"
backup_dir = "/opt/easyway/var/backup"
runtime_root = "/opt/easyway/var/runtime/frontend"

if not os.path.exists(compose_path):
    die(f"compose file not found: {compose_path}")

ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
os.makedirs(backup_dir, exist_ok=True)
backup_path = os.path.join(backup_dir, f"docker-compose.yml.{ts}.bak")
shutil.copy2(compose_path, backup_path)
print(f"[patch-compose] backup={backup_path}")

text = open(compose_path, "r", encoding="utf-8").read()

# 1) Update Traefik router rules to include clean routes and runtime JSON endpoints.
public_rule = (
    "Path(`/`) || "
    "Path(`/demo`) || Path(`/manifesto`) || "
    "Path(`/demo.html`) || Path(`/manifesto.html`) || "
    "Path(`/branding.json`) || Path(`/config.js`) || "
    "Path(`/theme-packs.manifest.json`) || Path(`/assets.manifest.json`) || "
    "PathPrefix(`/pages`) || PathPrefix(`/content`) || PathPrefix(`/theme-packs`) || "
    "PathPrefix(`/assets`) || Path(`/vite.svg`) || Path(`/manifest.json`) || Path(`/robots.txt`) || Path(`/llms.txt`)"
)

private_rule = (
    "Path(`/memory`) || Path(`/memory.html`) || "
    "PathPrefix(`/dashboard`) || PathPrefix(`/app`)"
)

def replace_label_rule(s: str, label_key: str, new_rule: str) -> str:
    # Match the full quoted label line so we don't break YAML formatting.
    pattern = re.compile(rf'(^\\s*-\\s+\"{re.escape(label_key)}\\.rule=[^\"]*\"\\s*$)', re.MULTILINE)
    m = pattern.search(s)
    if not m:
        die(f"label rule not found: {label_key}.rule")
    indent = re.match(r'^(\\s*)-', m.group(1)).group(1)
    replaced = f'{indent}- \"{label_key}.rule={new_rule}\"'
    return s[: m.start(1)] + replaced + s[m.end(1) :]


text = replace_label_rule(text, "traefik.http.routers.frontend-public", public_rule)
text = replace_label_rule(text, "traefik.http.routers.frontend-private", private_rule)

# 2) Ensure runtime pack volumes are mounted into the frontend container.
# We insert after the existing config.js mount for deterministic location.
volume_block = "\n".join(
    [
        f"      - {runtime_root}/pages:/usr/share/nginx/html/pages:ro",
        f"      - {runtime_root}/content:/usr/share/nginx/html/content:ro",
        f"      - {runtime_root}/theme-packs.manifest.json:/usr/share/nginx/html/theme-packs.manifest.json:ro",
        f"      - {runtime_root}/assets.manifest.json:/usr/share/nginx/html/assets.manifest.json:ro",
        f"      - {runtime_root}/theme-packs:/usr/share/nginx/html/theme-packs:ro",
        f"      - {runtime_root}/assets/themes:/usr/share/nginx/html/assets/themes:ro",
    ]
)

if runtime_root not in text:
    # Find frontend volumes section (best-effort: anchored around the config.js mount).
    anchor = re.search(r'(^\\s*volumes:\\s*$\\n(?:^\\s*-\\s+.*\\n)+)', text, re.MULTILINE)
    if not anchor:
        die("could not locate a volumes: block to patch (expected under services.frontend)")

    # Insert after the config.js mount if present, else append at end of first volumes block.
    cfg_line = re.search(r'(^\\s*-\\s+\\./config\\.js:/usr/share/nginx/html/config\\.js:ro\\s*$)', text, re.MULTILINE)
    if cfg_line:
        insert_at = cfg_line.end(1)
        text = text[:insert_at] + "\n" + volume_block + text[insert_at:]
        print("[patch-compose] inserted runtime volumes after config.js mount")
    else:
        # Append at end of first volumes block.
        insert_at = anchor.end(1)
        text = text[:insert_at] + volume_block + "\n" + text[insert_at:]
        print("[patch-compose] appended runtime volumes to first volumes block")
else:
    print("[patch-compose] runtime volumes already present; skipping")

open(compose_path, "w", encoding="utf-8").write(text)
print("[patch-compose] OK patched compose file.")

