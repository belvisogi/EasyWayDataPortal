# 🔒 Security Framework Summary

## Quick Reference

This is a **high-level summary** for quick access. For complete details, see [`SECURITY_FRAMEWORK.md`](../docs/infra/SECURITY_FRAMEWORK.md).

---

## 🏢 Enterprise RBAC Model

### 4 Security Groups

| Group | Access Level | Example Members |
|-------|-------------|-----------------|
| `easyway-read` | Read-only | Monitoring tools, auditors |
| `easyway-ops` | Deploy + restart | CI/CD pipeline |
| `easyway-dev` | Full development | Senior developers |
| `easyway-admin` | Full control + sudo | System administrators |

### Directory Permissions (ACL-based)

| Directory | `read` | `ops` | `dev` | `admin` |
|-----------|--------|-------|-------|---------|
| `/opt/easyway/bin` | r-x | **rwx** | rwx | rwx |
| `/opt/easyway/config` | r-- | r-- | r-- | **rwx** |
| `/var/lib/easyway/db` | --- | --- | --- | **rwx** |
| `/var/lib/easyway/backups` | --- | --- | r-x | **rwx** |
| `/var/log/easyway` | **r-x** | r-x | rwx | rwx |

---

## 🛠️ Quick Setup

```bash
# 1. Create users, groups, directories
cd /path/to/EasyWayDataPortal
sudo ./scripts/infra/setup-easyway-server.sh

# 2. Apply ACLs
sudo ./scripts/infra/apply-acls.sh

# 3. Add users to groups
sudo usermod -aG easyway-admin ubuntu
sudo usermod -aG easyway-ops ci-deploy
sudo usermod -aG easyway-dev alice

# 4. Verify
sudo ./scripts/infra/security-audit.sh
```

---

## 📖 Full Documentation

**Location**: [`docs/infra/SECURITY_FRAMEWORK.md`](../docs/infra/SECURITY_FRAMEWORK.md)

**Contains**:
- Complete RBAC model explanation
- ACL mapping for all directories
- Audit compliance guide (ISO 27001, SOC 2)
- Agent-ready implementation instructions
- Maintenance procedures
- FAQ

---

## 🤖 For AI Agents

When applying this framework:

1. **Read**: [`docs/infra/SECURITY_FRAMEWORK.md`](../docs/infra/SECURITY_FRAMEWORK.md) → "Agent Instructions" section
2. **Execute**: Follow checklist in order (backup → setup → ACLs → verify)
3. **Document**: Update [`docs/ORACLE_CURRENT_ENV.md`](../docs/ORACLE_CURRENT_ENV.md) with new state
4. **Verify**: All scripts in `scripts/infra/tests/` must pass

---

**Last Updated**: 2026-01-25
