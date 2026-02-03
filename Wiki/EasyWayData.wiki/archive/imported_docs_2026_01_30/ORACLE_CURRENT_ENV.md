---
id: ew-archive-imported-docs-2026-01-30-oracle-current-env
title: 🏗️ Oracle Cloud - Current Production Environment
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# 🏗️ Oracle Cloud - Current Production Environment

> **Status**: ACTIVE - Ambiente di produzione attuale  
> **Created**: 2026-01-25  
> **Last Deploy**: 2026-01-25 (via `deploy_easyway.ps1`)

---

## 📍 Server Details

| Parameter | Value |
|-----------|-------|
| **Provider** | Oracle Cloud |
| **IP Address** | `80.225.86.168` |
| **OS** | Ubuntu (version TBD) |
| **Admin User** | `ubuntu` |
| **SSH Key** | `C:\old\Virtual-machine\ssh-key-2026-01-25.key` |
| **Service User** | `easyway` |

---

## 🔧 Infrastructure Setup

### Directory Structure (FHS Standard)

Il server segue lo standard definito in [SERVER_STANDARDS.md](SERVER_STANDARDS.md):

```
/opt/easyway/          # Application root
├── bin/               # Scripts (start, stop)
├── config/            # Configuration files
├── current/           # Symlink to current release
└── releases/          # Version history

/var/lib/easyway/      # Persistent data
├── db/                # Database files
├── uploads/           # User uploads
└── backups/           # Local backups

/var/log/easyway/      # Application logs

/home/easyway/app      # Symlink → /opt/easyway (convenience)
```

### Users & Groups

- **Service User**: `easyway` (owner di app e dati)
- **Developer Group**: `easyway-dev` (include `ubuntu` e `easyway`)
- **Permissions**: `775` + SGID (gruppo ereditato automaticamente)

### Firewall Configuration

Porte aperte (via `open-ports.sh`):

| Port | Service | Protocol |
|------|---------|----------|
| 22 | SSH | TCP |
| 80 | HTTP (Standard) | TCP |
| 443 | HTTPS (Standard) | TCP |
| 8080 | EasyWay Portal (Frontend) | TCP |
| 8000 | EasyWay Cortex (Backend API) | TCP |

> ⚠️ **IMPORTANTE**: Le porte sono aperte anche su Oracle Cloud Console > Security List

---

## 🚀 Deployment Process

### From Local PC (Windows)

Il deployment avviene tramite script PowerShell da `c:\old\`:

#### Script: `deploy_easyway.ps1`

**Funzionamento**:
1. Legge Azure DevOps PAT da `c:\old\azure_pat.txt`
2. Si connette via SSH a `80.225.86.168`
3. Esegue il seguente flusso remoto:

```bash
# Clean previous deployment
rm -rf EasyWayDataPortal

# Clone repository
git clone https://Tokens:${PAT}@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal

# Navigate into repo
cd EasyWayDataPortal

# Fix line endings (CRLF → LF)
find . -type f -name "*.sh" -exec dos2unix {} \;

# Execute infrastructure setup
chmod +x scripts/infra/setup-easyway-server.sh
sudo ./scripts/infra/setup-easyway-server.sh
```

**Idempotenza**: Lo script `setup-easyway-server.sh` può essere eseguito più volte senza problemi.

#### Script: `monitor_deployment.ps1`

Verifica lo stato remoto:

```powershell
# Controlla symlink /opt/easyway/current
# Controlla status Docker containers
# Legge ultimi 10 log di easyway-runner
```

---

## 📦 Docker Stack (Complete)

Basato su `docker-compose.yml`, i seguenti containers sono attivi:

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| **easyway-runner** | Custom (agents/Dockerfile) | - | Container principale agenti PowerShell |
| **easyway-cortex** | chromadb/chroma:latest | 8000 | **Vector Database** (ChromaDB) per RAG |
| **easyway-db** | azure-sql-edge:latest | 1433 | Database SQL Edge (ARM compatible) |
| **easyway-storage** | azurite | 10000-10002 | Blob Storage Emulator (Azure compatible) |
| **easyway-portal** | nginx:alpine | 8080 | Frontend PWA (servito da nginx) |

### Volumi Persistenti

```
chroma-data       → /chroma/chroma (Vector DB data)
sql-data          → /var/opt/mssql (Database files)
azurite-data      → /data (Blob storage)
```

### Environment Variables

```bash
EASYWAY_MODE=Framework
OPENAI_API_KEY=${OPENAI_API_KEY}
DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
CHROMA_HOST=chromadb
SQL_SERVER=sql-edge
AZURITE_HOST=azurite
SQL_PASSWORD=${SQL_PASSWORD:-EasyWayStrongPassword1!}
```

### 🚧 n8n (Planned, Not Yet Deployed)

n8n orchestration è ampiamente documentato nella Wiki (`orchestrations/orchestrator-n8n.md`), ma **non è ancora nel docker-compose.yml**.

**Quando si aggiungerà n8n**:
```yaml
n8n:
  image: n8nio/n8n:latest
  ports:
    - "5678:5678"
  volumes:
    - n8n-data:/home/node/.n8n
```



---

## 🔐 Security Configuration

> [!IMPORTANT]
> **EasyWay utilizza un modello di sicurezza enterprise-grade** con RBAC a 4 livelli e ACLs.  
> **📖 Documentazione Completa**: [infra/SECURITY_FRAMEWORK.md](../../../../scripts/docs/infra/SECURITY_FRAMEWORK.md)

### Current Security Posture

**SSH Access**:
- ✅ Key-based authentication only (`ssh-key-2026-01-25.key`)
- ⚠️ Password authentication status: **TBD** (needs audit)
- ✅ Root login: **TBD** (needs audit)

**User & Group Model**:
- Service User: `easyway` (application owner)
- Admin User: `ubuntu` (infrastructure management)
- Groups: **TBD** (enterprise RBAC not yet applied - see [SECURITY_FRAMEWORK.md](../../../../scripts/docs/infra/SECURITY_FRAMEWORK.md))

**Secrets Management**:
- ⚠️ Azure DevOps PAT: Stored in `c:\old\azure_pat.txt` (NON commitare!)
- ⚠️ API keys: In environment variables (visible in `docker ps`) - needs migration to `.env` file

### Security TODO

- [x] Run `security-audit.sh` to assess current state
- [x] Apply enterprise RBAC model (4 groups: read/ops/dev/admin)
- [x] Apply ACLs via `apply-acls.sh`
- [x] Configure `.env` with 600 permissions
- [ ] Disable SSH password authentication (to be done during next maintenance)
- [ ] Configure sudo rules for ops group (to be done if needed)

### Current Security State (Updated 2026-01-25)

**RBAC Groups** (✅ Applied):
- `easyway-read` → Read-only (for monitoring tools)
- `easyway-ops` → Deploy + restart (added: ubuntu)
- `easyway-dev` → Full development (existing, members: easyway, ubuntu)
- `easyway-admin` → Full control (added: ubuntu)

**ACLs Applied** (✅ Complete):
- `/opt/easyway/config` → admin: rwx, ops/dev/read: r-- (config protection)
- `/var/lib/easyway/db` → admin: rwx, all others: --- (database isolation)
- `/var/lib/easyway/backups` → admin: rwx, dev: r-x (backup protection)
- `/var/log/easyway` → read: r-x, dev+: rwx (log transparency)

**Verification**:
```bash
# Check ACLs
getfacl /opt/easyway/config
getfacl /var/lib/easyway/db

# Check groups
getent group | grep easyway

# Security audit
cd ~/EasyWayDataPortal && sudo bash scripts/infra/security-audit.sh
```

---

## 🛠️ Common Operations

### Deploy Latest Code

```powershell
# Da PC Windows
cd c:\old
.\deploy_easyway.ps1
```

### Check Status

```powershell
# Da PC Windows
.\monitor_deployment.ps1
```

### Manual SSH Access

```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168
```

### View Logs Remotely

```bash
# Dopo SSH
sudo docker logs -f easyway-runner
```

---

## 📊 Known Issues / TODO

- [x] Documentare versione OS esatta (`lsb_release -a`)
- [x] Documentare lista completa containers Docker (fatto!)
- [x] **Aggiungere n8n al docker-compose** (FATTO 2026-01-27)
- [ ] Verificare se c'è reverse proxy (nginx/Caddy?) per HTTPS
- [ ] Documentare Azure SQL connection string location (se usato)
- [ ] Setup SSL certificates (Let's Encrypt?)

## 🛠️ Troubleshooting

### Container Name Conflicts ("Bind for ... failed")
Se durante il deploy ricevi errori come:
`Error response from daemon: Conflict. The container name "/easyway-db" is already in use`

Significa che ci sono vecchi container (creati manualmente) che bloccano il nuovo deploy.
**Soluzione (Force Clean)**:
```bash
# ATTENZIONE: Questo cancella TUTTI i container attivi sul server!
sudo docker rm -f $(sudo docker ps -a -q)
sudo docker network prune -f

# Rilancia il deploy
cd ~/EasyWayDataPortal && sudo docker compose up -d
```



---

## 🔄 Migration to Hetzner

Quando si decide di migrare a Hetzner:

1. **Stessa struttura**: Usare identici script `setup-easyway-server.sh`
2. **Stesso standard**: Directory `/opt/easyway`, utente `easyway`
3. **Adattare**: Cambiare IP in `deploy_easyway.ps1` da Oracle a Hetzner
4. **Firewall**: Su Hetzner usare UFW invece di iptables/Oracle Security List

---

**Maintainer**: Team EasyWay  
**Contact**: Via Azure DevOps Work Items



