#!/bin/bash
set -e

# ==============================================================================
# 🚀 EasyWay Local Deployer
# ==============================================================================
# Questo script sposta il codice dalla "Cava" (Workspace utente) al "Tempio" (Runtime /opt).
# Usa Link Simbolici per garantire deploy atomici (Zero Downtime palese).
#
# USAGE: sudo ./scripts/ci/deploy-local.sh
# ==============================================================================

APP_NAME="easyway"
SOURCE_DIR="$(pwd)"
BASE_DEST_DIR="/opt/$APP_NAME"
RELEASES_DIR="$BASE_DEST_DIR/releases"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NEW_RELEASE_DIR="$RELEASES_DIR/$TIMESTAMP"
CURRENT_LINK="$BASE_DEST_DIR/current"

# Check Root
if [ "$EUID" -ne 0 ]; then
  echo "❌ ERRORE: Devi essere root/sudo per deployare in /opt."
  exit 1
fi

echo "🚀 Avvio Deploy Local..."
echo "   📍 Sorgente: $SOURCE_DIR"
echo "   🏁 Destinazione: $NEW_RELEASE_DIR"

# 0. Prerequisiti
if ! command -v rsync &> /dev/null; then
    echo "📦 Installazione rsync..."
    apt-get update -qq && apt-get install -y rsync -qq
fi

# 1. Crea Cartella Release
mkdir -p "$NEW_RELEASE_DIR"

# 2. Copia File (Escludendo spazzatura)
echo "📦 Copia file in corso..."
rsync -a \
    --exclude '.git' \
    --exclude 'node_modules' \
    --exclude 'tmp' \
    --exclude '.env' \
    "$SOURCE_DIR/" "$NEW_RELEASE_DIR/"

# 3. Copia config persistenti (se esistono in /opt/easyway/config)
# Se abbiamo file .env di produzione esterni al repo, li linkiamo
if [ -f "$BASE_DEST_DIR/config/.env" ]; then
    ln -sf "$BASE_DEST_DIR/config/.env" "$NEW_RELEASE_DIR/.env"
    echo "🔗 Linkato .env di produzione."
fi

# 4. Sistema Permessi
echo "🔒 Applicazione Permessi (easyway:easyway-dev)..."
chown -R easyway:easyway-dev "$NEW_RELEASE_DIR"
chmod -R 775 "$NEW_RELEASE_DIR"

# 5. Switch Atomico (Il Momento della Verità)
echo "🔄 Aggiornamento Symlink 'current'..."
ln -sfn "$NEW_RELEASE_DIR" "$CURRENT_LINK"

# 6. Cleanup Vecchie Release (Tieni ultime 5)
echo "🧹 Pulizia vecchie release..."
cd "$RELEASES_DIR"
ls -dt * | tail -n +6 | xargs -r rm -rf

echo "✅ DEPLOY COMPLETATO!"
echo "   La versione attiva è ora in: $CURRENT_LINK"
echo "   Per vedere i log: cd /opt/easyway/current"
