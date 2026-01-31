#!/usr/bin/env python3
import datetime
import os
import re
import shutil
import subprocess
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

# Work only inside the "frontend:" service block to avoid accidental edits elsewhere.
front_m = re.search(r"(?m)^  frontend:\n", text)
if not front_m:
    die("could not find services.frontend block")

next_m = re.search(r"(?m)^  n8n:\n", text[front_m.end() :])
if not next_m:
    die("could not find end of services.frontend block (expected 'n8n:' after it)")

front_start = front_m.start()
front_end = front_m.end() + next_m.start()
front_block = text[front_start:front_end]

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
    needle = f'{label_key}.rule='
    out_lines = []
    replaced = False

    for line in s.splitlines(True):
        if needle in line:
            m = re.match(r'^(\s*)-\s+"', line)
            if not m:
                die(f"label line for {label_key}.rule has unexpected format")
            indent = m.group(1)
            out_lines.append(f'{indent}- "{label_key}.rule={new_rule}"\n')
            replaced = True
        else:
            out_lines.append(line)

    if not replaced:
        die(f"label rule not found: {label_key}.rule")
    return "".join(out_lines)


front_block = replace_label_rule(front_block, "traefik.http.routers.frontend-public", public_rule)
front_block = replace_label_rule(front_block, "traefik.http.routers.frontend-private", private_rule)

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

if runtime_root in front_block:
    print("[patch-compose] runtime volumes already present; skipping")
else:
    # Locate the frontend volumes block and insert after config.js mount (or append).
    vols_m = re.search(r"(?m)^\s{4}volumes:\s*$", front_block)
    if not vols_m:
        die("could not locate services.frontend.volumes block")

    cfg_m = re.search(r"(?m)^\s{6}-\s+\./config\.js:/usr/share/nginx/html/config\.js:ro\s*$", front_block)
    if cfg_m:
        insert_at = cfg_m.end()
        front_block = front_block[:insert_at] + "\n" + volume_block + front_block[insert_at:]
        print("[patch-compose] inserted runtime volumes after config.js mount")
    else:
        # Append at end of volumes list (best-effort: after the last list item under volumes).
        last_item = None
        for m in re.finditer(r"(?m)^\s{6}-\s+.*$", front_block):
            last_item = m
        if not last_item:
            die("services.frontend.volumes has no list items to anchor insertion")
        insert_at = last_item.end()
        front_block = front_block[:insert_at] + "\n" + volume_block + front_block[insert_at:]
        print("[patch-compose] appended runtime volumes to services.frontend.volumes")

# Rebuild full text with patched frontend block.
text = text[:front_start] + front_block + text[front_end:]

open(compose_path, "w", encoding="utf-8").write(text)
print("[patch-compose] validating compose via docker compose config ...")

tmp_path = f"/tmp/docker-compose.patched.{ts}.yml"
open(tmp_path, "w", encoding="utf-8").write(text)

try:
    subprocess.run(
        ["docker", "compose", "-f", tmp_path, "config"],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
except Exception:
    # Restore backup on failure.
    shutil.copy2(backup_path, compose_path)
    die(f"patched compose is invalid; restored backup {backup_path}")
finally:
    try:
        os.remove(tmp_path)
    except OSError:
        pass

print("[patch-compose] OK patched compose file.")
