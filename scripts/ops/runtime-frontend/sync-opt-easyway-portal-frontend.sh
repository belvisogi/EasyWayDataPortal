#!/usr/bin/env bash
set -euo pipefail

# Sync the portal-frontend source code from the repo checkout into /opt/easyway/apps/portal-frontend.
# This keeps /opt/easyway build context aligned with the git repo (so containers rebuild from the new engine).

SRC_DEFAULT="$HOME/EasyWayDataPortal/apps/portal-frontend"
SRC="${1:-$SRC_DEFAULT}"
DST="/opt/easyway/apps/portal-frontend"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

echo "[sync-frontend-src] src=$SRC"
echo "[sync-frontend-src] dst=$DST"

if [[ ! -d "$SRC" ]]; then
  echo "[sync-frontend-src] ERROR: source folder not found: $SRC" >&2
  exit 1
fi

sudo mkdir -p "$DST"

# Backup current folder (metadata only; real rollback is via /opt/easyway/releases)
BK="/opt/easyway/var/backup/portal-frontend-src-$TS"
echo "[sync-frontend-src] backup=$BK"
sudo mkdir -p "$BK"
sudo rsync -a --delete --exclude 'node_modules' --exclude 'dist' "$DST/" "$BK/" || true

# Sync source (avoid copying node_modules/dist)
sudo rsync -a --delete \
  --exclude 'node_modules' \
  --exclude 'dist' \
  --exclude '.git' \
  "$SRC/" "$DST/"

sudo chown -R easyway:easyway-dev "$DST"
sudo chmod -R g+rwX "$DST"
sudo find "$DST" -type d -exec chmod 2775 {} +

echo "[sync-frontend-src] OK synced."

