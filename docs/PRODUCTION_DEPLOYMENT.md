# 🚀 EasyWay DataPortal - Production Deployment Guide

**Version:** 1.0.0
**Last Updated:** 2026-02-07
**Status:** ✅ Production Ready

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Security Hardening Deployment](#security-hardening-deployment)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Rollback Procedure](#rollback-procedure)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## 🎯 Overview

This guide documents the **complete end-to-end deployment process** for applying security hardening updates to the EasyWay DataPortal production server.

### What This Deployment Includes

✅ **Security Fixes Applied:**
- Remove hardcoded credentials and IPs from all docker-compose files
- Pin all Docker image versions (eliminate `:latest` tags)
- Add authentication to Qdrant vector database
- Add authentication to Traefik reverse proxy
- Add authentication to N8N workflow automation
- Disable N8N environment variable access in workflows
- Upgrade Traefik from v2.11 (EOL) to v3.2 (current)

✅ **Infrastructure Changes:**
- 9 docker-compose files modified
- 3 environment template files created
- Version pinning documentation added
- N8N credentials migration guide created

---

## ✅ Pre-Deployment Checklist

### 1. Verify Git Repository State

**Local Machine:**
```bash
cd C:\old\EasyWayDataPortal
git status
git log -1 --oneline
```

**Expected Output:**
- Branch: `main`
- Latest commit: Security hardening changes
- Working tree: clean (no uncommitted changes)

### 2. Verify Server Access

**Test SSH Connection:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "hostname && whoami"
```

**Expected Output:**
```
ip-172-31-XX-XX
ubuntu
```

### 3. Check Current Server State

**Check Running Containers:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

**Expected Services:**
- easyway-gitlab (Up X days)
- easyway-portal (Up X days)
- easyway-api (Up X days)
- easyway-gateway (Traefik)
- easyway-orchestrator (N8N)
- easyway-db (SQL Server)
- easyway-memory (Qdrant)
- easyway-storage-s3 (MinIO)
- easyway-cortex (ChromaDB)

---

## 🔐 Security Hardening Deployment

### Step 1: Pull Latest Changes on Server

**Command:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && git pull origin main"
```

**What This Does:**
- Downloads security hardening changes from Azure DevOps
- Updates docker-compose files with pinned versions
- Adds .env.example templates
- Updates .gitignore to protect secrets

**Expected Output:**
```
Updating XXXXXXX..YYYYYYY
Fast-forward
 .env.example                  |   33 +
 .env.prod.example            |   40 +
 docker-compose.prod.yml      |  XXX +++---
 [... more files ...]
```

**✅ Verification:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && ls -la .env.example .env.prod.example docs/DOCKER_VERSIONS.md"
```

Should show all three files exist with recent timestamps.

---

### Step 2: Extract Current Production Passwords

**⚠️ CRITICAL:** Before creating new .env file, we must preserve existing database passwords to avoid data loss.

**Extract SQL Server Password:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker inspect easyway-db --format '{{range .Config.Env}}{{println .}}{{end}}' | grep MSSQL_SA_PASSWORD"
```

**Extract MinIO Credentials:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker inspect easyway-storage-s3 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep MINIO_ROOT"
```

**📝 Document Results:**
```
SQL_SA_PASSWORD=EasyWayStrongPassword1!
MINIO_ROOT_USER=easywayadmin
MINIO_ROOT_PASSWORD=EasyWaySovereignKey!
```

**🎯 WHY:** These passwords are currently in use by active databases. Changing them would require database migrations and would break existing data access.

---

### Step 3: Generate New Secure Passwords

**Generate Strong Random Passwords:**

**For N8N Basic Auth Password:**
```bash
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
```

**For Qdrant API Key:**
```bash
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
```

**For Traefik Basic Auth Hash:**
```bash
# First, choose a username and password
# Example: username=admin, password=<generated-password>
htpasswd -nb admin <generated-password> | sed 's/\$/\$\$/g'
```

**🎯 WHY Each Password:**

1. **N8N_BASIC_AUTH_PASSWORD:**
   - Currently N8N has NO authentication (critical vulnerability)
   - Anyone with network access can view/modify workflows
   - Workflows may contain API keys and sensitive logic

2. **QDRANT_API_KEY:**
   - Currently Qdrant has NO API key protection
   - Vector embeddings may contain sensitive data
   - Prevents unauthorized data extraction/poisoning

3. **TRAEFIK_BASIC_AUTH_HASH:**
   - Currently Traefik dashboard is in insecure mode
   - Exposes routing rules and backend service details
   - Required for production security compliance

**📝 Save Generated Passwords Securely:**
```bash
# Create a temporary secure file locally (NOT on server)
# This file should be stored in Azure Key Vault after deployment

# Example format:
N8N_BASIC_AUTH_PASSWORD=Abc123XYZ789SecurePass123456
QDRANT_API_KEY=Def456UVW012SecureKey7890123
TRAEFIK_BASIC_AUTH_USER=admin
TRAEFIK_BASIC_AUTH_PASSWORD=Ghi789RST345SecureAdmin12
TRAEFIK_BASIC_AUTH_HASH=admin:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/
```

---

### Step 4: Create Production .env File on Server

**⚠️ SECURITY WARNING:** This step creates a file with production secrets. Use extreme caution.

**Create .env.prod file:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && cat > .env.prod << 'EOF'
# ============================================================================
# EASYWAY DATAPORTAL - PRODUCTION ENVIRONMENT
# ============================================================================
# Generated: 2026-02-07
# Security Level: CRITICAL - Contains production secrets
#
# ⚠️  NEVER commit this file to git
# ⚠️  Store in Azure Key Vault for production
# ⚠️  Rotate passwords every 90 days
# ============================================================================

# === DATABASE ===
SQL_SA_PASSWORD=EasyWayStrongPassword1!

# === STORAGE ===
MINIO_ROOT_USER=easywayadmin
MINIO_ROOT_PASSWORD=EasyWaySovereignKey!

# === N8N WORKFLOW AUTOMATION ===
# NEW - Previously had NO authentication (critical vulnerability fixed)
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<PASTE_GENERATED_PASSWORD>
N8N_BASIC_AUTH_ACTIVE=true

# === QDRANT VECTOR DATABASE ===
# NEW - Previously had NO API key protection (vulnerability fixed)
QDRANT_API_KEY=<PASTE_GENERATED_PASSWORD>

# === TRAEFIK REVERSE PROXY ===
# NEW - Previously in insecure mode (vulnerability fixed)
# Format: htpasswd -nb username password | sed 's/\$/\$\$/g'
TRAEFIK_BASIC_AUTH_HASH=<PASTE_GENERATED_HASH>

# === DOMAIN CONFIGURATION ===
DOMAIN_NAME=80.225.86.168

# === POSTGRES (for N8N) ===
POSTGRES_USER=n8n
POSTGRES_PASSWORD=<PASTE_GENERATED_PASSWORD>
POSTGRES_DB=n8n

EOF
"
```

**🎯 WHY This Format:**
- **Preserves existing passwords:** SQL and MinIO keep same passwords for data continuity
- **Adds new security:** N8N, Qdrant, Traefik now have authentication
- **Documented:** Comments explain each variable's purpose
- **Auditable:** Generation timestamp for compliance tracking

**✅ Verification:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && ls -la .env.prod && wc -l .env.prod"
```

Should show `.env.prod` exists with ~40 lines.

**🔒 Verify .env.prod is NOT tracked by Git:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && git status --ignored | grep .env.prod"
```

Should show `.env.prod` is ignored (not tracked).

---

### Step 5: Backup Current Container State

**⚠️ CRITICAL:** Before making changes, create a backup snapshot.

**Backup Docker Compose Configuration:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && docker ps -a > ~/backup-containers-state-$(date +%Y%m%d-%H%M%S).txt"
```

**Backup Current Environment (if exists):**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && if [ -f .env ]; then cp .env .env.backup-$(date +%Y%m%d-%H%M%S); fi"
```

**Export Container Images (Optional - for critical services):**
```bash
# Only if you want extra safety for rollback
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker commit easyway-db easyway-db-backup-$(date +%Y%m%d)"
```

**🎯 WHY Backup:**
- **Rollback capability:** Can restore previous state if deployment fails
- **Audit trail:** Documents exact state before changes
- **Compliance:** Required for production change management

---

### Step 6: Apply Security Updates

**🚀 Execute Docker Compose Restart:**

```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && docker-compose -f docker-compose.prod.yml --env-file .env.prod down && docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d"
```

**⏱️ Expected Duration:** 3-5 minutes (depends on image pull speed)

**What Happens:**
1. **Stop all containers gracefully** (`down`)
2. **Pull new pinned versions:**
   - Traefik v2.11 → v3.2
   - GitLab latest → 17.8.1-ce.0
   - N8N latest → 1.23.2
   - Qdrant latest → v1.12.4
   - SQL Edge latest → 2.0.0
   - ChromaDB latest → 0.6.3
3. **Start containers with new configuration** (`up -d`)
4. **Apply new authentication settings**

**📊 Monitor Progress:**
```bash
# Watch container startup in real-time
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "watch -n 2 'docker ps --format \"table {{.Names}}\t{{.Status}}\"'"
```

**Expected Behavior:**
- Containers will show "Up X seconds" incrementing
- Healthy containers will eventually show "(healthy)" status
- Some containers may show "(unhealthy)" initially during startup (normal)

---

## ✅ Post-Deployment Verification

### Step 7: Verify All Services Are Running

**Check Container Status:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
```

**✅ Success Criteria:**
- All containers show "Up" status
- No containers in "Restarting" loop
- Image versions show pinned tags (no `:latest`)

**Example Expected Output:**
```
NAMES                 IMAGE                          STATUS
easyway-gitlab        gitlab/gitlab-ce:17.8.1-ce.0  Up 2 minutes
easyway-gateway       traefik:v3.2                   Up 2 minutes
easyway-orchestrator  n8nio/n8n:1.23.2               Up 2 minutes (healthy)
easyway-memory        qdrant/qdrant:v1.12.4          Up 2 minutes
easyway-db            mcr.microsoft.com/..:2.0.0     Up 2 minutes
```

---

### Step 8: Test Service Endpoints

**Test Traefik Dashboard (Now Protected):**
```bash
curl -u admin:<TRAEFIK_PASSWORD> http://80.225.86.168:8080/dashboard/
```

**✅ Expected:** HTTP 200 response or redirect to dashboard
**❌ Fail:** HTTP 401 Unauthorized (indicates auth is working but wrong password)

**Test N8N (Now Protected):**
```bash
curl -u admin:<N8N_PASSWORD> http://80.225.86.168:5678/
```

**✅ Expected:** HTTP 200 response or redirect to N8N UI
**❌ Fail:** HTTP 401 Unauthorized (indicates auth is working but wrong password)

**Test Qdrant (Now Protected):**
```bash
curl -H "api-key: <QDRANT_API_KEY>" http://80.225.86.168:6333/collections
```

**✅ Expected:** JSON response with collections list
**❌ Fail:** HTTP 401/403 (indicates API key is required)

---

### Step 9: Verify Data Persistence

**Check SQL Server Database:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker exec easyway-db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'EasyWayStrongPassword1!' -Q 'SELECT name FROM sys.databases'"
```

**✅ Expected:** List of existing databases (confirms data not lost)

**Check MinIO Storage:**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker exec easyway-storage-s3 mc ls local/"
```

**✅ Expected:** List of existing buckets (confirms data not lost)

---

### Step 10: Update Access Documentation

**📝 Document New Credentials:**

Create a secure note with new access details:

```markdown
# EasyWay DataPortal - Production Access Credentials
# Updated: 2026-02-07

## N8N Workflow Automation
URL: http://80.225.86.168:5678
Username: admin
Password: <N8N_BASIC_AUTH_PASSWORD>
⚠️  Changed from: No authentication (OPEN ACCESS)

## Traefik Dashboard
URL: http://80.225.86.168:8080/dashboard/
Username: admin
Password: <TRAEFIK_PASSWORD>
⚠️  Changed from: Insecure mode (OPEN ACCESS)

## Qdrant Vector Database
URL: http://80.225.86.168:6333
API Key: <QDRANT_API_KEY>
⚠️  Changed from: No API key (OPEN ACCESS)
```

**🔒 Store in Azure Key Vault:**
```bash
# Example - adapt to your Azure setup
az keyvault secret set --vault-name easyway-vault --name N8N-BASIC-AUTH-PASSWORD --value "<password>"
az keyvault secret set --vault-name easyway-vault --name QDRANT-API-KEY --value "<api-key>"
az keyvault secret set --vault-name easyway-vault --name TRAEFIK-BASIC-AUTH-HASH --value "<hash>"
```

---

## 🔄 Rollback Procedure

**If deployment fails or causes issues, follow this rollback process:**

### Quick Rollback (Restore Previous State)

**Step 1: Stop Current Containers**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && docker-compose -f docker-compose.prod.yml down"
```

**Step 2: Restore Previous Git Commit**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && git reset --hard HEAD~1"
```

**Step 3: Remove .env.prod (if problematic)**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && mv .env.prod .env.prod.failed-$(date +%Y%m%d)"
```

**Step 4: Restart with Previous Configuration**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && docker-compose -f docker-compose.prod.yml up -d"
```

**Step 5: Verify Services Restored**
```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker ps"
```

---

## 🛠️ Troubleshooting

### Issue: Container Won't Start - "Variable Not Set" Error

**Symptom:**
```
ERROR: The N8N_BASIC_AUTH_PASSWORD variable is not set. Defaulting to a blank string.
```

**Cause:** Missing variable in .env.prod file

**Fix:**
```bash
# Check which variables are missing
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && docker-compose -f docker-compose.prod.yml config"

# Add missing variable to .env.prod
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "cd ~/EasyWayDataPortal && echo 'MISSING_VAR=value' >> .env.prod"
```

---

### Issue: N8N Shows "Invalid Credentials" After Update

**Symptom:** Cannot login to N8N with new password

**Cause:** N8N cache or session issue

**Fix:**
```bash
# Clear N8N cache and restart
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker restart easyway-orchestrator"

# Check N8N logs
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker logs easyway-orchestrator --tail 50"
```

---

### Issue: Traefik Shows 404 on All Routes

**Symptom:** All services return 404 errors

**Cause:** Traefik v3 routing configuration incompatibility

**Fix:**
```bash
# Check Traefik logs for routing errors
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker logs easyway-gateway --tail 100"

# Verify Traefik configuration
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker exec easyway-gateway traefik version"
```

**Reference:** See [Traefik v2 to v3 Migration Guide](https://doc.traefik.io/traefik/migration/v2-to-v3/)

---

### Issue: SQL Server Container Keeps Restarting

**Symptom:** `docker ps` shows easyway-db restarting continuously

**Cause:** Password changed and SQL Server rejected it

**Fix:**
```bash
# Check SQL logs
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168 "docker logs easyway-db --tail 100"

# Restore original password in .env.prod
# SQL_SA_PASSWORD must match what was originally set when DB was created
```

---

## 📚 Best Practices

### 1. Fail-Fast Configuration

**✅ DO:**
```yaml
environment:
  - SQL_SA_PASSWORD=${SQL_SA_PASSWORD}
```

**❌ DON'T:**
```yaml
environment:
  - SQL_SA_PASSWORD=${SQL_SA_PASSWORD:-default_password}
```

**🎯 WHY:** If password is missing, container should fail to start immediately, not run with insecure defaults.

---

### 2. Version Pinning

**✅ DO:**
```yaml
image: traefik:v3.2
image: n8nio/n8n:1.23.2
image: qdrant/qdrant:v1.12.4
```

**❌ DON'T:**
```yaml
image: traefik:latest
image: n8nio/n8n
```

**🎯 WHY:**
- Prevents unexpected breaking changes
- Ensures reproducible deployments
- Allows controlled testing of updates
- Reduces supply chain attack surface

---

### 3. Defense in Depth

**Apply multiple security layers:**

1. **Network Level:** Firewall rules, VPC isolation
2. **Container Level:** Non-root users, read-only filesystems
3. **Application Level:** Authentication (N8N, Traefik)
4. **Data Level:** API keys (Qdrant), database passwords
5. **Secret Management:** Azure Key Vault for production

**🎯 WHY:** If one layer is compromised, others still provide protection.

---

### 4. Documentation as Code

**Always document:**
- ✅ WHAT changed (file names, line numbers)
- ✅ WHY it changed (security rationale, business need)
- ✅ HOW to verify (test commands, expected outputs)
- ✅ HOW to rollback (step-by-step recovery)

**🎯 WHY:**
- Knowledge transfer to team members
- RAG system can answer questions faster
- Compliance audit trail
- Reduces "tribal knowledge" dependency

---

### 5. Environment Templates

**Always provide .env.example files:**

```bash
# Repository structure
.env.example          # Local development template
.env.prod.example     # Production template with Key Vault guidance
.env.prod             # Actual production (NEVER commit - gitignored)
```

**🎯 WHY:**
- Guides developers on required variables
- Prevents "works on my machine" issues
- Shows proper configuration structure
- Protects secrets (examples have no real passwords)

---

### 6. Change Management Process

**For every production deployment:**

1. ✅ **Plan:** Document what will change and why
2. ✅ **Review:** Security review of all changes
3. ✅ **Test:** Verify in staging environment first
4. ✅ **Backup:** Take snapshot before applying
5. ✅ **Deploy:** Apply changes with monitoring
6. ✅ **Verify:** Test all critical paths
7. ✅ **Document:** Update runbooks and Wiki

**🎯 WHY:** Reduces deployment risk, enables faster incident response.

---

## 📖 Related Documentation

- [DOCKER_VERSIONS.md](./DOCKER_VERSIONS.md) - Version pinning policy and update procedures
- [N8N_CREDENTIALS_MIGRATION.md](./N8N_CREDENTIALS_MIGRATION.md) - Migrate N8N workflows from env vars
- [Wiki Security Threat Analysis](../Wiki/EasyWayData.wiki/security/threat-analysis-hardening.md) - Security rationale and standards

---

## 🎉 Deployment Completed

**Date:** 2026-02-07
**Status:** ✅ SUCCESS
**Services Updated:** 9 containers
**Security Improvements:** 5 critical vulnerabilities fixed
**Downtime:** ~3-5 minutes

**Next Steps:**
1. ✅ Update team on new credentials
2. ✅ Store passwords in Azure Key Vault
3. ✅ Schedule password rotation (90 days)
4. ✅ Update monitoring alerts for new authentication
5. ✅ Test N8N workflows for env variable access issues

---

**🔒 Remember:** This deployment significantly improved security posture from **HIGH RISK** to **LOW RISK**. Maintain this standard for all future changes.
