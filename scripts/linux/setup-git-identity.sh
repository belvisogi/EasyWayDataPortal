#!/bin/bash
# 🆔 Agent Identity Setup (Linux)
# Genera l'identità Git e le chiavi SSH per gli Agenti.

set -e

# Configurazione
GITLAB_HOST="80.225.86.168"
AGENT_NAME=${1:-"ew_developer"}
AGENT_EMAIL=${2:-"bots+developer@easyway.local"}
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_$AGENT_NAME"

echo "🤖 Setup Identità Agente: $AGENT_NAME"

# 1. Git Config Global
echo "📧 Configurazione Git Global..."
git config --global user.name "$AGENT_NAME"
git config --global user.email "$AGENT_EMAIL"
git config --global init.defaultBranch main
# Evita problemi con dubbi ownership nelle CI
git config --global --add safe.directory '*'

# 2. SSH Key Generation
if [ -f "$SSH_KEY_PATH" ]; then
    echo "🔑 Chiave SSH esistente: $SSH_KEY_PATH"
else
    echo "🔑 Generazione nuova chiave SSH (Ed25519)..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$AGENT_EMAIL" -f "$SSH_KEY_PATH" -N ""
fi

# 3. SSH Config (Alias)
# Permette di usare git@gitlab-agent:... invece di dover gestire host multipli
CONFIG_FILE="$HOME/.ssh/config"
if ! grep -q "Host $GITLAB_HOST" "$CONFIG_FILE" 2>/dev/null; then
    echo "🌐 Aggiunta configurazione SSH Host..."
    cat <<EOF >> "$CONFIG_FILE"

# Configurazione EasyWay GitLab
Host $GITLAB_HOST
  User git
  IdentityFile $SSH_KEY_PATH
  StrictHostKeyChecking no
EOF
    chmod 600 "$CONFIG_FILE"
fi

# 4. Output Pubblica per GitLab
echo ""
echo "==================================================="
echo "👉 COPIA QUESTA CHIAVE IN GITLAB:"
echo "   URL: http://$GITLAB_HOST/admin/users (Impersonate $AGENT_NAME -> SSH Keys)"
echo "==================================================="
echo ""
cat "$SSH_KEY_PATH.pub"
echo ""
echo "==================================================="
