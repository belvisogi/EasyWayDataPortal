#!/bin/bash
set -e

# ==============================================================================
# 🔐 EasyWay Security Audit Script
# ==============================================================================
# Purpose: Check current server state against EasyWay Server Standard
# Usage: sudo ./security-audit.sh
# Output: Report of compliance and deviations
# ==============================================================================

echo "=== EasyWay Security Audit ==="
echo "Timestamp: $(date)"
echo ""

# Track issues
ISSUES=0

# ==============================================================================
# 1. User & Group Verification
# ==============================================================================
echo "📋 Checking Users & Groups..."

# Check if easyway user exists
if id -u easyway > /dev/null 2>&1; then
    echo "✅ User 'easyway' exists"
    echo "   $(id easyway)"
else
    echo "❌ User 'easyway' MISSING"
    ISSUES=$((ISSUES + 1))
fi

# Check if easyway-dev group exists
if getent group easyway-dev > /dev/null; then
    echo "✅ Group 'easyway-dev' exists"
    echo "   $(getent group easyway-dev)"
else
    echo "❌ Group 'easyway-dev' MISSING"
    ISSUES=$((ISSUES + 1))
fi

# Check if current user is in easyway-dev
CURRENT_USER=${SUDO_USER:-$USER}
if groups "$CURRENT_USER" | grep -q easyway-dev; then
    echo "✅ User '$CURRENT_USER' is in 'easyway-dev' group"
else
    echo "⚠️  User '$CURRENT_USER' is NOT in 'easyway-dev' group"
    echo "   (May need to logout/login after running setup script)"
fi

echo ""

# ==============================================================================
# 2. Directory Structure Verification
# ==============================================================================
echo "📂 Checking Directory Structure..."

REQUIRED_DIRS=(
    "/opt/easyway"
    "/opt/easyway/bin"
    "/opt/easyway/config"
    "/var/lib/easyway"
    "/var/lib/easyway/db"
    "/var/lib/easyway/uploads"
    "/var/lib/easyway/backups"
    "/var/log/easyway"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        owner=$(stat -c '%U:%G' "$dir")
        perms=$(stat -c '%a' "$dir")
        echo "✅ $dir (owner: $owner, perms: $perms)"
        
        # Check if owned by easyway:easyway-dev
        if [ "$owner" != "easyway:easyway-dev" ]; then
            echo "   ⚠️  Expected ownership: easyway:easyway-dev"
        fi
        
        # Check if permissions are 775
        if [ "$perms" != "775" ] && [ "$perms" != "770" ]; then
            echo "   ⚠️  Expected permissions: 775 or 770"
        fi
    else
        echo "❌ MISSING: $dir"
        ISSUES=$((ISSUES + 1))
    fi
done

# Check for convenience symlink
if [ -L "/home/easyway/app" ]; then
    target=$(readlink /home/easyway/app)
    echo "✅ Symlink exists: /home/easyway/app -> $target"
else
    echo "⚠️  Symlink MISSING: /home/easyway/app"
fi

echo ""

# ==============================================================================
# 3. SSH Security Configuration
# ==============================================================================
echo "🔒 Checking SSH Security..."

# Check if SSH config exists
if [ -f "/etc/ssh/sshd_config" ]; then
    # Password authentication
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo "✅ Password authentication disabled"
    else
        echo "⚠️  Password authentication may be ENABLED (security risk!)"
        ISSUES=$((ISSUES + 1))
    fi
    
    # Root login
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        echo "✅ Root login disabled"
    else
        echo "⚠️  Root login may be ENABLED (check manually)"
    fi
    
    # Pubkey authentication
    if grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config || ! grep -q "^PubkeyAuthentication" /etc/ssh/sshd_config; then
        echo "✅ Public key authentication enabled (or default)"
    else
        echo "❌ Public key authentication DISABLED"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "❌ SSH config file not found!"
    ISSUES=$((ISSUES + 1))
fi

echo ""

# ==============================================================================
# 4. Firewall Status
# ==============================================================================
echo "🛡️  Checking Firewall..."

if command -v ufw > /dev/null; then
    echo "✅ UFW installed"
    sudo ufw status numbered
elif command -v iptables > /dev/null; then
    echo "⚠️  Using iptables (Oracle Cloud default)"
    echo "Current rules (first 20 lines):"
    sudo iptables -L -n | head -20
else
    echo "❌ NO FIREWALL DETECTED!"
    ISSUES=$((ISSUES + 1))
fi

echo ""

# ==============================================================================
# 5. Docker Security
# ==============================================================================
echo "🐳 Checking Docker..."

if command -v docker > /dev/null; then
    echo "✅ Docker installed: $(docker --version)"
    
    # Check if Docker is running
    if docker ps >/dev/null 2>&1; then
        echo "✅ Docker daemon running"
        echo ""
        echo "Running containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    else
        echo "⚠️  Docker daemon not running (or permission denied)"
    fi
else
    echo "⚠️  Docker not installed"
fi

echo ""

# ==============================================================================
# 6. Secrets Management
# ==============================================================================
echo "🔑 Checking Secrets Management..."

# Check for .env file
if [ -f "/opt/easyway/config/.env" ]; then
    perms=$(stat -c '%a' "/opt/easyway/config/.env")
    owner=$(stat -c '%U:%G' "/opt/easyway/config/.env")
    echo "✅ .env file exists (perms: $perms, owner: $owner)"
    
    if [ "$perms" != "600" ] && [ "$perms" != "640" ]; then
        echo "   ⚠️  Recommended permissions: 600 (current: $perms)"
    fi
else
    echo "⚠️  .env file not found at /opt/easyway/config/.env"
    echo "   API keys may be stored in docker-compose.yml (less secure)"
fi

echo ""

# ==============================================================================
# 7. Summary
# ==============================================================================
echo "=== Summary ==="
if [ $ISSUES -eq 0 ]; then
    echo "✅ All critical security checks passed!"
    echo "   Server appears to be configured according to EasyWay Server Standard."
    exit 0
else
    echo "⚠️  Found $ISSUES issue(s) that need attention."
    echo "   Review the output above and run setup-easyway-server.sh to fix."
    exit 1
fi
