# Operations Scripts (`scripts/ops/`)

## 📋 Purpose

This directory contains **operational scripts** for recurring tasks: diagnostics, monitoring, restarts, and troubleshooting.

These scripts are meant to be run **on-demand** or **scheduled** to maintain the EasyWay Data Portal stack.

---

## 🔧 Scripts Overview

### 1. `check-chromadb-status.ps1`
**Purpose**: Health check for ChromaDB vector store  
**When to use**:
- After deployments to verify ChromaDB is running
- When debugging RAG/vectorization issues
- Before running vector-dependent operations

**Usage**:
```powershell
.\check-chromadb-status.ps1
```

**What it checks**:
- ✅ Container running status
- ✅ HTTP endpoint reachability (port 8000)
- ✅ API health (`/api/v1/heartbeat`)
- ✅ Collection list retrieval

---

### 2. `check-oracle-status.ps1`
**Purpose**: Verify Oracle XE database connectivity  
**When to use**:
- Before running ETL pipelines
- When debugging portal API connection issues
- During infrastructure maintenance

**Usage**:
```powershell
.\check-oracle-status.ps1
```

**What it checks**:
- ✅ Container running status
- ✅ TCP listener on port 1521
- ✅ SQL*Plus connectivity test

---

### 3. `fix-chromadb.ps1`
**Purpose**: Automated ChromaDB recovery and diagnostics  
**When to use**:
- When `check-chromadb-status.ps1` reports failures
- After crashes or unexpected container restarts
- Before escalating to full stack restart

**Usage**:
```powershell
.\fix-chromadb.ps1
```

**What it does**:
1. Runs full diagnostic (same as `check-chromadb-status.ps1`)
2. Attempts container restart if unhealthy
3. Re-validates health after restart
4. Reports recovery status

---

### 4. `restart-easyway-stack.ps1`
**Purpose**: Full stack restart (API + ChromaDB + Oracle)  
**When to use**:
- When individual fixes (`fix-chromadb.ps1`) don't resolve issues
- After configuration changes requiring full restart
- During scheduled maintenance windows

**Usage**:
```powershell
.\restart-easyway-stack.ps1
```

**What it does**:
1. Stops all EasyWay containers (`docker-compose down`)
2. Waits for clean shutdown
3. Restarts the stack (`docker-compose up -d`)
4. Verifies all services are running

---

## 🆚 `ops/` vs `infra/`

| Directory | Purpose | Frequency | Examples |
|-----------|---------|-----------|----------|
| **`infra/`** | Initial setup & bootstrapping | **One-time** (or rare) | `setup-easyway-server.sh`, `install-docker.sh`, `open-ports.sh` |
| **`ops/`** | Maintenance & operations | **Recurring** (on-demand or scheduled) | `check-*-status.ps1`, `fix-*.ps1`, `restart-*.ps1` |

---

## 📊 Recommended Workflow

### Daily/Scheduled Monitoring
```powershell
# Run health checks (can be scheduled via Task Scheduler)
.\check-chromadb-status.ps1
.\check-oracle-status.ps1
```

### Troubleshooting Progression
```powershell
# 1. Diagnose
.\check-chromadb-status.ps1

# 2. Attempt targeted fix
.\fix-chromadb.ps1

# 3. If still failing, full restart
.\restart-easyway-stack.ps1

# 4. Re-validate
.\check-chromadb-status.ps1
.\check-oracle-status.ps1
```

---

## 🔐 Prerequisites

All scripts require:
- Docker Desktop running
- PowerShell 7+ (for cross-platform compatibility)
- Working directory: `c:\old\EasyWayDataPortal\` (or adjust relative paths)

**Docker Compose Note**: Scripts assume `docker-compose.yml` is in the repository root.

---

## 📝 Logs & Debugging

For detailed container logs:
```powershell
# ChromaDB logs
docker logs chromadb

# Oracle logs
docker logs oracle-xe

# API logs
docker logs easyway-api
```

---

## ✨ Future Enhancements

Planned additions:
- [ ] `backup-vector-db.ps1` - Automated ChromaDB collection backups
- [ ] `export-oracle-logs.ps1` - Extract Oracle diagnostic logs
- [ ] `health-report.ps1` - Generate comprehensive health report (all services)
