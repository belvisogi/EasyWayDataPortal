#!/bin/bash
set -e

# ==============================================================================
# 🔐 EasyWay Environment Setup
# ==============================================================================
# Questo script crea il file .env di produzione in /opt/easyway/config/.env
# Chiede all'utente le chiavi segrete (non le salva nello script!).
#
# USAGE: sudo ./scripts/infra/setup-env.sh
# ==============================================================================

CONFIG_DIR="/opt/easyway/config"
ENV_FILE="$CONFIG_DIR/.env"

# Check Root
if [ "$EUID" -ne 0 ]; then
  echo "❌ ERRORE: Devi essere root/sudo."
  exit 1
fi

echo "🔐 Configurazione Variabili d'Ambiente (Production)..."

mkdir -p "$CONFIG_DIR"

# Funzione per chiedere valore o usare default
ask_var() {
    local var_name=$1
    local prompt_text=$2
    local default_val=$3
    local current_val=""
    
    # Se il file esiste, cerca valore corrente
    if [ -f "$ENV_FILE" ]; then
        current_val=$(grep "^$var_name=" "$ENV_FILE" | cut -d'=' -f2-)
    fi

    # Se non c'è valore corrente, usa default
    if [ -z "$current_val" ]; then
        current_val="$default_val"
    fi

    echo -n "👉 $prompt_text [$current_val]: "
    read input_val

    if [ -z "$input_val" ]; then
        input_val="$current_val"
    fi

    echo "$var_name=$input_val"
}

# --- Raccolta Dati ---
echo ""
echo "🤖 API KEYS (Lascia vuoto per saltare)"
OPENAI_KEY=$(ask_var "OPENAI_API_KEY" "Inserisci OpenAI API Key" "")
DEEPSEEK_KEY=$(ask_var "DEEPSEEK_API_KEY" "Inserisci DeepSeek API Key" "")
ANTHROPIC_KEY=$(ask_var "ANTHROPIC_API_KEY" "Inserisci Anthropic API Key" "")

echo ""
echo "🗄️ DATABASE (SQL Server)"
SQL_PWD=$(ask_var "SQL_PASSWORD" "Inserisci Password SQL SA" "EasyWayStrongPassword1!")

# --- Scrittura File ---
echo ""
echo "💾 Salvataggio in $ENV_FILE..."

cat > "$ENV_FILE" <<EOF
# EasyWay Production Environment
# Generated on $(date)

EASYWAY_MODE=Production

# 🤖 AI Models
OPENAI_API_KEY=$OPENAI_KEY
DEEPSEEK_API_KEY=$DEEPSEEK_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_KEY

# 🗄️ Database
SQL_PASSWORD=$SQL_PWD
ACCEPT_EULA=Y

# 🌐 Network
PORT=80
EOF

# Permessi
chown easyway:easyway-dev "$ENV_FILE"
chmod 640 "$ENV_FILE" # Solo Proprietario RW, Gruppo R

echo "✅ File .env creato con successo!"
echo "   Puoi modificarlo manualmente con: sudo nano $ENV_FILE"
