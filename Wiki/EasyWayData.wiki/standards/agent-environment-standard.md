---
id: agent-environment-standard
title: Agent Runtime Environment Standard
summary: Proposal per standardizzare l'esecuzione degli agenti usando Docker e uv, garantendo consistenza tra Local, Oracle e Hetzner.
owner: team-platform
status: proposal
tags: [standard, architecture, python, powershell, docker]
updated: 2026-01-26
---

# Agent Runtime Environment Standard

> **Obiettivo**: Eliminare "Funziona sul mio PC" e problemi come PEP 668 o conflitti di architettura (ARM vs x86).

## 1. Il Problema
Durante il deploy su Oracle Cloud (ARM) abbiamo riscontrato:
1.  **Dependency Hell**: Ubuntu 24.04 blocca `pip install` globale (PEP 668).
2.  **Architecture Mismatch**: I package apt di PowerShell non sempre supportano ARM correttamente out-of-the-box.
3.  **Reproducibility**: Lo script che va su Windows potrebbe non andare su Linux se le versioni differiscono.

## 2. La Soluzione: "Docker-First"

Invece di installare Python e PowerShell *sul server* (Host), li installiamo *dentro* un container che definiamo noi.

### 🏗️ 2.1 Architettura Proposed

```mermaid
graph TD
    subgraph "Server (Oracle/Hetzner)"
        HOST[Host OS (Ubuntu)]
        OLLAMA[Ollama Service]
        DOCKER[Docker Engine]
        
        subgraph "Agent Container"
            PS[PowerShell 7.4]
            PY[Python 3.12 + uv]
            APP[Agent Scripts]
        end
        
        DOCKER --> AgentContainer
        AgentContainer -->|API| OLLAMA
    end
```

### 🐍 2.2 Python Management: `uv`
Abbandoniamo `pip` raw per **`uv`** (di Astral).
- **Veloce**: Scritto in Rust, 10-100x più veloce di pip.
- **Deterministico**: Usa `uv.lock` per versioni esatte.
- **Versatile**: Gestisce anche l'installazione di Python stesso.

### 🐚 2.3 PowerShell Management
I moduli PowerShell devono essere definiti in un file `requirements.psd1` ed installati build-time.

## 3. Dependency Management Standard (Mandatory)

Per garantire la longevità del codice e proteggerci da breaking changes (es. funzioni deprecate), applichiamo queste regole a TUTTI i linguaggi:

### 🛡️ Regola 1: Isolation (Mai Globali)
*   **Python**: MAI usare `pip install` globale. Sempre dentro un **Virtual Environment** (`.venv`) gestito da `uv`.
*   **PowerShell**: I moduli dipendenti devono essere scaricati in una cartella locale al progetto (es. `Run/Modules`) o pre-installati nell'immagine Docker.
*   **Node.js**: Sempre `node_modules` locali.

### 🔒 Regola 2: Pinning & Locking (Congelare il Tempo)
*   Ogni progetto DEVE avere un **Lockfile** (`uv.lock`, `package-lock.json`).
*   Questo file registra la versione ESATTA (es. `1.2.3-sha256`) di ogni libreria.
*   **Risultato**: Il deploy di oggi sarà identico a quello tra 2 anni, indipendentemente dagli aggiornamenti esterni.

### 📜 Regola 3: Explicit Deklaration
*   Nessuna dipendenza "nascosta". Se usi una libreria, deve essere dichiarata nel manifesto (`pyproject.toml`, `package.json`, `RequiredModules.psd1`).

---

## 4. Implementazione Pratica

### Dockerfile "Golden Image"

Questo Dockerfile diventa la **singola fonte di verità** per l'ambiente script.

```dockerfile
# Usa immagine ufficiale MSFT che ha già PowerShell Core
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# 1. Installa uv (Python manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# 2. Installa Python 3.12 via uv
RUN uv python install 3.12

# 3. Copia dipendenze
WORKDIR /app
COPY pyproject.toml .
# Installa dependencies in un venv isolato
RUN uv venv && uv pip install -r pyproject.toml

# 4. Copia scripts
COPY scripts/ /app/scripts/

# 5. Entrypoint
CMD ["pwsh", "/app/scripts/ai-agent/agent-retrieval.ps1"]
```

## 4. Workflow

### Sviluppo (Locale)
```bash
# Usa Dev Container o uv locale
uv run scripts/chromadb_manager.py
```

### Deploy (Prod)
1. **Build**: `docker build -t easyway-agent .`
2. **Run**: 
   ```bash
   docker run --network host \
     -v easyway-data:/data \
     easyway-agent \
     -Query "What is EasyWay?"
   ```

## 5. Vantaggi
1. **Immutabile**: Se builda, funziona. Ovunque (ARM, x86, Windows, Linux).
2. **Pulito**: Nessun `pip install --break-system-packages` sporco sul server.
3. **Aggiornato**: Aggiornare Python o PWSH significa solo cambiare una riga nel Dockerfile.

## 6. Next Steps
- [ ] Creare `Dockerfile` ufficiale.
- [ ] Migrare scripts attuali dentro il container.
- [ ] Setup CI/CD per buildare l'immagine.
