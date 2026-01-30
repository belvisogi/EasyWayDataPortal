#!/bin/bash
# Ubuntu Desktop + XRDP Setup per Hetzner Server
# Esegui come root: bash hetzner-ubuntu-desktop-setup.sh

set -e

echo "🚀 Installazione Ubuntu Desktop + XRDP"
echo "Tempo stimato: 20-30 minuti"
echo ""

# 1. Update sistema
echo "📦 Step 1/5: Aggiornamento sistema..."
apt update
apt upgrade -y

# 2. Installa Ubuntu Desktop (minimal)
echo "🖥️ Step 2/5: Installazione Ubuntu Desktop (questo richiede ~15 minuti)..."
DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop-minimal

# 3. Installa XRDP
echo "🔌 Step 3/5: Installazione XRDP..."
apt install -y xrdp
systemctl enable xrdp
systemctl start xrdp

# 4. Configura firewall per RDP
echo "🔥 Step 4/5: Configurazione firewall..."
ufw allow 3389/tcp
ufw --force enable

# 5. Crea utente per desktop
echo "👤 Step 5/5: Creazione utente 'easyway'..."
if id "easyway" &>/dev/null; then
    echo "Utente easyway già esistente"
else
    adduser --gecos "" --disabled-password easyway
    echo "easyway:EasyWay2026!" | chpasswd
    usermod -aG sudo easyway
fi

# 6. Configura XRDP per Ubuntu Desktop
echo "⚙️ Configurazione XRDP..."
cat > /etc/xrdp/startwm.sh << 'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec /usr/bin/gnome-session
EOF
chmod +x /etc/xrdp/startwm.sh

# Restart XRDP
systemctl restart xrdp

echo ""
echo "✅ INSTALLAZIONE COMPLETATA!"
echo ""
echo "📋 Informazioni Accesso:"
echo "   IP: $(curl -s ifconfig.me)"
echo "   Porta RDP: 3389"
echo "   Username: easyway"
echo "   Password: EasyWay2026!"
echo ""
echo "🔌 Per connetterti da Windows:"
echo "   1. Apri 'Remote Desktop Connection' (mstsc.exe)"
echo "   2. Computer: $(curl -s ifconfig.me)"
echo "   3. Username: easyway"
echo "   4. Password: EasyWay2026!"
echo ""
echo "⚠️ IMPORTANTE: Cambia la password dopo il primo accesso!"
echo "   Comando: passwd"
echo ""
