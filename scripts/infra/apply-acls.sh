#!/bin/bash
set -e

# ==============================================================================
# 🔐 Apply ACLs to EasyWay Directories - Enterprise RBAC Model
# ==============================================================================
# Purpose: Apply granular Access Control Lists to EasyWay directories
# Usage: sudo ./apply-acls.sh
# Prerequisites: ACL support enabled on filesystem (ext4/xfs default)
# ==============================================================================

echo "🔐 Applying ACLs to EasyWay directories..."
echo ""

# Check if ACL tools are installed
if ! command -v setfacl &> /dev/null; then
    echo "❌ ERROR: setfacl not found. Installing acl package..."
    sudo apt-get update && sudo apt-get install -y acl
fi

# ==============================================================================
# /opt/easyway - Application Root
# ==============================================================================
echo "📂 /opt/easyway - Application root"
sudo setfacl -R -m g:easyway-read:r-x /opt/easyway
sudo setfacl -R -m g:easyway-ops:r-x /opt/easyway
sudo setfacl -R -m g:easyway-dev:rwx /opt/easyway
sudo setfacl -R -m g:easyway-admin:rwx /opt/easyway
sudo setfacl -d -m g:easyway-read:r-x /opt/easyway
sudo setfacl -d -m g:easyway-dev:rwx /opt/easyway
echo "   ✅ read: r-x, ops: r-x, dev: rwx, admin: rwx"

# ==============================================================================
# /opt/easyway/bin - Executables (Ops can deploy)
# ==============================================================================
echo "📂 /opt/easyway/bin - Executables"
sudo setfacl -R -m g:easyway-read:r-x /opt/easyway/bin
sudo setfacl -R -m g:easyway-ops:rwx /opt/easyway/bin
sudo setfacl -R -m g:easyway-dev:rwx /opt/easyway/bin
sudo setfacl -R -m g:easyway-admin:rwx /opt/easyway/bin
sudo setfacl -d -m g:easyway-ops:rwx /opt/easyway/bin
echo "   ✅ read: r-x, ops: rwx (can deploy), dev: rwx, admin: rwx"

# ==============================================================================
# /opt/easyway/config - Configs (Admin-only write)
# ==============================================================================
echo "📂 /opt/easyway/config - Configuration files"
sudo setfacl -R -m g:easyway-read:r-- /opt/easyway/config
sudo setfacl -R -m g:easyway-ops:r-- /opt/easyway/config
sudo setfacl -R -m g:easyway-dev:r-- /opt/easyway/config
sudo setfacl -R -m g:easyway-admin:rwx /opt/easyway/config
sudo setfacl -d -m g:easyway-admin:rwx /opt/easyway/config
echo "   ✅ read: r--, ops: r--, dev: r--, admin: rwx (only admins can modify)"

# ==============================================================================
# /var/lib/easyway/db - Database (Admin-only)
# ==============================================================================
echo "📂 /var/lib/easyway/db - Database files"
sudo setfacl -R -m g:easyway-read:--- /var/lib/easyway/db
sudo setfacl -R -m g:easyway-ops:--- /var/lib/easyway/db
sudo setfacl -R -m g:easyway-dev:--- /var/lib/easyway/db
sudo setfacl -R -m g:easyway-admin:rwx /var/lib/easyway/db
sudo setfacl -d -m g:easyway-admin:rwx /var/lib/easyway/db
echo "   ✅ read: ---, ops: ---, dev: ---, admin: rwx (strict isolation)"

# ==============================================================================
# /var/lib/easyway/uploads - User Uploads (Ops + Dev can manage)
# ==============================================================================
echo "📂 /var/lib/easyway/uploads - User uploads"
sudo setfacl -R -m g:easyway-read:r-x /var/lib/easyway/uploads
sudo setfacl -R -m g:easyway-ops:rwx /var/lib/easyway/uploads
sudo setfacl -R -m g:easyway-dev:rwx /var/lib/easyway/uploads
sudo setfacl -R -m g:easyway-admin:rwx /var/lib/easyway/uploads
sudo setfacl -d -m g:easyway-ops:rwx /var/lib/easyway/uploads
echo "   ✅ read: r-x, ops: rwx, dev: rwx, admin: rwx"

# ==============================================================================
# /var/lib/easyway/backups - Backups (Dev read, Admin write)
# ==============================================================================
echo "📂 /var/lib/easyway/backups - Backup files"
sudo setfacl -R -m g:easyway-read:--- /var/lib/easyway/backups
sudo setfacl -R -m g:easyway-ops:--- /var/lib/easyway/backups
sudo setfacl -R -m g:easyway-dev:r-x /var/lib/easyway/backups
sudo setfacl -R -m g:easyway-admin:rwx /var/lib/easyway/backups
sudo setfacl -d -m g:easyway-admin:rwx /var/lib/easyway/backups
echo "   ✅ read: ---, ops: ---, dev: r-x (read-only), admin: rwx"

# ==============================================================================
# /var/log/easyway - Logs (Everyone read, Dev+ write)
# ==============================================================================
echo "📂 /var/log/easyway - Application logs"
sudo setfacl -R -m g:easyway-read:r-x /var/log/easyway
sudo setfacl -R -m g:easyway-ops:r-x /var/log/easyway
sudo setfacl -R -m g:easyway-dev:rwx /var/log/easyway
sudo setfacl -R -m g:easyway-admin:rwx /var/log/easyway
sudo setfacl -d -m g:easyway-read:r-x /var/log/easyway
sudo setfacl -d -m g:easyway-dev:rwx /var/log/easyway
echo "   ✅ read: r-x (everyone), ops: r-x, dev: rwx, admin: rwx"

echo ""
echo "✅ ACLs applied successfully!"
echo ""
echo "Verify with:"
echo "  getfacl /opt/easyway"
echo "  getfacl /opt/easyway/config"
echo "  getfacl /var/lib/easyway/db"
echo ""
echo "Export ACLs for backup/replication:"
echo "  sudo getfacl -R /opt/easyway > easyway-acls.txt"
echo "  sudo setfacl --restore=easyway-acls.txt"
