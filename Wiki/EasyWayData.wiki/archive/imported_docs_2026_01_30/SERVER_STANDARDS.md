---
id: ew-archive-imported-docs-2026-01-30-server-standards
title: Standard di Organizzazione Server EasyWay
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
# Standard di Organizzazione Server EasyWay

> Questo documento definisce lo standard per utenti, gruppi e struttura delle directory sui server EasyWay (Oracle Cloud / On-Premise).

## 1. Gestione Utenti e Ruoli (Roles)

Per evitare il caos di utenti multipli (`opc`, `ubuntu`, `produser`), definiamo ruoli chiari:

### 👑 System Administrator (`sysadmin`)
- **Utente OS**: `ubuntu` (o `opc` su Oracle Linux)
- **Ruolo**: Gestione infrastruttura, aggiornamenti, installazione pacchetti.
- **Accesso**: Solo via chiavi SSH.
- **Gruppi**: `sudo`, `docker`.

### 🤖 Application Service User (`easyway`)
- **Utente OS**: `easyway`
- **Ruolo**: Esecuzione dell'applicazione, proprietario dei file applicativi.
- **Accesso**:
    - **Nessun login shell** (sicurezza ottimale) OPPURE
    - **RDP/Desktop** (se necessario per sviluppo/test).
- **Gruppi**: `easyway`, `docker` (se deve gestire container).
- **Home**: `/home/easyway`.

### 👥 Developers (Es. `giuseppe`, `team`)
- **Utente OS**: `nome.cognome`
- **Ruolo**: Accesso per debug/sviluppo.
- **Accesso**: SSH con chiave personale.
- **Gruppi**: `easyway-dev` (per accesso in lettura/scrittura a cartelle condivise).

---

## 2. Alberatura Directory (Filesystem Hierarchy)

Abbandoniamo l'uso disordinato delle Home Directory per l'applicazione. Usiamo lo standard Linux FHS (`/opt` e `/var`).

### 📂 Root Applicativa: `/opt/easyway`
Tutto il codice e i file statici dell'applicazione risiedono qui.

```text
/opt/easyway/
├── bin/              # Script di avvio/stop (start.sh, stop.sh)
├── config/           # File di configurazione (.env, config.yaml)
├── current/          # Symlink alla versione corrente (per deploy atomic)
├── releases/         # Versioni precedenti (v1.0, v1.1)
└── docker-compose.yml
```

### 💾 Dati Persistenti: `/var/lib/easyway`
Database, volumi docker, file caricati dagli utenti.

```text
/var/lib/easyway/
├── db/               # PostgreSQL data files
├── redis/            # Redis dump
├── uploads/          # User uploaded files
└── backups/          # Backup locali (prima dell'upload su S3)
```

### 📝 Log Files: `/var/log/easyway`
Log centralizzati per facile consultazione (o via Docker logs).

```text
/var/log/easyway/
├── app.log
├── error.log
└── access.log
```

---

## 3. Gestione Permessi

Per garantire sicurezza e collaborazione:

1.  **Proprietario Applicazione**:
    ```bash
    sudo chown -R easyway:easyway /opt/easyway
    sudo chown -R easyway:easyway /var/lib/easyway
    ```

2.  **Gruppo Sviluppatori**:
    Creiamo un gruppo `easyway-dev` per permettere al team di editare config/codice senza usare `sudo` ovunque.
    ```bash
    sudo groupadd easyway-dev
    sudo usermod -aG easyway-dev ubuntu
    sudo usermod -aG easyway-dev easyway
    sudo chmod -R 775 /opt/easyway
    ```

---

## 🚀 Implementazione Rapida

Per applicare questa struttura su un server nuovo:

```bash
# 1. Crea struttura
sudo mkdir -p /opt/easyway/{bin,config,releases}
sudo mkdir -p /var/lib/easyway/{db,uploads,backups}
sudo mkdir -p /var/log/easyway

# 2. Crea utente applicativo (se non esiste)
sudo useradd -m -s /bin/bash easyway

# 3. Assegna permessi
sudo chown -R easyway:easyway /opt/easyway
sudo chown -R easyway:easyway /var/lib/easyway
sudo chown -R easyway:easyway /var/log/easyway

# 4. Link simbolico per facilità (Opzionale)
sudo ln -s /opt/easyway /home/easyway/app
```


