#!/bin/bash
set -e

# ==============================================================================
# 🐳 EasyWay Docker Installer
# ==============================================================================
# Installa Docker Engine e Docker Compose Plugin su Ubuntu (compatibile ARM64).
# Aggiunge gli utenti 'ubuntu' (sysadmin) e 'easyway' (service) al gruppo docker.
#
# USAGE: sudo ./scripts/infra/install-docker.sh
# ==============================================================================

# Check Root
if [ "$EUID" -ne 0 ]; then
  echo "❌ ERRORE: Devi essere root/sudo."
  exit 1
fi

echo "🐳 Avvio Installazione Docker..."

# 1. Rimuovi vecchi pacchetti (se presenti)
echo "🧹 Pulizia vecchie versioni..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    apt-get remove -y $pkg || true
done

# 2. Prerequisiti
echo "📦 Installazione prerequisiti..."
apt-get update -qq
apt-get install -y ca-certificates curl gnupg

# 3. Keyring Docker ufficiale
echo "🔑 Setup Docker GPG Key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Repo Setup (Auto-detect architecture: amd64/arm64)
echo "🌍 Aggiunta Repository Docker..."
echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq

# 5. Installazione
echo "⬇️  Installazione Engine & Compose..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Post-Installazione (Gruppi)
echo "👥 Configurazione Permessi Utenti..."

# Aggiungi utente corrente (sudoer)
REAL_USER=${SUDO_USER:-$USER}
if [ "$REAL_USER" != "root" ]; then
    usermod -aG docker "$REAL_USER"
    echo "   ✅ Utente '$REAL_USER' aggiunto a gruppo 'docker'."
fi

# Aggiungi utente di servizio 'easyway' (se esiste)
if id "easyway" &>/dev/null; then
    usermod -aG docker easyway
    echo "   ✅ Utente 'easyway' aggiunto a gruppo 'docker'."
fi

# 7. Verifica
echo "🧪 Verifica Installazione..."
docker --version
docker compose version

echo "✅ DOCKER INSTALLATO CON SUCCESSO!"
echo "⚠️  IMPORTANTE: Fai logout e login per applicare i permessi del gruppo docker."
