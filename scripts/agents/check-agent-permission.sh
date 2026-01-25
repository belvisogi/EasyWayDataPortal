#!/bin/bash
# ==============================================================================
# Agent Permission Enforcer
# ==============================================================================
# Purpose: Check if current user has required group permission to execute agent
# Usage: ./check-agent-permission.sh <agent_name> <required_group>
# Exit codes:
#   0 = Permission granted
#   1 = Permission denied
#   2 = Invalid arguments
# ==============================================================================

set -e

AGENT_NAME="${1:-}"
REQUIRED_GROUP="${2:-}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==============================================================================
# Validation
# ==============================================================================

if [ -z "$AGENT_NAME" ] || [ -z "$REQUIRED_GROUP" ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: $0 <agent_name> <required_group>"
    echo ""
    echo "Example:"
    echo "  $0 agent_dba easyway-admin"
    exit 2
fi

# ==============================================================================
# Get current user
# ==============================================================================

CURRENT_USER="${USER:-$(whoami)}"

if [ -z "$CURRENT_USER" ]; then
    echo -e "${RED}❌ Error: Cannot determine current user${NC}"
    exit 1
fi

# ==============================================================================
# Check group membership
# ==============================================================================

echo -e "${YELLOW}🔍 Checking permission for agent: ${AGENT_NAME}${NC}"
echo "   Current user: $CURRENT_USER"
echo "   Required group: $REQUIRED_GROUP"

# Get user's groups
USER_GROUPS=$(groups "$CURRENT_USER" 2>/dev/null || id -nG "$CURRENT_USER" 2>/dev/null)

if [ -z "$USER_GROUPS" ]; then
    echo -e "${RED}❌ Error: Cannot retrieve groups for user '$CURRENT_USER'${NC}"
    exit 1
fi

echo "   User groups: $USER_GROUPS"

# Check if user is in required group
if echo "$USER_GROUPS" | grep -qw "$REQUIRED_GROUP"; then
    echo -e "${GREEN}✅ Permission GRANTED${NC}"
    echo "   User '$CURRENT_USER' is member of group '$REQUIRED_GROUP'"
    
    # Log successful authorization (append to audit log)
    LOG_DIR="/var/log/easyway"
    if [ -d "$LOG_DIR" ] && [ -w "$LOG_DIR" ]; then
        echo "$(date -Iseconds)|GRANT|$CURRENT_USER|$AGENT_NAME|$REQUIRED_GROUP" >> "$LOG_DIR/agent-auth.log"
    fi
    
    exit 0
else
    echo -e "${RED}❌ Permission DENIED${NC}"
    echo "   User '$CURRENT_USER' is NOT member of group '$REQUIRED_GROUP'"
    echo ""
    echo "Required actions:"
    echo "  1. Contact system administrator"
    echo "  2. Request membership in group '$REQUIRED_GROUP'"
    echo "  3. Command: sudo usermod -aG $REQUIRED_GROUP $CURRENT_USER"
    echo "  4. Logout/login to refresh group membership"
    
    # Log denied authorization (append to audit log)
    LOG_DIR="/var/log/easyway"
    if [ -d "$LOG_DIR" ] && [ -w "$LOG_DIR" ]; then
        echo "$(date -Iseconds)|DENY|$CURRENT_USER|$AGENT_NAME|$REQUIRED_GROUP" >> "$LOG_DIR/agent-auth.log"
    fi
    
    exit 1
fi
