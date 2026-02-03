---
id: ew-infrastructure-oracle-cloud-01-hardware-storage-os
title: 1. Specifiche Hardware & Risorse
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
Hostname: oracle-agent
Hardware: Oracle Cloud Free Tier (ARM Ampere A1)
OS: Ubuntu Server 24.04 LTS
Stato Aggiornamento: Gennaio 2026

---

## 1. Specifiche Hardware & Risorse

Il server opera su ARM64 architettura con risorse generose gratuite (Oracle Always Free Tier).

|**Componente**|**Specifica Reale**|**Stato & Note Operative**|
|---|---|---|
|**CPU**|Ampere Altra (4 vCPU ARM64)|Performance ottima per AI workloads.|
|**RAM**|**24 GB**|Sufficiente per Ollama + DeepSeek-R1 7B + ChromaDB.|
|**Swap**|0 GB|Non configurato (RAM abbondante).|
|**Boot Drive**|96 GB SSD (Block Volume)|Veloce. I servizi si avviano in < 2 min post-reboot.|
|**Network**|Gigabit (Public IP)|IP Statico: `80.225.86.168`|

---

## 2. Mappa dello Storage (Filesystem)

Il sistema segue **TESS v1.0** (The EasyWay Server Standard).

### 💾 A. Disco Sistema (Root)

- **Device:** `/dev/sda1` (EXT4)
- **Mountpoint:** `/` (Root)
- **Contenuto:** OS, System Software
- **Policy:** Mantieni < 80% per evitare problemi Docker/System.

### 💾 B. Application Root (`/opt/easyway/`)

- **Struttura:** TESS v1.0 Canonical
  ```
  /opt/easyway/
  ├── bin/          # Eseguibili (easyway-agent, easyway-status)
  ├── lib/          # Python venv, scripts helper
  ├── etc/          # Config, aliases, secrets
  ├── var/          # Runtime data (logs, DB, knowledge-base)
  └── share/        # Docs, templates
  ```
- **Owner:** `root:easyway`
- **Permissions:** 755 (read-only app, runtime scrive in `var/`)

---

## 3. Gestione Permessi & Utenti

Per evitare conflitti e rispettare security best practices:

- **Utente Sistema:** `ubuntu` (UID: 1000, GID: 1000) - SSH access, sudo
- **Utente Runtime:** `easyway` (system user) - No sudo, solo runtime

### Comandi di Ripristino Permessi

Se l'agent non riesce a scrivere/leggere:

```bash
# Fix permissions su var/
sudo chown -R easyway:easyway /opt/easyway/var
sudo chmod 755 /opt/easyway/var

# Fix permissions su secrets/
sudo chmod 700 /opt/easyway/etc/secrets
```

---

## 4. Strategia di Backup

⚠️ **ATTENZIONE: Backup manuale richiesto (nessun automatismo configurato).**

Aree critiche a rischio perdita dati:

1. **Knowledge Base:** `/opt/easyway/var/data/knowledge-base/` (ChromaDB)
2. **Database Logs:** `/opt/easyway/var/logs/easyway.db` (SQLite)
3. **Configurazioni:** `/opt/easyway/etc/`

**Procedura di Backup Manuale:**

```bash
# Creare backup compresso
tar -czf /tmp/easyway-backup-$(date +%F).tar.gz \
  /opt/easyway/etc \
  /opt/easyway/var/data \
  /opt/easyway/var/logs

# Copiare su Object Storage o macchina locale
scp /tmp/easyway-backup-*.tar.gz user@backup-server:/backups/
```

**Restore:**

```bash
# Estrarre backup
sudo tar -xzf easyway-backup-2026-01-26.tar.gz -C /

# Fix permissions
sudo chown -R easyway:easyway /opt/easyway/var

# Restart services
sudo systemctl restart ollama
```

---

## 5. Network Configuration

|**Componente**|**Valore**|**Note**|
|---|---|---|
|**Public IP**|`80.225.86.168`|Statico (Oracle Cloud)|
|**Private IP**|`10.0.0.247`|VCN interno Oracle|
|**Hostname**|`oracle-agent`|Configurato in `/etc/hostname`|
|**DNS**|Cloudflare (1.1.1.1)|Automatico via DHCP|

### Porte Esposte (Firewall)

|**Porta**|**Servizio**|**Esposta?**|
|---|---|---|
|**22**|SSH|✅ Public (chiave only)|
|**11434**|Ollama API|❌ Localhost only|

**Security Rules**: Gestite tramite Oracle Cloud Console (Security Lists).

---

## 6. Software Inventory (SBOM)

Vedi documento dedicato: [`software-inventory.md`](./software-inventory.md)

**Summary**:
- Ollama (Latest)
- DeepSeek-R1 7B
- ChromaDB 1.4.1
- PowerShell 7.4.1
- Python 3.12 (venv)
- btop, glances, neofetch

---

## 7. Monitoring & Health Check

**Quick Status Command:**

```bash
easyway-status
```

**Output**:
- Ollama service status
- Models loaded
- Disk usage
- Memory usage
- System uptime

**Dashboard**: `btop` (alias: `status`)



