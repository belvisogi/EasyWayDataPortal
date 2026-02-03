---
id: ew-infrastructure-oracle-cloud-04-operations-maintenance
title: 📄 04 - Operations, Maintenance & Commands
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
# 📄 04 - Operations, Maintenance & Commands

Shell: Bash (/bin/bash)
Command Path: `/opt/easyway/bin/` (in$PATH via symlinks)
Aliases: `/opt/easyway/etc/aliases.sh`

---

## 1. Quick Commands Reference

### 🧭 Navigation (Aliases)

|**Comando**|**Destinazione**|
|---|---|
|`goto-easyway`|`/opt/easyway`|
|`goto-bin`|`/opt/easyway/bin`|
|`goto-logs`|`/opt/easyway/var/logs`|

### 🤖 AI Agent Operations

|**Comando**|**Funzione**|**Esempio**|
|---|---|---|
|`easyway-agent`|Esegui query RAG|`easyway-agent -Query "What is GEDI?"`|
|`easyway-status`|Health check rapido|`easyway-status`|
|`easyway-query`|Alias di `easyway-agent`|`easyway-query -Query "Test"`|
|`easyway-logs`|Tail logs real-time|`easyway-logs`|
|`easyway-db`|Apri SQLite audit log|`easyway-db` (interactive)|

### 📊 Monitoring

|**Comando**|**Funzione**|**Note**|
|---|---|---|
|`status`|Dashboard risorse (btop)|CPU/RAM/Network/Disk real-time|
|`monitor`|Advanced monitoring (glances)|Include I/O, temperature|
|`info`|System info banner (neofetch)|Quick overview del sistema|

### 🔧 System Maintenance

|**Comando**|**Funzione**|
|---|---|
|`sudo systemctl status ollama`|Status servizio Ollama|
|`sudo systemctl restart ollama`|Restart Ollama (se lento)|
|`ollama list`|Lista modelli installati|
|`df -h /opt/easyway`|Spazio disco /opt/easyway|
|`du -h /opt/easyway/var/data`|Dimensione knowledge base|

---

## 2. Operational Workflows

### Workflow A: Query Agent

```bash
# 1. Verificare che Ollama sia up
systemctl status ollama | grep Active

# 2. Eseguire query
easyway-agent -Query "Spiega la filosofia GEDI"

# 3. Verificare logs
easyway-logs
```

### Workflow B: Index Nuovo Documento

```bash
# 1. Copiare documento in /tmp/
scp newdoc.md ubuntu@80.225.86.168:/tmp/

# 2. Indexare in ChromaDB
python3 /opt/easyway/lib/scripts/chromadb_manager.py index /tmp/newdoc.md

# 3. Verificare indexed
easyway-agent -Query "test new doc"
```

### Workflow C: System Update

```bash
# 1. Update package list
sudo apt update

# 2. Upgrade (sicuro)
sudo apt upgrade -y

# 3. Reboot (se kernel update)
sudo reboot

# 4. Verificare servizi post-reboot
systemctl status ollama
easyway-status
```

---

## 3. Backup & Restore

### 💾 Backup Manuale (Mensile)

1. **Stop Ollama** (per evitare file corruption):
   ```bash
   sudo systemctl stop ollama
   ```

2. **Creare backup TAR**:
   ```bash
   sudo tar -czf /tmp/easyway-backup-$(date +%F).tar.gz \
     /opt/easyway/etc \
     /opt/easyway/var/data \
     /opt/easyway/var/logs
   ```

3. **Copiare off-server** (SCP o Object Storage):
   ```bash
   scp /tmp/easyway-backup-*.tar.gz user@backup-server:/backups/
   ```

4. **Riavviare Ollama**:
   ```bash
   sudo systemctl start ollama
   ```

### 💿 Restore Procedure

1. **Upload backup sul server**:
   ```bash
   scp easyway-backup-2026-01-26.tar.gz ubuntu@80.225.86.168:/tmp/
   ```

2. **Stop services**:
   ```bash
   sudo systemctl stop ollama
   ```

3. **Estrarre backup**:
   ```bash
   sudo tar -xzf /tmp/easyway-backup-2026-01-26.tar.gz -C /
   ```

4. **Fix permissions**:
   ```bash
   sudo chown -R easyway:easyway /opt/easyway/var
   ```

5. **Start services**:
   ```bash
   sudo systemctl start ollama
   ```

6. **Verify**:
   ```bash
   easyway-status
   easyway-agent -Query "Test after restore"
   ```

---

## 4. Troubleshooting Rapido

|**Sintomo**|**Diagnosi Probabile**|**Azione**|
|---|---|---|
|**Agent timeout**|Ollama down o lento|`sudo systemctl restart ollama`|
|**"ChromaDB not found"**|Python venv non attivo in script|Verificare shebang: `#!/opt/easyway/lib/python/.venv/bin/python3`|
|**"Permission denied" log write**|Permessi errati su `/opt/easyway/var/`|`sudo chown -R easyway:easyway /opt/easyway/var`|
|**Disco pieno**|Knowledge base o logs troppo grandi|`du -sh /opt/easyway/var/*` e cleanup|
|**SSH connection refused**|Firewall Oracle o IP banned|Verificare Security Lists in Console|

---

## 5. Manutenzione Periodica

### Settimanale
- [ ] Verificare spazio disco: `df -h /opt/easyway`
- [ ] Check Ollama status: `systemctl status ollama`
- [ ] Test query: `easyway-agent -Query "Test"`

### Mensile
- [ ] Backup completo (vedi sezione 3)
- [ ] Update sistema: `sudo apt update && sudo apt upgrade`
- [ ] Review logs: `easyway-db` → `SELECT * FROM agent_executions ORDER BY timestamp DESC LIMIT 100;`
- [ ] Cleanup vecchi backup: rimuovere `.tar.gz` > 90 giorni

### Trimestrale
- [ ] Security scan: `sudo lynis audit system`
- [ ] Rotate SSH key (se richiesto da policy)
- [ ] Review TESS compliance: verificare checklist standard

---

## 6. Performance Tuning

### Se Agent è Lento

1. **Verificare RAM disponibile**:
   ```bash
   free -h
   ```
   Se < 2GB liberi → considerare restart Ollama.

2. **Verificare CPU load**:
   ```bash
   uptime
   ```
   Se load > 4.0 → qualcosa sta saturando le CPU.

3. **Ridurre context length** (in script):
   ```powershell
   # In easyway-agent, modificare:
   max_tokens = 512  # invece di 2048
   ```

---

## 7. Disaster Recovery Quick Reference

### Scenario: Server Totalmente Perso

**RTO (Recovery Time Objective):** ~2 ore

**Checklist Rapida:**

1. [ ] Provision nuovo server Oracle (identico)
2. [ ] Installare Ubuntu 24.04
3. [ ] Eseguire script setup: `setup_stack.sh` (in `/opt/easyway/lib/scripts/`)
4. [ ] Restore backup: (vedi sezione 3)
5. [ ] Verificare: `easyway-status` + test query

**Prerequisiti:**
- ✅ Backup recente (< 30 giorni)
- ✅ Setup script aggiornato
- ✅ SSH key disponibile

---

## 8. Log Interpretation

### Agent Execution Log (SQLite)

**Query utili:**

```sql
-- Ultime 10 query
SELECT query, timestamp FROM agent_executions ORDER BY timestamp DESC LIMIT 10;

-- Query per parola chiave
SELECT * FROM agent_executions WHERE query LIKE '%GEDI%';

-- Statistiche giornaliere
SELECT DATE(timestamp) as day, COUNT(*) as queries 
FROM agent_executions 
GROUP BY day 
ORDER BY day DESC;
```

### System Logs

```bash
# Ollama logs
journalctl -u ollama -f

# SSH access logs
sudo tail -f /var/log/auth.log

# System errors
dmesg | tail -50
```

---

## 9. Contact & Escalation

**Primary Admin:** Team Platform (EasyWay)

**Escalation Path:**
1. Check troubleshooting table (sezione 4)
2. Review security assessment doc
3. Consult TESS standard doc
4. Escalate to architect if blocker

**Documentation References:**
- [`01-hardware-storage-os.md`](./01-hardware-storage-os.md)
- [`02-ai-services-stack.md`](./02-ai-services-stack.md)
- [`03-security-compliance.md`](./03-security-compliance.md)
- [`security-assessment.md`](./security-assessment.md)
- [`software-inventory.md`](./software-inventory.md)



