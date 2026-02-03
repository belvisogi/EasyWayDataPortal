# Infrastructure Documentation Index

> **Purpose**: Quick reference to all infrastructure documentation  
> **Audience**: DevOps, Platform Team, AI Agents

---

## 📚 Core Documentation

### Setup Guides

| Service | Guide | Status |
|---------|-------|--------|
| **GitLab** | [gitlab-setup-guide.md](gitlab-setup-guide.md) | ✅ Complete |
| **Oracle Cloud Network** | [oracle-cloud-network-setup.md](oracle-cloud-network-setup.md) | ✅ Complete |

### Quick References

| Document | Purpose |
|----------|---------|
| [INFRA-DEPLOYMENT-CHECKLIST.md](INFRA-DEPLOYMENT-CHECKLIST.md) | **START HERE** - Checklist for deploying any new service |
| [GITLAB-RECOVERY-CHEATSHEET.md](GITLAB-RECOVERY-CHEATSHEET.md) | 1-page GitLab recovery guide |
| [gitlab-quick-recovery.md](gitlab-quick-recovery.md) | Step-by-step GitLab recovery (human-friendly) |

### Troubleshooting

| Service | Q&A Document |
|---------|--------------|
| **GitLab** | [gitlab-qa.md](gitlab-qa.md) |

---

## 🚀 Quick Start: Deploying a New Service

**Always follow this order**:

1. **Read**: [INFRA-DEPLOYMENT-CHECKLIST.md](INFRA-DEPLOYMENT-CHECKLIST.md)
2. **Configure**: Oracle Cloud Security List
3. **Configure**: Server iptables (use `scripts/infra/open-ports.sh`)
4. **Deploy**: Your service
5. **Verify**: All 3 firewall layers
6. **Document**: Update relevant docs

---

## 🛡️ The 3-Layer Firewall Rule

**NEVER FORGET**: Oracle Cloud requires **3 layers** of configuration:

1. **Oracle Cloud Security List** (web console)
2. **iptables** (server: `/etc/iptables/rules.v4`)
3. **Application firewall** (if any, e.g. ufw)

**Missing any layer = Service not accessible!**

---

## 📋 Common Tasks

### Open a New Port

1. Update `scripts/infra/open-ports.sh`
2. Add port to Oracle Cloud Security List
3. Run script on server
4. Verify with checklist

### Troubleshoot Connectivity

1. Check service is running: `docker ps`
2. Check port is listening: `ss -tlnp | grep <PORT>`
3. Check iptables: `sudo iptables -L INPUT -n | grep <PORT>`
4. Check Oracle Cloud Security List
5. Check from external: `curl http://<IP>:<PORT>`

### Disaster Recovery

1. **GitLab**: Use [GITLAB-RECOVERY-CHEATSHEET.md](GITLAB-RECOVERY-CHEATSHEET.md)
2. **Network**: Follow [oracle-cloud-network-setup.md](oracle-cloud-network-setup.md)
3. **General**: Use [INFRA-DEPLOYMENT-CHECKLIST.md](INFRA-DEPLOYMENT-CHECKLIST.md)

---

## 🔧 Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `open-ports.sh` | Open firewall ports (iptables) | `scripts/infra/open-ports.sh` |
| `deploy-gitlab.sh` | Deploy GitLab | `scripts/infra/deploy-gitlab.sh` |
| `backup-gitlab.sh` | Backup GitLab | `scripts/infra/backup-gitlab.sh` |

---

## 📊 Server Information

**Production Server**: `80.225.86.168`

**Resources**:
- RAM: 23 GB
- Storage: 96 GB
- CPU: 4 cores

**Services Running**:
- Portal Frontend: Port 8080
- API Backend: Port 8000
- GitLab HTTP: Port 8929
- GitLab SSH: Port 2222
- n8n: Port 5678

---

## 🎯 For AI Agents

**When deploying infrastructure**:

1. **ALWAYS** check `INFRA-DEPLOYMENT-CHECKLIST.md` first
2. **ALWAYS** configure all 3 firewall layers
3. **ALWAYS** update `scripts/infra/open-ports.sh`
4. **ALWAYS** document in `docs/infra/`
5. **ALWAYS** add Q&A entries for issues encountered

**Key files to check**:
- `scripts/infra/open-ports.sh` - Existing port configuration
- `docs/infra/INFRA-DEPLOYMENT-CHECKLIST.md` - Deployment procedure
- `docs/infra/<service>-qa.md` - Known issues and solutions

---

**Last Updated**: 2026-02-03  
**Maintained By**: Platform Team
