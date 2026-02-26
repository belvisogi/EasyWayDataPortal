#!/bin/bash
# wiki-auto-ingest.sh — Auto Qdrant re-ingest when Wiki content changes
#
# Detects new commits in Wiki/ vs the last known ingested SHA and triggers
# a full re-index only when necessary. State is persisted in:
#   portal-api/data/ingest-state.json
#
# CRONTAB SETUP (run as ubuntu on server):
#   crontab -e
#   # Run every hour:
#   0 * * * * /home/ubuntu/EasyWayDataPortal/scripts/linux/wiki-auto-ingest.sh >> /tmp/wiki-auto-ingest.log 2>&1
#
# ENVIRONMENT:
#   REPO_DIR  — repo root (default: /home/ubuntu/EasyWayDataPortal)

REPO_DIR="${REPO_DIR:-/home/ubuntu/EasyWayDataPortal}"
STATE_FILE="$REPO_DIR/portal-api/data/ingest-state.json"
WIKI_PATH="$REPO_DIR/Wiki"
SCRIPTS_DIR="$REPO_DIR/scripts"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

echo "[$(ts)] wiki-auto-ingest: starting"

# --- Load secrets ---
if [ ! -f /opt/easyway/.env.secrets ]; then
  echo "[$(ts)] ERROR: /opt/easyway/.env.secrets not found — abort"
  exit 1
fi
# shellcheck disable=SC1091
source /opt/easyway/.env.secrets

# --- Fetch latest remote refs (silent) ---
cd "$REPO_DIR" || { echo "[$(ts)] ERROR: Cannot cd to $REPO_DIR"; exit 1; }
git fetch origin main --quiet 2>/dev/null || echo "[$(ts)] WARN: git fetch failed (network?)"

# --- Get latest commit SHA for Wiki/ on origin/main ---
CURRENT_SHA=$(git log origin/main --format="%H" -1 -- Wiki/ 2>/dev/null)
if [ -z "$CURRENT_SHA" ]; then
  echo "[$(ts)] No commits found for Wiki/. Skipping."
  exit 0
fi

# --- Read last ingested SHA from state file ---
LAST_SHA=""
if [ -f "$STATE_FILE" ]; then
  LAST_SHA=$(python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_FILE'))
    print(d.get('lastCommitSha',''))
except Exception as e:
    print('', file=sys.stderr)
    print('')
" 2>/dev/null || echo "")
fi

# --- Compare ---
if [ "$CURRENT_SHA" = "$LAST_SHA" ]; then
  echo "[$(ts)] No new Wiki commits (${CURRENT_SHA:0:8}). Nothing to do."
  exit 0
fi

echo "[$(ts)] Wiki changed: ${LAST_SHA:0:8}→${CURRENT_SHA:0:8}"

# --- Pull latest code ---
git pull --ff-only origin main --quiet 2>/dev/null \
  || echo "[$(ts)] WARN: git pull failed — running ingest with current local state"

# --- Run ingest ---
echo "[$(ts)] Starting ingest_wiki.js (WIKI_PATH=$WIKI_PATH)..."
QDRANT_API_KEY="$QDRANT_API_KEY" WIKI_PATH="$WIKI_PATH" node "$SCRIPTS_DIR/ingest_wiki.js"
INGEST_STATUS=$?

# --- Update state file ---
RUN_AT=$(ts)
if [ $INGEST_STATUS -eq 0 ]; then
  python3 -c "
import json
data = {
  'lastCommitSha': '$CURRENT_SHA',
  'lastRunAt': '$RUN_AT',
  'status': 'success'
}
with open('$STATE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
  echo "[$(ts)] Ingest SUCCESS — state saved (SHA: ${CURRENT_SHA:0:8})"
else
  python3 -c "
import json
data = {}
try:
    with open('$STATE_FILE') as f:
        data = json.load(f)
except Exception:
    pass
data['lastRunAt'] = '$RUN_AT'
data['status'] = 'failed'
with open('$STATE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
  echo "[$(ts)] Ingest FAILED (exit $INGEST_STATUS)"
  exit $INGEST_STATUS
fi
