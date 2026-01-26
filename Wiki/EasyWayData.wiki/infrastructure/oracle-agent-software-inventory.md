---
id: oracle-agent-software-inventory
title: Oracle Cloud Agent - Software Bill of Materials (SBOM)
summary: Inventario completo di tutti i software installati sul server Oracle Cloud dedicato all'AI Agent EasyWay.
status: active
owner: team-platform
tags: [infrastructure, oracle-cloud, inventory, compliance, audit]
updated: 2026-01-26
---

# Oracle Cloud Agent - Software Bill of Materials (SBOM)

> **Scopo**: Tracciare ogni software installato sul server per audit, compliance, troubleshooting e disaster recovery.

## 📋 Server Info

- **Provider**: Oracle Cloud Infrastructure (OCI)
- **Tier**: Always Free (ARM Ampere)
- **IP**: `80.225.86.168`
- **OS**: Ubuntu 24.04 LTS (ARM64)
- **Hostname**: `oracle-agent`
- **Setup Date**: 2026-01-26

---

## 🧠 AI/ML Stack (Core Mission)

### 1. Ollama
**Scopo**: LLM Runtime Engine (esegue DeepSeek-R1)

| Proprietà | Valore |
|-----------|--------|
| **Versione** | Latest (auto-update) |
| **Path Binario** | `/usr/local/bin/ollama` |
| **Servizio** | `systemd` (`ollama.service`) |
| **Porta** | `11434` (localhost) |
| **Modelli Path** | `~/.ollama/models/` |
| **RAM Peak** | ~9.2GB |
| **Licenza** | MIT |
| **Compliance** | ✅ Open Source, No telemetry |

**Note**:
- Configurato per listen solo su localhost (no esposizione esterna)
- Auto-start al boot abilitato

---

### 2. DeepSeek-R1 7B
**Scopo**: Large Language Model per reasoning

| Proprietà | Valore |
|-----------|--------|
| **Model ID** | `deepseek-r1:7b` |
| **Size** | 4.7 GB |
| **Quantization** | 4-bit (Q4_K_M) |
| **Context Length** | 8192 tokens |
| **Licenza** | MIT (DeepSeek AI) |
| **Compliance** | ✅ Può essere usato in produzione |

**Rischi Identificati**:
- ⚠️ Può generare contenuti non deterministici (mitigato con prompt engineering)

---

### 3. ChromaDB (Vector Database)
**Scopo**: Semantic search e embedding storage

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 1.4.1 |
| **Installation Method** | `pip3 install --break-system-packages` |
| **Data Path** | `~/easyway-kb/` |
| **Embedding Model** | `all-MiniLM-L6-v2` (Sentence Transformers) |
| **Licenza** | Apache 2.0 |
| **Compliance** | ✅ Enterprise-ready |

**Note**:
- Modalità persistente (file-based)
- No esposizione HTTP (usata solo via Python API locale)

---

### 4. Sentence Transformers
**Scopo**: Generazione embedding per ChromaDB

| Proprietà | Valore |
|-----------|--------|
| **Versione** | Latest (pip) |
| **Model Used** | `all-MiniLM-L6-v2` |
| **Licenza** | Apache 2.0 |
| **Compliance** | ✅ GDPR-compliant (no data sent externally) |

---

## 🐍 Python Stack

### Python 3.12
**Scopo**: Runtime per ChromaDB e script ML

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 3.12.x (Ubuntu system) |
| **Path** | `/usr/bin/python3` |
| **Packages** | Installati con `--break-system-packages` (vedi sotto) |
| **Compliance** | ⚠️ **Debito Tecnico**: Installazione globale sporca |

**Packages Installati**:
```
chromadb==1.4.1
sentence-transformers
numpy
pandas
```

**Rischio Dichiarato**:
- ⚠️ Violazione PEP 668 (externally-managed-environment)
- ✅ **Mitigazione**: Server dedicato, no multi-tenancy
- 🎯 **Piano Futuro**: Migrare a Docker (vedi `agent-environment-standard.md`)

---

## 🐚 PowerShell Core

### PowerShell 7.4.1
**Scopo**: Scripting e orchestrazione cross-platform

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 7.4.1 LTS |
| **Installation Method** | Binary ARM64 (`.tar.gz`) |
| **Path Binario** | `/opt/microsoft/powershell/7/pwsh` |
| **Symlink** | `/usr/bin/pwsh` |
| **Licenza** | MIT |
| **Compliance** | ✅ Enterprise-grade |

**Note**:
- Installato via binary invece di apt (ARM64 compatibility fix)

---

## 📊 Monitoring & Observability

### 1. btop
**Scopo**: Resource monitoring dashboard (CPU, RAM, Network, Disk)

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 1.3.0 |
| **Installation Method** | `apt install btop` |
| **Path** | `/usr/bin/btop` |
| **Licenza** | Apache 2.0 |
| **Compliance** | ✅ Read-only tool, no security risk |

**Uso**: `btop` o alias `status`

---

### 2. glances
**Scopo**: Advanced system monitoring con export JSON

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 3.4.0 |
| **Installation Method** | `apt install glances` |
| **Path** | `/usr/bin/glances` |
| **Web Port** | 61208 (disabilitato di default) |
| **Licenza** | LGPL v3 |
| **Compliance** | ✅ No data exfiltration risk |

**Uso**: `glances` o alias `monitor`

---

### 3. neofetch
**Scopo**: System info banner

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 7.1.0 |
| **Installation Method** | `apt install neofetch` |
| **Path** | `/usr/bin/neofetch` |
| **Licenza** | MIT |
| **Compliance** | ✅ Static info only |

**Uso**: `neofetch` o alias `info`

---

## 🛠️ Custom Scripts (EasyWay Agent)

### 1. rag_agent.ps1
**Scopo**: Orchestrator principale RAG pipeline

| Proprietà | Valore |
|-----------|--------|
| **Path** | `~/rag_agent.ps1` |
| **Autore** | EasyWay Team |
| **Versione** | 1.0 (2026-01-26) |
| **Licenza** | Proprietaria EasyWay |
| **Dipendenze** | PowerShell, Ollama API, chromadb_manager.py, SQLite3 |

**Workflow**:
1. Retrieval semantico (ChromaDB)
2. Prompt generation
3. LLM query (Ollama/DeepSeek)
4. Response logging (SQLite)

---

### 2. chromadb_manager.py
**Scopo**: Python wrapper per operazioni ChromaDB

| Proprietà | Valore |
|-----------|--------|
| **Path** | `~/chromadb_manager.py` |
| **Autore** | EasyWay Team |
| **Versione** | 1.0 (2026-01-26) |
| **Licenza** | Proprietaria EasyWay |

**Comandi**:
```bash
python3 chromadb_manager.py index <file>
python3 chromadb_manager.py search "<query>"
```

---

### 3. check-agent-health.sh
**Scopo**: Quick health check script

| Proprietà | Valore |
|-----------|--------|
| **Path** | `~/check-agent-health.sh` |
| **Autore** | EasyWay Team |
| **Versione** | 1.0 (2026-01-26) |
| **Licenza** | Proprietaria EasyWay |

**Uso**: `~/check-agent-health.sh` o alias `agent-status`

---

### 4. setup_stack.sh
**Scopo**: Idempotent setup script (PowerShell + Python)

| Proprietà | Valore |
|-----------|--------|
| **Path** | `~/setup_stack.sh` |
| **Autore** | EasyWay Team |
| **Versione** | 1.0 (2026-01-26) |
| **Licenza** | Proprietaria EasyWay |

**Note**: Usato per deployment iniziale, non necessario a runtime.

---

## 🗄️ Databases & Persistence

### SQLite3
**Scopo**: Logging agent executions

| Proprietà | Valore |
|-----------|--------|
| **Versione** | 3.45.1 |
| **Installation Method** | `apt install sqlite3` |
| **DB Path** | `~/easyway.db` |
| **Schema** | `agent_executions` table |
| **Licenza** | Public Domain |
| **Compliance** | ✅ Local-only, no network exposure |

---

## 🔐 Security & Compliance Summary

| Area | Status | Note |
|------|--------|------|
| **Firewall** | ✅ CONFIGURED | Solo SSH (22) aperto. Ollama su localhost only. |
| **Data Exfiltration** | ✅ NO RISK | Tutto locale, no telemetry abilitata. |
| **PII Handling** | ✅ SAFE | ChromaDB non contiene PII, solo test data. |
| **System Updates** | ⚠️ MANUAL | Nessun auto-update configurato (rischio drift). |
| **Backup** | ❌ TODO | Nessun backup automatico configurato. |
| **Python Env** | ⚠️ DIRTY | Installazione globale (debito tecnico dichiarato). |

---

## 📦 Software Non Installato (Decisioni Consapevoli)

| Software | Motivazione per NON installarlo |
|----------|----------------------------------|
| **n8n** | Rinviato. Serve audit di sicurezza prima. |
| **Docker** | Pianificato per Hetzner, non necessario su sandbox Oracle. |
| **Nginx/Apache** | Nessun servizio web pubblico necessario. |
| **Monitoring Agent** (Prometheus, etc.) | Overkill per un server di test. |

---

## 🔄 Update Policy

**Strategia**: **Manual Update Only**

- ✅ **Pro**: Controllo totale, no sorprese
- ⚠️ **Contro**: Rischio security patch mancanti

**Processo di Update** (quando necessario):
1. Leggere changelog upstream
2. Testare in locale (se possibile)
3. Backup stato attuale
4. Update via `apt upgrade` o re-run setup script
5. Validare con `agent-status`

---

## 📖 Risorse & Documentazione

- [Setup Guide](./agent-local-llm-oracle.md)
- [Monitoring Tools Guide](./server-monitoring-tools.md)
- [Environment Standard](../standards/agent-environment-standard.md)
- [Deployment Runbook](../../brain/deployment-runbook-oracle-to-hetzner.md)

---

**Ultima verifica**: 2026-01-26  
**Prossima verifica consigliata**: 2026-02-26 (1 mese)
