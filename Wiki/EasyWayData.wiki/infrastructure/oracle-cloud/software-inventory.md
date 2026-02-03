---
id: oracle-agent-software-inventory
title: Oracle Cloud Agent - Software Bill of Materials (SBOM)
summary: Inventario completo di tutti i software installati sul server Oracle Cloud.
status: active
owner: team-platform
tags: [infrastructure, oracle-cloud, inventory, compliance, sbom]
updated: 2026-01-26
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# Oracle Cloud Agent - Software Bill of Materials (SBOM)

> **Scopo**: Tracciare ogni componente software per audit, compliance e disaster recovery.

## 📋 Server Info

| Proprietà | Valore |
|-----------|--------|
| **Provider** | Oracle Cloud (OCI Free Tier) |
| **IP Pubblico** | `80.225.86.168` |
| **OS** | Ubuntu 24.04 LTS ARM64 |
| **RAM** | 24GB |
| **Storage** | 96GB |
| **Setup Date** | 2026-01-26 |

---

## 🧠 AI/ML Stack

### Ollama (LLM Runtime)
- **Versione**: Latest
- **Path**: `/usr/local/bin/ollama`
- **Servizio**: systemd (`ollama.service`)
- **Licenza**: MIT
- **Compliance**: ✅ No telemetry

### DeepSeek-R1 7B (Model)
- **Size**: 4.7 GB
- **Quantization**: 4-bit
- **Licenza**: MIT
- **Compliance**: ✅ Production-ready

### ChromaDB
- **Versione**: 1.4.1
- **Installation**: pip (global)
- **Licenza**: Apache 2.0
- **Compliance**: ✅ Enterprise-grade

### Sentence Transformers
- **Model**: all-MiniLM-L6-v2
- **Licenza**: Apache 2.0
- **Compliance**: ✅ GDPR-compliant

---

## 🐍 Python Stack

### Python 3.12
- **Installation**: System (Ubuntu)
- **Packages**: chromadb, sentence-transformers, numpy, pandas
- **⚠️ Warning**: Installed with `--break-system-packages` (technical debt)

---

## 🐚 PowerShell Core

### PowerShell 7.4.1
- **Installation**: Binary ARM64
- **Path**: `/opt/microsoft/powershell/7/pwsh`
- **Licenza**: MIT
- **Compliance**: ✅ Enterprise-grade

---

## 📊 Monitoring Tools

### btop 1.3.0
- **Scopo**: Resource monitoring
- **Licenza**: Apache 2.0

### glances 3.4.0
- **Scopo**: Advanced monitoring + API
- **Licenza**: LGPL v3

### neofetch 7.1.0
- **Scopo**: System info banner
- **Licenza**: MIT

---

## 🗄️ Database

### SQLite 3.45.1
- **Scopo**: Agent execution logging
- **DB Path**: `~/easyway.db`
- **Licenza**: Public Domain
- **Compliance**: ✅ Local-only

---

## 🛠️ Custom Scripts (EasyWay)

| Script | Path | Scopo |
|--------|------|-------|
| **agent-retrieval.ps1** | `~/agent-retrieval.ps1` | RAG orchestrator (Standard) |
| **chromadb_manager.py** | `~/chromadb_manager.py` | Vector DB wrapper |
| **check-agent-health.sh** | `~/check-agent-health.sh` | Health check |
| **setup_stack.sh** | `~/setup_stack.sh` | Deployment script |

---

## 🔐 Security Notes

- ✅ All network services on localhost only
- ✅ No telemetry/external calls
- ⚠️ Python installed globally (PEP 668 violation)
- ⚠️ No backup configured
- ⚠️ No auto-updates enabled

**Vedi**: [Security Assessment](./security-assessment.md) per dettagli.

---

**Last Updated**: 2026-01-26

