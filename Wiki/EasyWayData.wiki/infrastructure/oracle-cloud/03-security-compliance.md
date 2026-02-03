---
id: ew-infrastructure-oracle-cloud-03-security-compliance
title: 📄 03 - Security, Access Control & Compliance
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
# 📄 03 - Security, Access Control & Compliance

Security Model: Defense in Depth
Access: SSH Key Only (No Password)
Compliance: TESS v1.0 + ISO 27001 Aware

---

## 1. Network Security

### Firewall (Oracle Cloud Security Lists)

**Inbound Rules:**

|**Porta**|**Protocollo**|**Sorgente**|**Scopo**|**Status**|
|---|---|---|---|---|
|**22**|TCP|0.0.0.0/0 (Public)|SSH Access|✅ OPEN|
|**11434**|TCP|❌ BLOCKED|Ollama API (localhost only)|🔒 CLOSED|

**Outbound:** All allowed (necessario per apt updates, model downloads).

### Service Exposition

- ✅ **Ollama**: Bind su `127.0.0.1:11434` (NO esposizione esterna)
- ✅ **ChromaDB**: File-based (NO network listener)
- ✅ **Agent**: CLI-only (NO web interface)

**Kill Switch:** Nessun servizio AI è raggiungibile dall'esterno. Solo SSH.

---

## 2. SSH Access Control

### Authentication

**Method:** SSH Key Only (no password authentication).

**Key Location (client):** `C:\old\Virtual-machine\ssh-key-2026-01-25.key`

**Key Type:** RSA 2048-bit (generata da Oracle Cloud Console)

**⚠️ Security Risk Identified:**
- Chiave memorizzata in path temporaneo (`C:\old\`)
- **Remediation (TODO):** Spostare in `~/.ssh/` con permissions 0600

### User Access Matrix

|**User**|**UID**|**Sudo**|**Purpose**|
|---|---|---|---|
|**ubuntu**|1000|✅ YES|Admin/SSH access|
|**easyway**|999 (system)|❌ NO|Runtime only|

**Policy:** Runtime services NON eseguono come root.

---

## 3. Data Security

### Secrets Management

**Path:** `/opt/easyway/etc/secrets/`

**Permissions:** `0700` (owner: `easyway`, only easyway can read)

**Current Content:** Empty (nessun secret configurato attualmente)

**Future Use:**
- API keys (se integriamo servizi esterni)
- Database credentials (se aggiungiamo PostgreSQL)

**⚠️ IMPORTANTE:** 
```bash
# Questa cartella è in .gitignore (sempre)
echo "/opt/easyway/etc/secrets/*" >> /opt/easyway/.gitignore
```

### Data at Rest

|**Data Type**|**Path**|**Encryption**|**Backup**|
|---|---|---|---|
|**Knowledge Base**|`/opt/easyway/var/data/knowledge-base/`|❌ Plain (no sensitive data)|⚠️ Manual|
|**Logs DB**|`/opt/easyway/var/logs/easyway.db`|❌ Plain|⚠️ Manual|
|**Ollama Models**|`~/.ollama/models/`|❌ Plain|Not critical (re-downloadable)|

**Risk Assessment:** LOW (no PII, no credentials stored).

---

## 4. Compliance Status

### TESS v1.0 Compliance

|**Requisito**|**Status**|**Note**|
|---|---|---|
|**Filesystem Hierarchy**|✅ PASS|`/opt/easyway/` structure conforme|
|**Python Venv**|✅ PASS|No `--break-system-packages`|
|**User Segregation**|✅ PASS|User `easyway` dedicato|
|**Secrets Dir**|✅ PASS|`/opt/easyway/etc/secrets/` (0700)|
|**Backup Script**|⚠️ PARTIAL|Manuale, non automatizzato|
|**Documentation**|✅ PASS|4 doc presenti|

**Overall:** 9/10 TESS Points

### GDPR Readiness

|**Principio**|**Status**|**Note**|
|---|---|---|
|**Data Minimization**|✅ OK|ChromaDB contiene solo doc pubblici Wiki|
|**Right to be Forgotten**|✅ OK|SQLite DELETE + ChromaDB purge|
|**Data Portability**|✅ OK|Backup .tar.gz esportabile|
|**Consent**|N/A|Sistema interno, no user tracking|
|**Audit Trail**|✅ OK|SQLite logga tutte le query|

**Verdict:** ✅ GDPR-Ready per uso interno

---

## 5. Vulnerability Management

### Current Posture

**Last Security Scan:** ❌ None

**Recommended Tools:**
```bash
# System hardening check
sudo lynis audit system

# Port scan
nmap -sV localhost

# Package vulnerabilities
sudo apt list --upgradable
```

**Update Policy:** Manual (no auto-updates configured).

**⚠️ Risk:** Potential unpatched CVEs in system packages.

**Remediation (TODO):**
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

---

## 6. Incident Response Plan

### Scenario A: Unauthorized SSH Access Detected

**Detection:** `journalctl -u ssh | grep "Failed password"`

**Response:**
1. Bloccare IP sorgente (Oracle Security Rules)
2. Ruotare SSH key
3. Audit `/var/log/auth.log`

### Scenario B: Ollama Service Compromised

**Detection:** Process anomalo, CPU spike, network activity insolita

**Response:**
1. `sudo systemctl stop ollama`
2. Backup `/opt/easyway/` completo
3. Reinstall Ollama da source ufficiale
4. Restore config

---

## 7. Security Hardening (Future)

### Recommended Improvements

- [ ] SSH: Disabilitare root login (`PermitRootLogin no`)
- [ ] SSH: Configurare Fail2Ban (auto-ban dopo N tentativi)
- [ ] Firewall: UFW enable (additional layer su Oracle Security Lists)
- [ ] Monitoring: Configurare audit daemon (`auditd`)
- [ ] Backup: Automatizzare backup giornaliero off-site
- [ ] Encryption: Considerare LUKS per `/opt/easyway/var/`

---

## 8. Audit Log

### SQLite Agent Executions

**Path:** `/opt/easyway/var/logs/easyway.db`

**Schema:**
```sql
CREATE TABLE agent_executions (
  id INTEGER PRIMARY KEY,
  query TEXT,
  answer TEXT,
  retrieved_docs TEXT,
  timestamp TEXT
);
```

**Query Audit:**
```bash
sqlite3 /opt/easyway/var/logs/easyway.db "SELECT * FROM agent_executions ORDER BY timestamp DESC LIMIT 10;"
```

**Retention:** Illimitato (nessuna rotazione configurata).

**⚠️ TODO:** Implementare log rotation (es. delete > 90 giorni).

---

## 9. Security Assessment Summary

**See:** [`security-assessment.md`](./security-assessment.md) per dettagli completi.

**Quick Stats:**
- **Funzionalità:** 5/5 ⭐
- **Security:** 3/5 ⭐ (MVP-grade, non Production)
- **Compliance:** 3/5 ⭐ (GDPR OK, ISO 27001 gaps)

**Blockers per Production:**
- No backup automatici
- No vulnerability scanning
- No MFA su SSH
- No monitoring/alerting



