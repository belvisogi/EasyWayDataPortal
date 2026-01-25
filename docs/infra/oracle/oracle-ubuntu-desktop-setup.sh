#!/bin/bash
# Oracle Cloud - Fix Firewall and Install Ubuntu Desktop + XRDP
# Version: 1.0
# Date: 2026-01-25

set -e

echo "════════════════════════════════════════════════════════"
echo "  Oracle Cloud - Ubuntu Desktop + XRDP Setup"
echo "════════════════════════════════════════════════════════"
echo ""

# Step 1: Fix Firewall (iptables)
echo "🔥 [1/10] Fixing Ubuntu firewall..."
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT
echo "  ✅ Firewall rules added (SSH + RDP)"

# Step 2: Install iptables-persistent
echo ""
echo "💾 [2/10] Installing iptables-persistent..."
sudo apt update
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
echo "  ✅ Firewall rules saved permanently"

# Step 3: Verify firewall rules
echo ""
echo "🔍 [3/10] Verifying firewall rules..."
sudo iptables -L -n -v | grep -E "22|3389"
echo "  ✅ Firewall configured correctly"

# Step 4: Update system
echo ""
echo "📦 [4/10] Updating system packages..."
sudo apt update && sudo apt upgrade -y
echo "  ✅ System updated"

# Step 5: Install Ubuntu Desktop
echo ""
echo "🖥️  [5/10] Installing Ubuntu Desktop (this takes 15-20 minutes)..."
echo "  ⏳ Please be patient..."
sudo apt install -y ubuntu-desktop-minimal
echo "  ✅ Ubuntu Desktop installed"

# Step 6: Install XRDP
echo ""
echo "🔧 [6/10] Installing XRDP..."
sudo apt install -y xrdp xorgxrdp
echo "  ✅ XRDP installed"

# Step 7: Configure XRDP
echo ""
echo "⚙️  [7/10] Configuring XRDP..."
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
echo "  ✅ XRDP configured"

# Step 8: Create desktop user
echo ""
echo "👤 [8/10] Creating desktop user 'produser'..."
sudo useradd -m -s /bin/bash produser
echo "produser:EasyWay2026!" | sudo chpasswd
sudo usermod -aG sudo produser
echo "  ✅ User 'produser' created with password: EasyWay2026!"

# Step 9: Configure GNOME session
echo ""
echo "🎨 [9/10] Configuring GNOME desktop..."
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession

# Configure startwm.sh
sudo bash -c 'cat > /etc/xrdp/startwm.sh <<EOF
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
if [ -f /home/\$USER/.xsession ]; then
  . /home/\$USER/.xsession
else
  exec /usr/bin/gnome-session
fi
EOF'
sudo chmod +x /etc/xrdp/startwm.sh

# Fix XRDP to listen on IPv4
sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini
echo "  ✅ GNOME configured"

# Step 10: Start XRDP
echo ""
echo "🚀 [10/10] Starting XRDP service..."
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman
echo "  ✅ XRDP started"

# Final verification
echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ INSTALLATION COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Connection Details:"
echo "  IP Address: $(curl -s ifconfig.me)"
echo "  Username: produser"
echo "  Password: EasyWay2026!"
echo ""
echo "🔌 Connect with Remote Desktop:"
echo "  1. Press Win + R"
echo "  2. Type: mstsc"
echo "  3. Enter IP: $(curl -s ifconfig.me)"
echo "  4. Login with credentials above"
echo ""
echo "🔍 Service Status:"
sudo systemctl status xrdp --no-pager | head -5
echo ""
echo "🔍 Listening Ports:"
sudo netstat -tulpn | grep -E "22|3389"
echo ""
echo "════════════════════════════════════════════════════════"
echo "  ⚠️  IMPORTANT: Change the password after first login!"
echo "════════════════════════════════════════════════════════"
echo ""
