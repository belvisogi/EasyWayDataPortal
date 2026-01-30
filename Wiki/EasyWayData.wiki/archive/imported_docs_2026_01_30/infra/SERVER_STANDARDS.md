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

> [!IMPORTANT]
> **Enterprise Security Model**: EasyWay utilizza un modello RBAC a 4 livelli con ACLs per controllo fine-grained.  
> **📖 Documentazione Completa**: [SECURITY_FRAMEWORK.md](SECURITY_FRAMEWORK.md)

### Quick Summary

Per garantire sicurezza enterprise-grade e audit compliance:

**4 Gruppi di Sicurezza**:
- `easyway-read` → Sola lettura (monitoring, auditor)
- `easyway-ops` → Deploy e restart (CI/CD)
- `easyway-dev` → Accesso sviluppo completo
- `easyway-admin` → Controllo amministrativo totale

**ACLs per Controllo Granulare**:
```bash
# Directory configs: solo admin può modificare
/opt/easyway/config → admin: rwx, dev/ops: r--, read: r--

# Directory DB: solo admin ha accesso
/var/lib/easyway/db → admin: rwx, all others: ---

# Logs: tutti possono leggere, dev+ possono scrivere
/var/log/easyway → read: r-x, ops: r-x, dev: rwx, admin: rwx
```

### Setup Rapido

**Opzione 1: Basic Model** (per team piccoli, no audit)
```bash
# Creazione gruppo sviluppatori semplice
sudo groupadd easyway-dev
sudo usermod -aG easyway-dev ubuntu
sudo usermod -aG easyway-dev easyway
sudo chmod -R 775 /opt/easyway
```

**Opzione 2: Enterprise Model** (consigliato per produzione)
```bash
# Applica framework di sicurezza completo
sudo ./scripts/infra/setup-easyway-server.sh  # Crea utenti, gruppi, directory
sudo ./scripts/infra/apply-acls.sh            # Applica ACLs granulari

# Verifica
sudo ./scripts/infra/security-audit.sh
```

**Per dettagli completi su RBAC, ACLs, audit compliance, e manutenzione**: vedere [SECURITY_FRAMEWORK.md](SECURITY_FRAMEWORK.md)

---

## 🚀 Implementazione Rapida (L'Agente)

Non fare nulla a mano. Usa l'Infrastructure Agent:

1.  Scarica la repo sulla VM.
2.  Lancia lo script idempotente:
    ```bash
    sudo ./EasyWayDataPortal/scripts/infra/setup-easyway-server.sh
    ```

Questo script:
- ✅ Crea utenti e gruppi
- ✅ Crea la struttura `/opt` e `/var`
- ✅ Applica i permessi corretti (775 + SGID)
- ✅ Crea i symlink di comodità


---

## 🛠️ EasyWay Infrastructure Agent (The Builder)

**Missione**: Replicare infrastrutture "come se non ci fosse un domani". Distruggere, Ricostruire, Scalare. Zero attrito.

### 🧠 Competenze (Skills)
- **Oracle Cloud Master**: Conosce a memoria i parametri delle VM ARM Ampere (Free Tier).
- **Firewall Breaker**: Inietta automaticamente script Cloud-Init per aprire le porte (iptables) prima ancora che l'OS finisca il boot.
- **Desktop Artificer**: Trasforma una shell Ubuntu vuota in un ambiente Desktop completo (GNOME + XRDP) in 15 minuti netti.
- **Self-Healing**: Se una VM non risponde al ping (SSH Timeout), non aspetta: la distrugge e ne crea una nuova corretta.

