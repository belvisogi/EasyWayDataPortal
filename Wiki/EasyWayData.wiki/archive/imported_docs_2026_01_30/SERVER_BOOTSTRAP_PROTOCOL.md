---
id: ew-archive-imported-docs-2026-01-30-server-bootstrap-protocol
title: 🛡️ Server Bootstrap & Security Protocol
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
type: guide
---
# 🛡️ Server Bootstrap & Security Protocol

> **Official Production Standard**
> Questo documento definisce lo standard per trasformare un server "grezzo" (Starter Kit) in un ambiente di produzione sicuro e gestibile.

## Server Matrix (Current vs Target)

| Server | Provider | Role | Status | Reference |
|---|---|---|---|---|
| Oracle VM | Oracle Cloud | Dev/Staging (current) | Attuale | `docs/infra/ORACLE_ENV_DOC.md`, `docs/infra/ORACLE_QUICK_START.md` |
| Hetzner VM | Hetzner Cloud | Production (future) | Target | `docs/HETZNER_SETUP_GUIDE.md` |

## Scope
- **Oracle (Dev/Staging)**: usa i riferimenti Oracle per accesso e snapshot, poi applica solo le parti necessarie di questo protocollo.
- **Hetzner (Production)**: questo protocollo si applica integralmente (hardening e standard di produzione).

## Remote Automation (Windows)
- Script remoti: `scripts/infra/remote/README.md`
- Config: copia `scripts/infra/remote/remote.config.example.ps1` in `scripts/infra/remote/remote.config.ps1` e compila i valori (oppure usa parametri)

## 1. Prerequisites & Provisioning

- **Hardware**: Hetzner Cloud CPX31 (4 vCPU, 8GB RAM) o superiore.
- **OS**: Ubuntu 22.04 LTS.
- **Network**: IPv4 pubblico statico.

## 2. Security Hardening (IMMEDIATO)

Appena ottenuto l'accesso `root`:

### 2.1 SSH Hardening
Non usare MAI password per root.

```bash
# 1. Copia la tua chiave pubblica locale (dal TUO pc)
ssh-copy-id root@<SERVER_IP>

# 2. Sul server, disabilita login via password
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/' /etc/ssh/sshd_config
# Disabilita login root (opzionale, consigliato creare utente admin prima)
# sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

systemctl restart sshd
```

### 2.2 UFW Firewall (Uncomplicated Firewall)
Chiudi tutto, apri solo il necessario.

```bash
apt update && apt install ufw -y

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow Critical Ports
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP (Portal)
ufw allow 443/tcp  # HTTPS (Portal)

# Enable
ufw enable
```

### 2.3 Azure SQL Firewall
Il server EasyWay deve accedere al database Azure SQL.
**Procedura manuale obbligatoria** (Hetzner Production). Per Oracle Dev/Staging applica solo se necessario:

1. Ottieni l'IP del server:
   ```bash
   curl ifconfig.me
   ```
2. Vai su **Azure Portal** > **SQL Server** > **Networking**.
3. Sotto "Firewall rules", aggiungi:
   - **Rule Name**: `EasyWay-Prod-Hetzner`
   - **Start IP**: `<SERVER_IP>`
   - **End IP**: `<SERVER_IP>`
4. Save.

## 3. Filesystem & User Standard

Abbandoniamo `/root`. Usiamo lo standard `/opt`.

### 3.1 Create Service User

```bash
# Crea utente 'easyway' senza login shell (o con shell se serve debug)
useradd -m -s /bin/bash easyway
usermod -aG docker easyway
```

### 3.2 Directory Structure

```bash
# Application Root
mkdir -p /opt/easyway/{bin,config,data,logs}

# Permissions
chown -R easyway:easyway /opt/easyway
chmod -R 775 /opt/easyway
```

### 3.3 Deploy Folder
Tutti i file di deploy (docker-compose.yml, .env) vanno in:
`file:///opt/easyway`

## 4. Service Management (Systemd)

Per garantire che i container partano al boot, usiamo Docker Restart Policy, ma per gestione avanzata usiamo un service.

**Docker Compose Approach (Recommended)**:
Nel `docker-compose.yml`, assicurati che ogni servizio abbia:
```yaml
restart: unless-stopped
```

**Alternative: Systemd Service**:
Crea `/etc/systemd/system/easyway.service`:
```ini
[Unit]
Description=EasyWay Data Portal Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/easyway
User=easyway
Group=easyway
ExecStart=/usr/bin/docker compose up -d --remove-orphans
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
```

Abilita:
```bash
systemctl enable easyway
```

## 5. Troubleshooting & Diagnostics

### 5.1 Connectivity Check
Se i servizi non partono, verifica le connessioni esterne.

**Test SQL Connection**:
```bash
# Da dentro il container runner (se attivo)
docker exec -it easyway-runner pwsh -c "Test-NetConnection -ComputerName 'vostro-server.database.windows.net' -Port 1433"

# Se fallisce: Controlla Azure SQL Firewall (Sezione 2.3)
```

**Test Internet/DNS**:
```bash
ping -c 4 google.com
```

### 5.2 Container Logs
Se un container crasha (es. `easyway-portal`), controlla i log specifici:

```bash
cd /opt/easyway
docker compose logs -f portal
```

### 5.3 Permission Denied
Se Docker non parte come utente `easyway`:
- Verifica gruppo: `groups easyway` (deve includere `docker`).
- Riavvia sessione o server se appena aggiunto.

---
**Riferimenti**:
- `docs/SERVER_STANDARDS.md` per dettagli filesytem.
- `agents/FAQ.md` per troubleshooting applicativo agenti.


