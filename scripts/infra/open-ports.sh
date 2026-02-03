#!/bin/bash
set -e

# ==============================================================================
# 🛡️ EasyWay Firewall Opener
# ==============================================================================
# Apre le porte necessarie sul firewall di sistema (Ubuntu/Oracle).
#
# PORTE:
# - 80, 443: Web Standard
# - 8080: EasyWay Portal (Frontend)
# - 8000: EasyWay Cortex (Backend API)
# - 8929: GitLab HTTP UI
# - 2222: GitLab SSH (Git operations)
#
# USAGE: sudo ./scripts/infra/open-ports.sh
# ==============================================================================

echo "🛡️ Configurazione Firewall..."

# 1. Metodo UFW (Uncomplicated Firewall) - Standard Ubuntu
if command -v ufw >/dev/null && systemctl is-active --quiet ufw; then
    echo "   ✅ Rilevato UFW attivo."
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8080/tcp
    ufw allow 8000/tcp
    ufw allow 8929/tcp  # GitLab HTTP
    ufw allow 2222/tcp  # GitLab SSH
    ufw allow 22/tcp # Assicuriamoci di non chiuderci fuori
    ufw reload
    echo "   ✅ Porte aperte su UFW."
    exit 0
fi

# 2. Metodo IPTABLES (Oracle Cloud Default)
echo "   ⚠️ UFW non attivo. Configuro IPTables direttamente (Oracle Style)."

# Inseriamo le regole in cima alla catena INPUT per evitare che vengano bloccate da DROP successivi
open_port() {
    local port=$1
    echo "   🔓 Apertura porta $port..."
    iptables -I INPUT -p tcp --dport $port -j ACCEPT -m comment --comment "EasyWay Service"
}

open_port 80
open_port 443
open_port 8080
open_port 8000
open_port 8929  # GitLab HTTP
open_port 2222  # GitLab SSH

# 3. Persistenza
echo "   💾 Salvataggio regole..."
if command -v netfilter-persistent >/dev/null; then
    netfilter-persistent save
    echo "   ✅ Regole salvate (netfilter-persistent)."
else
    echo "   ⚠️ ATTENZIONE: netfilter-persistent non installato."
    echo "      Installalo con: apt-get install iptables-persistent"
    # Fallback installation
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent netfilter-persistent
    netfilter-persistent save
fi

echo "✅ CONFIGURAZIONE FIREWALL COMPLETATA!"
echo "⚠️  IMPORTANTE: Ricordati di aprire le porte anche nella Oracle Cloud Console (Security List)!"
