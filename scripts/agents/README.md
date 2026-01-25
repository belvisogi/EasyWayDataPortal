# Agent Authorization & Enforcement

## Purpose

This directory contains scripts for enforcing **RBAC (Role-Based Access Control)** on agent execution.

Before any agent runs, we verify that the current user has the required group membership defined in the agent's `manifest.json`.

---

## 🔒 Security Model

### Concept: Agent Identity & Authorization

Every agent has a **security context** in its manifest:

```json
{
  "name": "agent_dba",
  "security": {
    "required_group": "easyway-admin",
    "rationale": "DBA agent modifies database schema and configurations",
    "can_sudo": true,
    "allowed_directories": ["/opt/easyway/config", "/var/lib/easyway/db"]
  }
}
```

**Before execution**, we check:
1. ✅ Is current user member of `required_group`?
2. ✅ If yes → proceed with agent execution
3. ❌ If no → block with permission denied

---

## 🛠️ Scripts

### 1. `check-agent-permission.sh`

**Purpose**: Check if current user has required group membership

**Usage**:
```bash
./check-agent-permission.sh <agent_name> <required_group>
```

**Example**:
```bash
# Check if current user can execute agent_dba  
./check-agent-permission.sh agent_dba easyway-admin

# Returns:
# - Exit 0 if permission granted (user in group)
# - Exit 1 if permission denied (user not in group)
# - Exit 2 if invalid arguments
```

**Features**:
- ✅ Checks group membership via `groups` command
- ✅ Logs authorization attempts to `/var/log/easyway/agent-auth.log`
- ✅ Colors output (green=granted, red=denied)
- ✅ Provides helpful error messages

---

### 2. `execute-agent.sh`

**Purpose**: Wrapper that enforces RBAC before running any agent

**Usage**:
```bash
./execute-agent.sh <agent_name> [agent_args...]
```

**Example**:
```bash
# Execute agent_dba with RBAC enforcement
./execute-agent.sh agent_dba --action db-user:create

# Workflow:
# 1. Load agents/agent_dba/manifest.json
# 2. Extract security.required_group
# 3. Call check-agent-permission.sh
# 4. If granted → execute agent's run.sh
# 5. If denied → block with error
```

**Features**:
- ✅ Reads `manifest.json` to get `security.required_group`
- ✅ Calls `check-agent-permission.sh` for enforcement
- ✅ Backward compatible (if no security block, executes without check)
- ✅ Logs all authorization attempts

---

## 📋 Quick Start

### Add Security Block to Agent Manifest

Edit `agents/<agent_name>/manifest.json`:

```json
{
  "name": "agent_deployer",
  "security": {
    "required_group": "easyway-ops",
    "rationale": "Deployer can push code and restart services",
    "can_sudo": false
  },
  ...
}
```

### Execute Agent with Enforcement

```bash
cd /path/to/EasyWayDataPortal

# Instead of calling agent directly:
# agents/agent_dba/run.sh

# Use the enforcer wrapper:
./scripts/agents/execute-agent.sh agent_dba
```

---

## 🎯 Agent → Group Mapping

| Agent | Required Group | Rationale |
|-------|----------------|-----------|
| `agent_dba` | `easyway-admin` | Modifies DB schema, configs |
| `agent_deployer` | `easyway-ops` | Deploys code, restarts services |
| `agent_docs_review` | `easyway-dev` | Modifies Wiki, docs |
| `agent_monitor` | `easyway-read` | Read-only access to logs |
| `agent_governance` | `easyway-admin` | Approves changes, quality gates |

---

## 🧪 Testing

### Test 1: Admin User Can Execute DBA Agent

```bash
# As ubuntu user (member of easyway-admin)
./scripts/agents/execute-agent.sh agent_dba

# Expected: ✅ Permission GRANTED
```

### Test 2: Read-Only User Cannot Execute DBA Agent

```bash
# Create read-only test user
sudo useradd -s /bin/bash -m testuser
sudo usermod -aG easyway-read testuser

# Switch to testuser
sudo -u testuser bash
cd /path/to/EasyWayDataPortal

# Try to execute DBA agent
./scripts/agents/execute-agent.sh agent_dba

# Expected: ❌ Permission DENIED
```

### Test 3: Ops User Can Execute Deployer (Not DBA)

```bash
# Create ops user
sudo useradd -s /bin/bash -m deployuser
sudo usermod -aG easyway-ops deployuser

# As deployuser
sudo -u deployuser bash

# Should succeed (if agent_deployer requires easyway-ops)
./scripts/agents/execute-agent.sh agent_deployer

# Should fail (agent_dba requires easyway-admin)
./scripts/agents/execute-agent.sh agent_dba
```

---

## 📊 Authorization Audit Trail

All authorization attempts are logged to:

```
/var/log/easyway/agent-auth.log
```

**Format**:
```
2026-01-25T18:30:00|GRANT|ubuntu|agent_dba|easyway-admin
2026-01-25T18:31:00|DENY|testuser|agent_dba|easyway-admin
```

**View logs**:
```bash
# Recent authorization events
tail -f /var/log/easyway/agent-auth.log

# Count denials
grep "DENY" /var/log/easyway/agent-auth.log | wc -l

# Who tried to execute what
awk -F'|' '{print $3 " → " $4}' /var/log/easyway/agent-auth.log
```

---

## 🔗 Related Documentation

- **Security Framework**: [`docs/infra/SECURITY_FRAMEWORK.md`](../../docs/infra/SECURITY_FRAMEWORK.md)
- **Agent Identity Wiki**: [`Wiki/EasyWayData.wiki/infra/security-framework.md`](../../Wiki/EasyWayData.wiki/infra/security-framework.md)
- **RBAC Groups**: 4-tier model (read/ops/dev/admin)

---

## 🚀 Next Steps

1. **Add security blocks** to all agent manifests
2. **Update orchestrator** to use `execute-agent.sh` wrapper
3. **Test enforcement** with different users/groups
4. **Monitor audit logs** for unauthorized attempts

---

**Status**: ✅ Example implementation complete  
**Production Ready**: Ready for integration into orchestrator  
**Last Updated**: 2026-01-25
