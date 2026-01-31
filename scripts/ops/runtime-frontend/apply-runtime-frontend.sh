#!/usr/bin/env bash
set -euo pipefail

# One-shot apply:
# - Pull latest repo (optional: do it outside)
# - Sync frontend engine into /opt/easyway/apps/portal-frontend
# - Install runtime pack into /opt/easyway/var/runtime/frontend
# - Patch /opt/easyway/docker-compose.yml (traefik routes + volume mounts)
# - Rebuild + restart frontend

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[apply] syncing frontend engine..."
bash "$SCRIPT_DIR/sync-opt-easyway-portal-frontend.sh"

echo "[apply] installing runtime pack..."
bash "$SCRIPT_DIR/install-runtime-pack.sh"

echo "[apply] patching /opt/easyway/docker-compose.yml ..."
sudo python3 "$SCRIPT_DIR/patch-opt-easyway-compose.py"

echo "[apply] rebuilding frontend..."
cd /opt/easyway
sudo docker compose up -d --build frontend

echo "[apply] done."
sudo docker compose ps

