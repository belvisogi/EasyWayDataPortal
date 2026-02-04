---
id: easyway-server-standard
title: The EasyWay Server Standard (TESS)
summary: Lo standard canonico per struttura, sicurezza e operazioni di tutti i server EasyWay. Questo è IL documento di riferimento.
status: active
owner: team-platform
tags: [standard, architecture, security, operations, canonical, domain/docs, layer/spec, audience/dev, privacy/internal, language/it]
updated: 2026-01-26
version: 1.0.0
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---

# The EasyWay Server Standard (TESS) v1.0

> **"Una struttura. Un linguaggio. Zero ambiguità."**

Questo documento definisce **LO STANDARD CANONICO** per tutti i server EasyWay (Oracle, Hetzner, on-premise, cloud). Non è un suggerimento: è **LA LEGGE**.

---

## 📐 Principi Fondamentali

### 1. **Separation of Concerns**
- **Codice** (scripts) separato da **Dati** (databases, logs)
- **Configurazioni** separate da **Runtime**
- **Sistema** (OS) separato da **Applicazioni** (EasyWay)

### 2. **Predictability**
- Chiunque deve poter fare SSH e sapere ESATTAMENTE dove cercare
- Nessun file in `~/` (tranne `.bashrc`, `.ssh/`, `.bash_history`)
- Path assoluti, mai relativi in produzione

### 3. **Idempotency**
- Setup script eseguibili infinite volte senza danni
- Backup ripristinabili senza configurazioni manuali
- Deployment riproducibile bit-a-bit

---

## 🗂️ FILESYSTEM HIERARCHY STANDARD (EasyWay FHS)

### Root Structure

```
/opt/easyway/                         # APPLICATION ROOT (System-level, owned by app)
├── bin/                              # Binari e script eseguibili (in PATH)
│   ├── easyway-agent*                # Main agent orchestrator
│   ├── easyway-backup*               # Backup utility
│   ├── easyway-status*               # Health check
│   └── easyway-index*                # Knowledge base indexer
│
├── lib/                              # Librerie e moduli condivisi
│   ├── python/                       # Python libraries (venv)
│   │   └── .venv/                    # Virtual environment (MANDATORY)
│   ├── powershell/                   # PowerShell modules
│   └── scripts/                      # Helper scripts (NOT in PATH)
│       ├── chromadb_manager.py
│       └── health_checks.sh
│
├── etc/                              # Configurazioni (READ-ONLY in runtime)
│   ├── agent.conf                    # Main config file
│   ├── aliases.sh                    # Bash aliases (sourced by users)
│   ├── environment.sh                # ENV variables
│   └── secrets/                      # Credenziali (0600 permissions)
│       └── .gitignore                # SEMPRE .gitignore questa cartella
│
├── var/                              # Dati variabili (RUNTIME, READ-WRITE)
│   ├── data/                         # Application data
│   │   ├── knowledge-base/           # ChromaDB / Vector storage
│   │   ├── models/                   # ML models (o symlink a ~/.ollama)
│   │   └── cache/                    # Temporary files
│   ├── logs/                         # Log files
│   │   ├── agent-{YYYY-MM-DD}.log    # Daily logs
│   │   ├── easyway.db                # SQLite audit log
│   │   └── archive/                  # Old logs (rotated)
│   └── backup/                       # Backup destination (local)
│       └── {YYYY-MM-DD}/
│
├── share/                            # Static resources
│   ├── docs/                         # Documentation
│   │   ├── 01-architecture.md
│   │   ├── 02-operations.md
│   │   ├── 03-security.md
│   │   └── 04-troubleshooting.md
│   └── templates/                    # Config templates
│
└── tmp/                              # Temporary (auto-cleanup)
```

### User Home (Minimalist)

```
/home/{user}/
├── .bashrc                           # Source /opt/easyway/etc/aliases.sh ONLY
├── .ssh/                             # SSH keys (0700)
│   ├── authorized_keys
│   └── config
└── .bash_history                     # Interactive history
```

**REGOLA**: Nient'altro. Tutto il resto va in `/opt/easyway/`.

---

## 🔐 SECURITY STANDARD

### File Permissions (Mandatory)

| Path | Owner | Permissions | Rationale |
|------|-------|-------------|-----------|
| `/opt/easyway/` | `root:easyway` | `755` | App read-only per sicurezza |
| `/opt/easyway/bin/*` | `root:easyway` | `755` | Eseguibili |
| `/opt/easyway/etc/secrets/` | `easyway:easyway` | `700` | Solo app legge |
| `/opt/easyway/var/` | `easyway:easyway` | `755` | App scrive runtime data |
| `/opt/easyway/var/logs/` | `easyway:easyway` | `750` | Read-only per audit |

### User & Group Policy (The Lego Role Model)

> **"A ogni mattoncino il suo incastro."**

| User | Role | Sudo? | Lego Metaphor |
|------|------|-------|---------------|
| `root` | **The Architect** | YES | Il terreno su cui si costruisce. Usato SOLO per setup iniziale (mount dischi, install package). MAI per runtime. |
| `ubuntu` | **The Builder** (Admin) | YES | Il costruttore. Usa `sudo` per assemblare i pezzi grossi. Non esegue l'applicazione. |
| `easyway` | **The Inhabitant** (Service) | **NO** | L'abitante. Vive nella casa (`/opt/easyway`). Accende le luci (Agenti, n8n). Non può abbattere i muri. |
| `ollama` | **The Furnace** (Daemon) | **NO** | La caldaia. Sta in cantina (Systemd). Fa una sola cosa (LLM). Isolato da tutto il resto. |

**Regola d'Oro**:
- **Setup**: `ubuntu` con `sudo`.
- **Runtime**: `easyway` senza `sudo`.
- **Emergenza**: `root` (console access).

### Secret Management

### Secret Management

**MANDATORY**:
- ❌ **MAI** hardcodare secret in script
- ✅ Usare `/opt/easyway/etc/secrets/` (0600)
- ✅ Oppure environment variables
- ✅ Oppure Oracle Cloud Vault (KMS)

---

## 🐍 PYTHON STANDARD

### Virtual Environment (MANDATORY)

```bash
# Setup
python3 -m venv /opt/easyway/lib/python/.venv

# Activation in scripts
#!/opt/easyway/lib/python/.venv/bin/python3
```

**REGOLA**: ❌ **MAI** `pip install --break-system-packages`

### Dependency Management

**File**: `/opt/easyway/lib/python/requirements.txt`

```txt
chromadb==1.4.1
sentence-transformers==2.5.1
numpy==1.26.3
pandas==2.1.4
```

**Lockfile**: `/opt/easyway/lib/python/requirements.lock` (generato da `pip freeze`)

---

## 🐚 POWERSHELL STANDARD

### Module Path

```powershell
# Installare moduli in:
/opt/easyway/lib/powershell/Modules/

# Configurare $env:PSModulePath
$env:PSModulePath += ":/opt/easyway/lib/powershell/Modules"
```

### Script Template

```powershell
#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    [Descrizione breve]
.DESCRIPTION
    [Descrizione completa]
.EXAMPLE
    easyway-agent -Query "Test"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Query
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import modules
Import-Module /opt/easyway/lib/powershell/Modules/EasyWayCore

# Main logic
...
```

---

## 🐳 DOCKER STANDARD (The Appliance Layer)

> **"Gli Elettrodomestici."**
> I container sono "Elettrodomestici": si attaccano alla presa, fanno il lavoro, si staccano.
> Non devono MAI sporcare il "Muro" (Host OS).

### Directory Structure
```
/opt/easyway/containers/           # Container Root
├── n8n/
│   ├── docker-compose.yml         # Definition
│   ├── .env                       # Config (Secrets via variable)
│   └── data/                      # Persistent Volume (Mapped)
└── chromadb/                      # (Optional if not using process)
```

### Naming Convention
- **Container**: `easyway-{service}` (es. `easyway-n8n`)
- **Network**: `easyway-net` (Internal bridge)
- **Volumes**: `easyway-{service}-data`
- **Storage Type**: **BIND MOUNT** (su host) preferito rispetto a Docker Volume.
  - *Rationale*: Configurazione e dati devono essere visibili/editabili da agenti sull'host.
  - Path: `./data:/home/node/.n8n` (relative to compose file)

### User Identity (The 1000 Problem)
I container DEVONO girare con UID/GID dell'utente `easyway` (es. 1003:1004) per evitare file root.
```yaml
user: "1003:1004" # Match host easyway user
```

### Integration Pattern: "The Remote Brain"
Come fa un Container (n8n) a lanciare script sull'Host (Agenti)?
**Protocollo**: SSH.

1. Il Container (n8n) ha una chiave SSH privata.
2. L'Host ha la chiave pubblica in `/home/easyway/.ssh/authorized_keys`.
3. n8n esegue: `ssh easyway@host.docker.internal '/opt/easyway/bin/agent-gedi ...'`

**Perché?**
- Mantiene l'Host pulito (niente Node.js/Python dependencies di n8n sull'OS).
- Mantiene l'isolamento (Il container non vede il filesystem host se non via SSH limitato).
- È "Portable": n8n potrebbe essere su un altro server domani.

---

### Aliases (Canonical)

**File**: `/opt/easyway/etc/aliases.sh`

```bash
#!/bin/bash
# EasyWay Standard Aliases v1.0

# === Navigation ===
alias goto-easyway='cd /opt/easyway'
alias goto-bin='cd /opt/easyway/bin'
alias goto-logs='cd /opt/easyway/var/logs'
alias goto-data='cd /opt/easyway/var/data'

# === Monitoring ===
alias status='btop'                   # System dashboard
alias monitor='glances'               # Advanced monitoring
alias info='neofetch'                 # System info
alias easyway-status='easyway-status' # Agent health

# === Operations ===
alias easyway-query='easyway-agent'
alias easyway-logs='tail -f /opt/easyway/var/logs/agent-$(date +%F).log'
alias easyway-db='sqlite3 /opt/easyway/var/logs/easyway.db'

# === Maintenance ===
alias easyway-backup='sudo /opt/easyway/bin/easyway-backup'
alias easyway-update='sudo /opt/easyway/bin/easyway-update'
alias easyway-restart='sudo systemctl restart easyway-agent'
```

### Systemd Service (MANDATORY per Production)

**File**: `/etc/systemd/system/easyway-agent.service`

```ini
[Unit]
Description=EasyWay AI Agent Service
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=easyway
Group=easyway
WorkingDirectory=/opt/easyway
Environment="PATH=/opt/easyway/bin:/usr/local/bin:/usr/bin"
ExecStart=/opt/easyway/bin/easyway-agent --daemon
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

---

## 🔄 BACKUP STANDARD

### Backup Strategy (3-2-1 Rule)

- **3** copie dei dati
- Su **2** media diversi
- **1** copia off-site

### Backup Script Template

**File**: `/opt/easyway/bin/easyway-backup`

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/easyway/var/backup/$(date +%F)"
BACKUP_NAME="easyway-backup-$(date +%F_%H%M%S).tar.gz"

mkdir -p "$BACKUP_DIR"

# Stop services
sudo systemctl stop easyway-agent ollama

# Backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
  /opt/easyway/etc \
  /opt/easyway/var/data \
  /opt/easyway/var/logs

# Restart services
sudo systemctl start ollama easyway-agent

echo "✅ Backup saved: $BACKUP_DIR/$BACKUP_NAME"
```

### Restore Procedure

```bash
# 1. Extract
sudo tar -xzf easyway-backup-YYYY-MM-DD.tar.gz -C /

# 2. Fix permissions
sudo chown -R easyway:easyway /opt/easyway/var

# 3. Restart
sudo systemctl restart easyway-agent
```

---

## 📖 DOCUMENTATION STANDARD

Ogni server DEVE avere questi 4 documenti in `/opt/easyway/share/docs/`:

### 1. `01-architecture.md`
- Hardware specs
- Storage layout
- Network topology
- Software inventory (SBOM)

### 2. `02-operations.md`
- Command reference (alias)
- Common tasks
- Troubleshooting table

### 3. `03-security.md`
- Security assessment
- Access control
- Compliance status
- Audit logs

### 4. `04-disaster-recovery.md`
- Backup procedure
- Restore procedure
- DR plan
- RTO/RPO targets

---

## ✅ COMPLIANCE CHECKLIST

Prima di dichiarare un server "Standard-Compliant":

- [ ] Struttura `/opt/easyway/` completa
- [ ] Python in venv (no `--break-system-packages`)
- [ ] Secrets in `/opt/easyway/etc/secrets/` (0600)
- [ ] Systemd service configurato
- [ ] Backup script testato
- [ ] 4 doc presenti e aggiornati
- [ ] Alias standard caricati
- [ ] User `easyway` creato (non root runtime)
- [ ] Firewall configurato (solo porte necessarie)
- [ ] No file in `~/` (tranne .bashrc/.ssh)

---

## 🚀 MIGRAZIONE DA "MVP DISORDINATO"

### Quick Migration Script

```bash
#!/bin/bash
# migrate-to-standard.sh

echo "🔄 Migrating to EasyWay Server Standard..."

# 1. Create structure
sudo mkdir -p /opt/easyway/{bin,lib/python,etc,var/{data,logs,backup},share/docs,tmp}

# 2. Create user
sudo groupadd easyway || true
sudo useradd -r -g easyway -s /bin/bash -d /opt/easyway easyway || true

# 3. Move scripts
sudo mv ~/agent-retrieval.ps1 /opt/easyway/bin/easyway-agent
sudo mv ~/chromadb_manager.py /opt/easyway/lib/scripts/
sudo mv ~/check-agent-health.sh /opt/easyway/bin/easyway-status

# 4. Move data
sudo mv ~/easyway-kb /opt/easyway/var/data/knowledge-base
sudo mv ~/easyway.db /opt/easyway/var/logs/

# 5. Create venv
python3 -m venv /opt/easyway/lib/python/.venv
source /opt/easyway/lib/python/.venv/bin/activate
pip install -r /opt/easyway/lib/python/requirements.txt

# 6. Fix permissions
sudo chown -R root:easyway /opt/easyway
sudo chown -R easyway:easyway /opt/easyway/var
sudo chmod 755 /opt/easyway/bin/*

echo "✅ Migration complete! Verify with: easyway-status"
```

---

## 📊 MONITORING STANDARD

### Required Dashboards

1. **System**: btop / glances
2. **Application**: Custom health check
3. **Logs**: Centralized logging (optional: Loki)

### Health Check Script

```bash
#!/bin/bash
# /opt/easyway/bin/easyway-status

echo "🤖 EasyWay Agent - Health Check"
echo "================================"

# Ollama
systemctl status ollama --no-pager | grep -E "Active|Memory"

# Models
ollama list

# Disk
df -h /opt/easyway | tail -1

# Memory
free -h | grep Mem

# Service
systemctl status easyway-agent --no-pager | grep Active
```

---

## 🔖 VERSIONING

Questo standard segue **Semantic Versioning** (SemVer):

- **MAJOR**: Breaking changes (es. cambio path root)
- **MINOR**: New features (es. nuova cartella opzionale)
- **PATCH**: Bug fix documentation

**Current Version**: `1.0.0` (2026-01-26)

---

## 📚 References

- [Filesystem Hierarchy Standard (Linux)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html)
- [12-Factor App Methodology](https://12factor.net/)
- [EasyWay Philosophy (GEDI)](../concept/architectural-vision.md)

---

**This is THE LAW. Deviations require architectural review.**

**Author**: EasyWay Platform Team  
**Status**: CANONICAL  
**Next Review**: 2026-06-26 (6 months)



