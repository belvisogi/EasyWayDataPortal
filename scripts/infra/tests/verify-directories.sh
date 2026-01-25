#!/bin/bash
set -e

# ==============================================================================
# 🧪 EasyWay Directory Structure Verification Test
# ==============================================================================
# Purpose: Verify directory structure and permissions
# Usage: sudo ./verify-directories.sh
# Exit Code: 0 = success, 1 = failure
# ==============================================================================

echo "🧪 Testing directory structure and permissions..."
echo ""

FAILED=0

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

# ==============================================================================
# Test 1: Directory existence and ownership
# ==============================================================================
echo "Test 1: Checking directory existence and ownership..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ FAIL: Missing directory: $dir"
        FAILED=1
        continue
    fi
    
    # Check ownership (should be easyway:easyway-dev)
    owner=$(stat -c '%U:%G' "$dir")
    if [ "$owner" != "easyway:easyway-dev" ]; then
        echo "❌ FAIL: Wrong ownership on $dir: $owner (expected easyway:easyway-dev)"
        FAILED=1
    else
        echo "✅ PASS: $dir ($owner)"
    fi
done
echo ""

# ==============================================================================
# Test 2: Directory permissions
# ==============================================================================
echo "Test 2: Checking directory permissions..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "⏭️  SKIP: $dir (does not exist)"
        continue
    fi
    
    perms=$(stat -c '%a' "$dir")
    # Accept 775 (standard) or 770 (strict)
    if [ "$perms" != "775" ] && [ "$perms" != "770" ]; then
        echo "⚠️  WARN: $dir has permissions $perms (expected 775 or 770)"
        # Not a hard failure, just a warning
    else
        echo "✅ PASS: $dir (permissions $perms)"
    fi
done
echo ""

# ==============================================================================
# Test 3: SGID bit (group inheritance)
# ==============================================================================
echo "Test 3: Checking SGID bit for group inheritance..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "⏭️  SKIP: $dir (does not exist)"
        continue
    fi
    
    # Check if SGID bit is set (should be 2XXX in octal)
    full_perms=$(stat -c '%a' "$dir")
    if [ "${full_perms:0:1}" -ge 2 ]; then
        echo "✅ PASS: $dir has SGID bit set"
    else
        echo "⚠️  WARN: $dir missing SGID bit (files may not inherit group)"
        # Not a hard failure, but recommended
    fi
done
echo ""

# ==============================================================================
# Test 4: Convenience symlink
# ==============================================================================
echo "Test 4: Checking convenience symlink..."
if [ -L "/home/easyway/app" ]; then
    target=$(readlink /home/easyway/app)
    if [ "$target" = "/opt/easyway" ]; then
        echo "✅ PASS: /home/easyway/app -> /opt/easyway"
    else
        echo "⚠️  WARN: /home/easyway/app points to $target (expected /opt/easyway)"
    fi
elif [ -e "/home/easyway/app" ]; then
    echo "❌ FAIL: /home/easyway/app exists but is not a symlink"
    FAILED=1
else
    echo "⚠️  WARN: Symlink /home/easyway/app does not exist (recommended for convenience)"
    # Not a hard failure
fi
echo ""

# ==============================================================================
# Summary
# ==============================================================================
if [ $FAILED -eq 0 ]; then
    echo "✅ All directory structure tests PASSED!"
    exit 0
else
    echo "❌ Some tests FAILED. Run setup-easyway-server.sh to fix."
    exit 1
fi
