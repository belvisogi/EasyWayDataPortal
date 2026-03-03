#!/usr/bin/env bash
# source-env.sh — Canonical environment loader for EasyWay bash scripts.
# Usage: source scripts/source-env.sh
#
# Exports standard aliases so that every script/curl command
# uses the same variable names without guessing.

ENV_FILE="${ENV_FILE:-/c/old/.env.local}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found" >&2
  return 1 2>/dev/null || exit 1
fi

# Load all variables from .env file
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  value="${value%\"}"
  value="${value#\"}"
  export "$key=$value"
done < "$ENV_FILE"

# Canonical aliases (what scripts expect)
export PAT="${ADO_PR_CREATOR_PAT:-$AZURE_DEVOPS_EXT_PAT}"
export B64=$(printf ":%s" "$PAT" | base64 -w0 2>/dev/null || printf ":%s" "$PAT" | base64)

# ADO constants
export ADO_ORG="https://dev.azure.com/EasyWayData"
export ADO_PROJECT="EasyWay-DataPortal"
export ADO_REPO="EasyWayDataPortal"
export ADO_API_BASE="$ADO_ORG/$ADO_PROJECT/_apis"
export ADO_REPO_API="$ADO_API_BASE/git/repositories/$ADO_REPO"

# Auth header helper — usage: curl "${ADO_AUTH[@]}" ...
export ADO_AUTH_HEADER="Authorization: Basic $B64"
