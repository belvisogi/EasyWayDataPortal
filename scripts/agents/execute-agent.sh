#!/bin/bash
# ==============================================================================
# Agent Executor with Authorization Check
# ==============================================================================
# Purpose: Example wrapper that enforces RBAC before executing an agent
# Usage: ./execute-agent.sh <agent_name> [agent_args...]
# ==============================================================================

set -e

AGENT_NAME="${1:-}"
shift || true  # Remove first arg, keep rest

if [ -z "$AGENT_NAME" ]; then
    echo "❌ Error: Agent name required"
    echo "Usage: $0 <agent_name> [agent_args...]"
    exit 1
fi

# ==============================================================================
# Load agent manifest and extract required_group
# ==============================================================================

MANIFEST_PATH="agents/${AGENT_NAME}/manifest.json"

if [ ! -f "$MANIFEST_PATH" ]; then
    echo "❌ Error: Agent manifest not found: $MANIFEST_PATH"
    exit 1
fi

# Extract required_group from manifest (using jq if available, else grep)
if command -v jq &> /dev/null; then
    REQUIRED_GROUP=$(jq -r '.security.required_group // empty' "$MANIFEST_PATH")
else
    # Fallback: grep-based extraction (less reliable)
    REQUIRED_GROUP=$(grep -oP '"required_group"\s*:\s*"\K[^"]+' "$MANIFEST_PATH" || echo "")
fi

if [ -z "$REQUIRED_GROUP" ]; then
    echo "⚠️  Warning: No security.required_group defined in manifest"
    echo "   Agent will execute WITHOUT authorization check"
    echo "   Consider adding 'security.required_group' to $MANIFEST_PATH"
    echo ""
    # Continue without check (backward compatibility)
else
    # ==============================================================================
    # Enforce permission check
    # ==============================================================================
    
    echo "🔒 Enforcing RBAC for agent: $AGENT_NAME"
    
    if ! ./scripts/agents/check-agent-permission.sh "$AGENT_NAME" "$REQUIRED_GROUP"; then
        echo ""
        echo "❌ AUTHORIZATION FAILED"
        echo "   Agent execution blocked by RBAC policy"
        exit 1
    fi
    
    echo ""
fi

# ==============================================================================
# Execute agent (if permission granted)
# ==============================================================================

echo "🚀 Executing agent: $AGENT_NAME"

# Example: call agent's main script
AGENT_SCRIPT="agents/${AGENT_NAME}/run.sh"

if [ -f "$AGENT_SCRIPT" ]; then
    exec bash "$AGENT_SCRIPT" "$@"
else
    echo "⚠️  Warning: Agent script not found: $AGENT_SCRIPT"
    echo "   This is just an example wrapper - implement actual agent execution"
    exit 0
fi
