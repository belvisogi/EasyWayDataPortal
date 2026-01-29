#!/bin/bash
# 🏛️ EASYWAY SOVEREIGN BOOTSTRAP PROTOCOL
# Target: Ubuntu 22.04 LTS (Oracle ARM / Hetzner)
# Goal: Turn a raw VM into a Sovereign Code Fortress

set -e # Exit on error

echo "🔵 [INIT] Starting Bootstrap Protocol..."

# 1. Update System
echo "🔄 [1/6] Updating System..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl wget git htop ufw tar unzip

# 2. Install Docker & Compose (Official Script)
echo "🐳 [2/6] Installing Docker Engine..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "   ✅ Docker installed. User added to 'docker' group."
else
    echo "   ⚠️ Docker already installed. Skipping."
fi

# 3. Create Directory Structure
echo "📂 [3/6] Creating /opt/easyway..."
sudo mkdir -p /opt/easyway
sudo chown -R $USER:$USER /opt/easyway
sudo chmod 750 /opt/easyway

# 4. Security: Firewall (UFW)
echo "🛡️ [4/6] Configuring Firewall (UFW)..."
# Default Policy: Deny Incoming, Allow Outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Allow SSH (Critical!)
sudo ufw allow 22/tcp
# Allow HTTP/HTTPS (Traefik) (Not 8080/5678 - they go through Traefik)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# Enable
echo "y" | sudo ufw enable
echo "   ✅ Firewall Active. Only ports 22, 80, 443 open."

# 5. Performance Tuning (sysctl)
echo "🚀 [5/6] Tuning Kernel for Vector DB..."
# Increase max map count for Qdrant/Elastic
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w vm.max_map_count=262144

# 6. Finalize
echo "✅ [6/6] Bootstrap Complete."
echo "   👉 Please LOGOUT and LOGIN again to apply Docker group changes."
