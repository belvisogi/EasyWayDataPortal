#!/bin/bash
set -e

# ==============================================================================
# 🧪 EasyWay User & Group Verification Test
# ==============================================================================
# Purpose: Verify user and group configuration
# Usage: sudo ./verify-users.sh
# Exit Code: 0 = success, 1 = failure
# ==============================================================================

echo "🧪 Testing user and group configuration..."
echo ""

FAILED=0

# ==============================================================================
# Test 1: easyway user exists
# ==============================================================================
echo "Test 1: Checking if 'easyway' user exists..."
if id -u easyway > /dev/null 2>&1; then
    echo "✅ PASS: User 'easyway' exists"
    echo "   $(id easyway)"
else
    echo "❌ FAIL: User 'easyway' does not exist"
    FAILED=1
fi
echo ""

# ==============================================================================
# Test 2: easyway-dev group exists
# ==============================================================================
echo "Test 2: Checking if 'easyway-dev' group exists..."
if getent group easyway-dev > /dev/null; then
    echo "✅ PASS: Group 'easyway-dev' exists"
    echo "   $(getent group easyway-dev)"
else
    echo "❌ FAIL: Group 'easyway-dev' does not exist"
    FAILED=1
fi
echo ""

# ==============================================================================
# Test 3: ubuntu user is in easyway-dev group
# ==============================================================================
echo "Test 3: Checking if 'ubuntu' user is in 'easyway-dev' group..."
if groups ubuntu | grep -q easyway-dev; then
    echo "✅ PASS: User 'ubuntu' is in 'easyway-dev' group"
else
    echo "❌ FAIL: User 'ubuntu' is NOT in 'easyway-dev' group"
    echo "   (User may need to logout/login for group membership to take effect)"
    FAILED=1
fi
echo ""

# ==============================================================================
# Test 4: easyway user is in easyway-dev group
# ==============================================================================
echo "Test 4: Checking if 'easyway' user is in 'easyway-dev' group..."
if id -u easyway > /dev/null 2>&1; then
    if groups easyway | grep -q easyway-dev; then
        echo "✅ PASS: User 'easyway' is in 'easyway-dev' group"
    else
        echo "❌ FAIL: User 'easyway' is NOT in 'easyway-dev' group"
        FAILED=1
    fi
else
    echo "⏭️  SKIP: User 'easyway' does not exist (already reported)"
fi
echo ""

# ==============================================================================
# Summary
# ==============================================================================
if [ $FAILED -eq 0 ]; then
    echo "✅ All user and group tests PASSED!"
    exit 0
else
    echo "❌ Some tests FAILED. Run setup-easyway-server.sh to fix."
    exit 1
fi
