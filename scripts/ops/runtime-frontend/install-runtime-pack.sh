#!/usr/bin/env bash
set -euo pipefail

# Install/update the frontend runtime pack (pages/content/themes/assets) on the server.
# Source: the repo checkout on the server (~/EasyWayDataPortal)
# Target: /opt/easyway/var/runtime/frontend

SRC_DEFAULT="$HOME/EasyWayDataPortal/apps/portal-frontend/public"
SRC="${1:-$SRC_DEFAULT}"
DST="/opt/easyway/var/runtime/frontend"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

echo "[runtime-pack] src=$SRC"
echo "[runtime-pack] dst=$DST"

if [[ ! -d "$SRC" ]]; then
  echo "[runtime-pack] ERROR: source folder not found: $SRC" >&2
  exit 1
fi

sudo mkdir -p "$DST"

# Backup existing pack if non-empty
if [[ -d "$DST" ]] && [[ "$(find "$DST" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)" -gt 0 ]]; then
  B="/opt/easyway/var/backup/runtime-frontend-$TS"
  echo "[runtime-pack] backup=$B"
  sudo mkdir -p "$B"
  sudo rsync -a "$DST/" "$B/"
fi

# Sync folders (delete drift)
sudo mkdir -p "$DST/pages" "$DST/content" "$DST/theme-packs" "$DST/assets/themes"
sudo rsync -a --delete "$SRC/pages/" "$DST/pages/"
sudo rsync -a --delete "$SRC/content/" "$DST/content/"
sudo rsync -a --delete "$SRC/theme-packs/" "$DST/theme-packs/"
sudo rsync -a --delete "$SRC/assets/themes/" "$DST/assets/themes/"

# Sync manifest files (flat)
sudo rsync -a "$SRC/theme-packs.manifest.json" "$DST/theme-packs.manifest.json"
sudo rsync -a "$SRC/assets.manifest.json" "$DST/assets.manifest.json"

# Permissions: align with /opt/easyway conventions
OWNER="easyway"
GROUP="easyway-dev"
sudo chown -R "$OWNER:$GROUP" "$DST"
sudo chmod -R g+rwX "$DST"
sudo find "$DST" -type d -exec chmod 2775 {} +

echo "[runtime-pack] OK installed."

