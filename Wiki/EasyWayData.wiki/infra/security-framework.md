---
title: Security Framework & Enterprise RBAC
tags: [security, rbac, infrastructure, compliance, audit, acl]
category: infrastructure
related:
  - infra/server-standards
  - deployment/server-bootstrap
  - governance/access-control
status: active
date: 2026-01-25
---

# 🔒 Security Framework - Enterprise RBAC Model

## Panoramica

EasyWay Data Portal utilizza un **modello di sicurezza enterprise-grade** basato su:
- **RBAC a 4 livelli** (Role-Based Access Control)
- **ACLs** (Access Control Lists) per controllo fine-grained
- **Compliance audit-ready** (ISO 27001, SOC 2, PCI-DSS)

> [!IMPORTANT]
> **Documentazione completa**: [`docs/infra/SECURITY_FRAMEWORK.md`](../../docs/infra/SECURITY_FRAMEWORK.md)  
> Questa pagina è un **sommario** per la Wiki. Per dettagli implementativi, vedi la bibbia di sicurezza.

---

## 🏢 Modello RBAC: 4 Gruppi di Sicurezza

### Architettura dei Gruppi

```
┌─────────────────────────────────────────────┐
│  easyway-read   (Read-only)                 │ ← Monitoring, Auditor
├─────────────────────────────────────────────┤
│  easyway-ops    (Deploy + Restart)          │ ← CI/CD, DevOps
├─────────────────────────────────────────────┤
│  easyway-dev    (Full Development)          │ ← Senior Developers
├─────────────────────────────────────────────┤
│  easyway-admin  (Full Control + sudo)       │ ← System Administrators
└─────────────────────────────────────────────┘
```

### Definizioni Gruppi

| Gruppo | Accesso | Membri Tipici | Use Cases |
|--------|---------|---------------|-----------|
| **`easyway-read`** | `r-x` (sola lettura) | Prometheus, Grafana, auditor, junior dev | View logs, check status, metrics |
| **`easyway-ops`** | `r-x` + deploy/restart | CI/CD pipeline, DevOps engineer | Deploy code, restart services |
| **`easyway-dev`** | `rwx` su code/logs | Senior developers | Modify code, debug, log analysis |
| **`easyway-admin`** | `rwx` + sudo | Sysadmin (`ubuntu`) | Infrastructure, DB, configs |

---

## 📂 ACL Mapping per Directory

| Directory | `read` | `ops` | `dev` | `admin` | Rationale |
|-----------|--------|-------|-------|---------|-----------|
| `/opt/easyway/bin` | `r-x` | **`rwx`** | `rwx` | `rwx` | Ops può deployare binari |
| `/opt/easyway/config` | `r--` | `r--` | `r--` | **`rwx`** | Solo admin modifica config |
| `/var/lib/easyway/db` | `---` | `---` | `---` | **`rwx`** | Database isolato |
| `/var/lib/easyway/backups` | `---` | `---` | `r-x` | **`rwx`** | Dev legge, admin scrive |
| `/var/log/easyway` | **`r-x`** | `r-x` | `rwx` | `rwx` | Logs visibili a tutti |

**Perché ACLs?**
- ✅ Controllo granulare (4 gruppi su stessa directory)
- ✅ Inheritance automatico (nuovi file ereditano permessi)
- ✅ Audit compliance (`getfacl` = prova per auditor)

---

## 🤖 Agent Identity & Authorization

### Mapping Agenti → Gruppi RBAC

Ogni agente dovrebbe avere un **security context** che definisce:
1. **required_group**: Gruppo minimo necessario
2. **can_sudo**: Se può eseguire comandi privilegiati
3. **restricted_paths**: Percorsi accessibili

#### Esempi Proposti

**Agent DBA** (gestione database):
```json
{
  "name": "agent_dba",
  "security": {
    "required_group": "easyway-admin",
    "can_sudo": true,
    "allowed_paths": ["/var/lib/easyway/db", "/opt/easyway/config"]
  }
}
```

**Agent Deployer** (CI/CD):
```json
{
  "name": "agent_deployer",
  "security": {
    "required_group": "easyway-ops",
    "can_sudo": false,
    "allowed_commands": ["docker restart", "docker compose up -d"]
  }
}
```

**Agent Monitor** (monitoring):
```json
{
  "name": "agent_monitor",
  "security": {
    "required_group": "easyway-read",
    "can_write": false,
    "allowed_paths": ["/var/log/easyway"]
  }
}
```

**Agent Governance** (quality gates):
```json
{
  "name": "agent_governance",
  "security": {
    "required_group": "easyway-admin",
    "can_approve": true,
    "scope": "all"
  }
}
```

### Enforcement

Prima di eseguire qualsiasi azione, l'agent framework dovrebbe:

1. **Verificare gruppo**: `id -nG agent-user | grep easyway-ops`
2. **Validare permessi**: `getfacl /target/path`
3. **Logging audit**: Registrare chi (agent) fa cosa (action) dove (path)

```bash
# Esempio check
if ! groups $AGENT_USER | grep -q "$REQUIRED_GROUP"; then
    echo "❌ Agent $AGENT_NAME requires group $REQUIRED_GROUP"
    exit 1
fi
```

---

## 🛠️ Quick Setup

### 1. Applicare Framework di Sicurezza

```bash
cd /path/to/EasyWayDataPortal

# Setup base (utenti, gruppi, directory)
sudo ./scripts/infra/setup-easyway-server.sh

# Applicare ACLs enterprise
sudo ./scripts/infra/apply-acls.sh

# Verificare
sudo ./scripts/infra/security-audit.sh
```

### 2. Aggiungere Utenti ai Gruppi

```bash
# Admin user
sudo usermod -aG easyway-admin,easyway-ops ubuntu

# CI/CD pipeline (ops-only)
sudo useradd -s /bin/bash -m ci-deploy
sudo usermod -aG easyway-ops ci-deploy

# Developer (senior)
sudo usermod -aG easyway-dev alice

# Monitoring agent (read-only)
sudo usermod -aG easyway-read prometheus-agent
```

### 3. Configurare Sudo Rules (opzionale)

Per permettere a `easyway-ops` di riavviare container senza full sudo:

```bash
sudo visudo -f /etc/sudoers.d/easyway-ops
```

Contenuto:
```sudoers
# Allow ops to restart containers
%easyway-ops ALL=(ALL) NOPASSWD: /usr/bin/docker restart easyway-*
%easyway-ops ALL=(ALL) NOPASSWD: /usr/bin/docker compose up -d
```

---

## 📊 Compliance & Audit

### Per Audit ISO 27001 / SOC 2

**Domanda auditor**: "Chi può accedere al database?"

**Risposta**:
```bash
# Mostra membri di easyway-admin (solo loro hanno accesso DB)
getent group easyway-admin

# Mostra ACLs su directory DB
getfacl /var/lib/easyway/db
```

**Domanda auditor**: "Come tracciate i cambiamenti di permessi?"

**Risposta**:
```bash
# Audit log per setfacl
sudo ausearch -c setfacl -ts recent

# Modifiche membri gruppo
sudo ausearch -c usermod -ts recent
```

### Export Configurazione per Audit

```bash
# Export gruppo membership
for group in easyway-read easyway-ops easyway-dev easyway-admin; do
    echo "=== $group ==="
    getent group $group
done > security-audit-$(date +%Y%m%d).txt

# Export ACLs
sudo getfacl -R /opt/easyway >> security-audit-$(date +%Y%m%d).txt
sudo getfacl -R /var/lib/easyway >> security-audit-$(date +%Y%m%d).txt
```

---

## 🔗 Risorse Correlate

### Documentazione Tecnica

- **La Bibbia**: [`docs/infra/SECURITY_FRAMEWORK.md`](../../docs/infra/SECURITY_FRAMEWORK.md) - Documentazione completa (15KB)
- **Server Standards**: [`docs/infra/SERVER_STANDARDS.md`](../../docs/infra/SERVER_STANDARDS.md) - FHS, directory structure
- **Current Environment**: [`docs/ORACLE_CURRENT_ENV.md`](../../docs/ORACLE_CURRENT_ENV.md) - Stato attuale server

### Script Implementazione

- [`scripts/infra/setup-easyway-server.sh`](../../scripts/infra/setup-easyway-server.sh) - Setup base
- [`scripts/infra/apply-acls.sh`](../../scripts/infra/apply-acls.sh) - Applica ACLs
- [`scripts/infra/security-audit.sh`](../../scripts/infra/security-audit.sh) - Audit completo
- [`scripts/infra/tests/verify-users.sh`](../../scripts/infra/tests/verify-users.sh) - Test utenti/gruppi
- [`scripts/infra/tests/verify-directories.sh`](../../scripts/infra/tests/verify-directories.sh) - Test directory/ACLs

### Wiki Correlate

- [Server Bootstrap Protocol](Runbooks/dual-server-bootstrap.md) - Setup server da zero
- [Deployment Decision MVP](deployment-decision-mvp.md) - Decisioni infrastruttura
- [Agent First Method](agent-first-method.md) - Metodologia agentica

---

## ❓ FAQ

**Q: Devo usare il modello enterprise o basic?**  
A: **Enterprise** se hai bisogno di audit compliance o team multipli. **Basic** se sei solo tu.

**Q: Come aggiungo un nuovo utente?**  
A: `sudo useradd -s /bin/bash -m john && sudo usermod -aG easyway-dev john`

**Q: Un agente può cambiare il proprio gruppo?**  
A: No. Solo un `easyway-admin` può modificare gruppi con `usermod`.

**Q: Cosa succede se un agente prova ad accedere a un path non autorizzato?**  
A: ACL nega l'accesso → `Permission denied` → l'agente deve loggare l'errore e fallire gracefully.

**Q: Posso avere un agente in più gruppi?**  
A: Sì! Esempio: un agente può essere in `easyway-dev` E `easyway-ops`.

---

## 🚀 Prossimi Passi

### Implementazione Immediata
1. [ ] Applicare security framework su Oracle Cloud server
2. [ ] Aggiornare manifest.json di tutti gli agenti con `security` block
3. [ ] Implementare enforcement check nel framework agenti
4. [ ] Testare con agent_monitor (read-only) e agent_deployer (ops)

### Roadmap Future
- [ ] Integrare con Azure Entra ID (SSO)
- [ ] Audit logging centralizzato (Loki/Grafana)
- [ ] Rotate secrets automation
- [ ] 2FA per admin group

---

**Maintainer**: Team EasyWay  
**Last Updated**: 2026-01-25  
**Status**: ✅ Framework documentato, pronto per implementazione
