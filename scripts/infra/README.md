# Infrastructure Scripts (`scripts/infra/`)

## 📋 Purpose

This directory contains **infrastructure setup scripts** for initial server provisioning and bootstrapping.

These scripts are meant to be run **once** (or rarely) to prepare the environment before deploying the EasyWay Data Portal stack.

---

## 🏗️ Scripts Overview

### 1. `setup-easyway-server.sh`
**Purpose**: Complete server standardization according to EasyWay Server Standards  
**When to use**:
- **First-time setup** of a new server instance (Oracle Cloud, AWS, Azure, etc.)
- When enforcing the standard directory structure on existing servers
- After OS reinstall or major infrastructure changes

**Usage**:
```bash
sudo ./setup-easyway-server.sh
```

**What it does**:
1. ✅ Creates service user (`easyway`) and developer group (`easyway-dev`)
2. ✅ Creates FHS-compliant directory structure:
   - `/opt/easyway/` - Application binaries and configs
   - `/var/lib/easyway/` - Persistent data (DB, uploads, backups)
   - `/var/log/easyway/` - Application logs
3. ✅ Applies secure permissions (775 + SGID for group inheritance)
4. ✅ Creates convenience symlink: `/home/easyway/app` → `/opt/easyway`

**Idempotent**: Can be run multiple times safely without breaking existing configurations.

**Reference**: See [`docs/infra/SERVER_STANDARDS.md`](../../docs/infra/SERVER_STANDARDS.md) for detailed philosophy and rationale.

---

### 2. `setup-env.sh`
**Purpose**: Environment-specific configuration setup  
**When to use**:
- After `setup-easyway-server.sh` to configure environment variables
- When switching between development/staging/production environments

**Usage**:
```bash
./setup-env.sh
```

**What it does**:
- Configures environment-specific settings
- Sets up `.env` files or exports required variables
- Prepares the environment for application deployment

---

### 3. `install-docker.sh`
**Purpose**: Automated Docker and Docker Compose installation  
**When to use**:
- On fresh server instances without Docker
- When upgrading Docker to a specific version

**Usage**:
```bash
sudo ./install-docker.sh
```

**What it does**:
1. ✅ Installs Docker Engine (latest stable or pinned version)
2. ✅ Installs Docker Compose plugin
3. ✅ Adds current user to `docker` group (no more `sudo docker`!)
4. ✅ Starts and enables Docker service

**Post-install**: Logout/login required for group membership to take effect.

---

### 4. `open-ports.sh`
**Purpose**: Configure firewall rules for EasyWay services  
**When to use**:
- After Docker installation on cloud instances (Oracle Cloud, AWS, etc.)
- When exposing new services/ports

**Usage**:
```bash
sudo ./open-ports.sh
```

**What it does**:
- Opens required ports in the OS firewall (`ufw`, `firewalld`, or `iptables`)
- Typically includes:
  - **80/443** - HTTP/HTTPS (web traffic)
  - **1521** - Oracle XE (database)
  - **8000** - ChromaDB API
  - **8080** - EasyWay Portal API

**Cloud Note**: You may also need to configure Security Lists/Security Groups in your cloud provider's console.

---

### 5. `remote/` Directory
**Purpose**: Remote deployment utilities and SSH helpers  
**Contents**:
- Scripts for deploying to remote servers
- SSH key management utilities
- Remote command execution wrappers

**When to use**:
- Deploying from local machine to production servers
- Automating multi-server deployments

---

## 🆚 `infra/` vs `ops/`

| Directory | Purpose | Frequency | Examples |
|-----------|---------|-----------|----------|
| **`infra/`** | Initial setup & bootstrapping | **One-time** (or rare) | `setup-easyway-server.sh`, `install-docker.sh`, `open-ports.sh` |
| **`ops/`** | Maintenance & operations | **Recurring** (on-demand or scheduled) | `check-*-status.ps1`, `fix-*.ps1`, `restart-*.ps1` |

---

## 📊 Recommended Workflow: New Server Setup

### Step-by-Step Bootstrap
```bash
# 1. Provision a fresh server (Oracle Cloud, AWS, etc.)
# 2. SSH into the server

# 3. Install Docker
sudo ./install-docker.sh

# 4. Configure firewall
sudo ./open-ports.sh

# 5. Set up EasyWay directory structure
sudo ./setup-easyway-server.sh

# 6. Configure environment
./setup-env.sh

# 7. Logout/login to refresh groups
exit
# (reconnect via SSH)

# 8. Verify Docker works without sudo
docker ps

# 9. Deploy your stack
cd /opt/easyway/releases
docker-compose up -d
```

---

## 🔐 Prerequisites

### OS Requirements
- **Linux** (Ubuntu 20.04+, Oracle Linux 8+, RHEL 8+, Debian 11+)
- **Root/sudo access** (most scripts require elevated privileges)
- **Bash 4.0+**

### Network Requirements
- Internet connectivity (for package downloads)
- Open outbound traffic on ports 80/443 (for apt/yum repositories)

---

## 🛡️ Security Considerations

> [!IMPORTANT]
> **EasyWay uses enterprise-grade RBAC** with 4 security groups and ACLs for fine-grained control.  
> **📖 Full Security Framework**: [`docs/infra/SECURITY_FRAMEWORK.md`](../../docs/infra/SECURITY_FRAMEWORK.md)

### Basic Model (Default `setup-easyway-server.sh`)

1. **User Isolation**: The `easyway` service user runs the application with minimal privileges
2. **Group-based Access**: Developers in `easyway-dev` group can deploy without `sudo`
3. **SGID Bit**: Ensures all new files inherit `easyway-dev` group ownership
4. **Firewall First**: Always run `open-ports.sh` before exposing services

### Enterprise Model (Recommended for Production)

For **audit compliance** and **production environments**, use the enterprise RBAC model:

```bash
# After running setup-easyway-server.sh
sudo ./apply-acls.sh                  # Apply enterprise ACLs
sudo ./security-audit.sh              # Verify security configuration
```

**See**: [`docs/infra/SECURITY_FRAMEWORK.md`](../../docs/infra/SECURITY_FRAMEWORK.md) for:
- 4-tier RBAC (read/ops/dev/admin groups)
- ACL mapping per directory
- ISO 27001/SOC 2 compliance
- Audit procedures

---

## 📝 Logs & Troubleshooting

If setup scripts fail, check:
```bash
# System logs
sudo journalctl -xe

# Docker installation
docker --version
docker compose version

# User groups (after logout/login)
groups

# Directory permissions
ls -la /opt/easyway
ls -la /var/lib/easyway
```

---

## 🔄 Re-running Scripts

All scripts are **idempotent** where possible:
- `setup-easyway-server.sh` - Safe to re-run; skips existing users/groups/directories
- `install-docker.sh` - May upgrade Docker if newer version available
- `open-ports.sh` - Adds rules only if missing

---

## ✨ Future Enhancements

Planned additions:
- [ ] `setup-monitoring.sh` - Install Prometheus/Grafana stack
- [ ] `setup-ssl-certs.sh` - Automated Let's Encrypt certificate provisioning
- [ ] `setup-backup-cron.sh` - Configure automated backups via cron
- [ ] `validate-infra.sh` - Post-setup validation script (verify all prerequisites)

---

## 📚 Related Documentation

- [`docs/infra/SECURITY_FRAMEWORK.md`](../../docs/infra/SECURITY_FRAMEWORK.md) - **LA BIBBIA** - Enterprise RBAC, ACLs, audit compliance
- [`docs/infra/SERVER_STANDARDS.md`](../../docs/infra/SERVER_STANDARDS.md) - Philosophy and design decisions
- [`docs/ORACLE_CURRENT_ENV.md`](../../docs/ORACLE_CURRENT_ENV.md) - Current production environment details
- [`scripts/ops/README.md`](../ops/README.md) - Operational scripts for day-to-day maintenance
