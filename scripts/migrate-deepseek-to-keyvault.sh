#!/bin/bash
# migrate-deepseek-to-keyvault.sh
# Bash wrapper for running on the Ubuntu server
#
# Usage:
#   chmod +x scripts/migrate-deepseek-to-keyvault.sh
#   ./scripts/migrate-deepseek-to-keyvault.sh [--dry-run]

set -e

VAULT_NAME="easyway-vault"
SECRET_NAME="deepseek--api--key"
DRY_RUN=false

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
fi

echo "========================================"
echo " DeepSeek API Key -> Key Vault Migration"
echo " Vault:  $VAULT_NAME"
echo " Secret: $SECRET_NAME"
echo " Mode:   $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"
echo "========================================"

# Step 1: Check az CLI
echo "[1/4] Checking Azure CLI..."
if ! command -v az &> /dev/null; then
    echo "ERROR: Azure CLI not installed. Install with: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

az account show > /dev/null 2>&1 || { echo "ERROR: Not logged in. Run 'az login'"; exit 1; }
echo "  OK: $(az account show --query user.name -o tsv)"

# Step 2: Get current key
echo "[2/4] Reading DEEPSEEK_API_KEY..."
if [ -z "$DEEPSEEK_API_KEY" ]; then
    # Try sourcing from bashrc
    source ~/.bashrc 2>/dev/null || true
fi

if [ -z "$DEEPSEEK_API_KEY" ]; then
    # Try grep from bashrc
    DEEPSEEK_API_KEY=$(grep -oP 'export DEEPSEEK_API_KEY=\K[^\s"]+' ~/.bashrc 2>/dev/null | tr -d "'\"")
fi

if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "ERROR: DEEPSEEK_API_KEY not found"
    exit 1
fi

MASKED="${DEEPSEEK_API_KEY:0:5}...${DEEPSEEK_API_KEY: -4}"
echo "  Found: $MASKED"

# Step 3: Store in Key Vault
echo "[3/4] Storing in Key Vault..."
if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would store '$SECRET_NAME' in '$VAULT_NAME'"
else
    az keyvault secret set \
        --vault-name "$VAULT_NAME" \
        --name "$SECRET_NAME" \
        --value "$DEEPSEEK_API_KEY" \
        --tags "owner=team-platform" "scope=production" "component=deepseek" "rotate-by=2026-08-01" \
        --output none

    echo "  Secret stored (value NOT logged)"
fi

# Step 4: Instructions
echo ""
echo "[4/4] Post-migration (MANUAL):"
echo ""
echo "  1. Remove from bashrc:"
echo "     sed -i '/DEEPSEEK_API_KEY/d' ~/.bashrc"
echo ""
echo "  2. Add to .env.prod:"
echo "     DEEPSEEK_API_KEY=\$(az keyvault secret show --vault-name $VAULT_NAME --name $SECRET_NAME --query value -o tsv)"
echo ""
echo "  3. For runtime, create /opt/easyway/load-secrets.sh:"
echo "     export DEEPSEEK_API_KEY=\$(az keyvault secret show --vault-name $VAULT_NAME --name $SECRET_NAME --query value -o tsv)"
echo ""
echo "  4. Restart: docker compose restart agent-runner"
echo ""
echo "========================================"
echo " Done"
echo "========================================"
