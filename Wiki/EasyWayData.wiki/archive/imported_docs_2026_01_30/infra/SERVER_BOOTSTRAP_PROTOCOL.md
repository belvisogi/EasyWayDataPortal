---
id: ew-archive-imported-docs-2026-01-30-infra-server-bootstrap-protocol
title: 🤖 Server Bootstrap Protocol (The EasyWay Golden Path)
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
# 🤖 Server Bootstrap Protocol (The EasyWay Golden Path)

> **Obiettivo**: Trasformare un server "nudo" (Ubuntu Fresh Install) in un nodo EasyWay operativo in meno di 10 minuti.
> **Target**: Infrastructure Agent (Umano o AI).

**Scope**:
- Production target: Hetzner (future). Questo protocollo si applica integralmente.
- Dev/Staging current: Oracle VM. Usa `docs/infra/ORACLE_ENV_DOC.md` e `docs/infra/ORACLE_QUICK_START.md` per l'accesso, poi applica solo le parti necessarie qui.

---

## ⏱️ Tabella di Marcia (Time Budget)

| Step | Azione | Script / Tool | Tempo Stimato |
|------|--------|---------------|---------------|
| 1 | **Accesso & Clone** | `git clone` | 30 sec |
| 2 | **Standardizzazione** | `setup-easyway-server.sh` | 10 sec |
| 3 | **Piattaforma (Docker)** | `install-docker.sh` | 3 min |
| 4 | **Segreti (.env)** | `setup-env.sh` | 1 min (Manuale) |
| 5 | **Deploy Atomico** | `deploy-local.sh` | 10 sec |
| **TOT** | **Ready to Serve** | | **< 5 min** |

---

## 📜 Procedura Dettagliata

### 0. Prerequisiti
- Server Linux (Ubuntu 22.04/24.04 ARM64 o AMD64).
- Accesso SSH root/sudoer.
- Token Azure DevOps (PAT) per clonare la repo.

### 0.1 Automazione remota da Windows (opzionale)
Se vuoi orchestrare il bootstrap da Windows, usa gli script in:
- `scripts/infra/remote/`

Leggi prima: `scripts/infra/remote/README.md` per prerequisiti e sequenza.

**Nota**: copia `scripts/infra/remote/remote.config.example.ps1` in `scripts/infra/remote/remote.config.ps1` e compila IP/Key/PatPath (oppure passa i parametri al momento dell'esecuzione).

**Safety**: esegui sempre prima con `-WhatIf` (dry-run), poi senza `-WhatIf` quando la preflight e' verde.

### 1. Inizializzazione Workspace (La Cava)
Il primo passo è portare l'intelligenza (il codice) sul server.

```bash
# Sostituisci TOKEN con il tuo PAT
git clone https://Token:IL_TUO_PAT@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal
cd EasyWayDataPortal
```

---

### 2. Standardizzazione Infrastruttura (The Builder)
Creiamo utenti, gruppi e cartelle secondo lo standard `SERVER_STANDARDS.md`.

```bash
chmod +x scripts/infra/*.sh
sudo ./scripts/infra/setup-easyway-server.sh
```

**Esito atteso**:
- Creazione utente `easyway`.
- Creazione cartelle `/opt/easyway` e `/var/lib/easyway`.
- Permessi 775 applicati.

---

### 3. Installazione Piattaforma (The Engine)
Installiamo il motore Docker e Docker Compose.

```bash
sudo ./scripts/infra/install-docker.sh
```

**Esito atteso**:
- Docker Engine attivo.
- Gruppo `docker` configurato per `ubuntu` e `easyway`.
- **Nota**: Potrebbe essere necessario fare logout/login per aggiornare i gruppi.

---

### 4. Configurazione Segreti (The Keys)
Iniettiamo le variabili d'ambiente (API Keys, Password DB). Questo step è interattivo per sicurezza.

```bash
sudo ./scripts/infra/setup-env.sh
```

**Esito atteso**:
- Generazione file `/opt/easyway/config/.env` con permessi ristretti (640).

---

### 5. Deploy Atomico (The Switch)
Spostiamo il codice dalla "Cava" (Home) al "Tempio" (Runtime) e accendiamo.

```bash
sudo ./scripts/ci/deploy-local.sh
```

**Esito atteso**:
- Codice copiato in `/opt/easyway/releases/YYYYMMDD...`.
- Link `/opt/easyway/current` aggiornato.

---

### 6. Accensione (Ignition)
Tutto è pronto. Avviamo lo stack.

```bash
cd /opt/easyway/current
sudo docker compose up -d
```

---

## 🛠️ Manutenzione e Aggiornamenti

Quando il codice cambia su Azure DevOps:

1.  **Aggiorna la Cava**: `git pull` in `~/EasyWayDataPortal`.
2.  **Riesegui Deploy**: `sudo ./scripts/ci/deploy-local.sh`.
3.  **Ricarica Container**: `docker compose up -d`.

*Nessun downtime percepibile grazie ai symlink atomici (se gestiti con load balancer, altrimenti minimo restart dei container).*


