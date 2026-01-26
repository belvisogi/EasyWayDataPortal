# 📄 02 - AI Services & Stack Architecture

Strategia: Modularità Funzionale (Agent-First)
AI Engine: Ollama (DeepSeek-R1 7B)
Knowledge Base: ChromaDB (Vector Store)

---

## 1. Panoramica degli AI Services

Il sistema è composto da 3 componenti principali orchestrati da PowerShell.

### 🧠 Stack AI: The Brain

Path: `/opt/easyway/`

Ruolo: Reasoning, Retrieval, Response Generation.

|**Servizio**|**Versione**|**Note Critiche**|
|---|---|---|
|**Ollama**|Latest (auto-update)|LLM Runtime. Listen su `localhost:11434` solo.|
|**DeepSeek-R1 7B**|4-bit Quantized|Modello di reasoning. 4.7GB su disco.|
|**ChromaDB**|1.4.1|Vector database. Storage: `/opt/easyway/var/data/knowledge-base/`|
|**Sentence Transformers**|5.2.1|Embedding model (`all-MiniLM-L6-v2`).|

---

## 2. Agent Orchestrator (PowerShell)

### 🤖 `easyway-agent` (Main Entry Point)

**Path:** `/opt/easyway/bin/easyway-agent`

**Scopo:** RAG Pipeline Orchestrator

**Workflow:**
```
User Query
    ↓
1. Semantic Search (ChromaDB)
    ↓
2. Context Retrieval (Top-K docs)
    ↓
3. Prompt Generation (System + Context + Query)
    ↓
4. LLM Inference (Ollama/DeepSeek)
    ↓
5. Response + Logging (SQLite)
```

**Invocazione:**
```bash
easyway-agent -Query "What is EasyWay philosophy?"
```

**Output (JSON):**
```json
{
  "query": "What is EasyWay philosophy?",
  "answer": "...",
  "retrieved_docs": "concept/architectural-vision.md",
  "timestamp": "2026-01-26 19:10:00"
}
```

---

## 3. Knowledge Base Manager

### 📚 `chromadb_manager.py`

**Path:** `/opt/easyway/lib/scripts/chromadb_manager.py`

**Scopo:** Index e Search su ChromaDB

**Comandi:**

```bash
# Index un file
python3 /opt/easyway/lib/scripts/chromadb_manager.py index /path/to/file.md

# Search semantico
python3 /opt/easyway/lib/scripts/chromadb_manager.py search "AI governance"
```

**Storage:** `/opt/easyway/var/data/knowledge-base/chroma.sqlite3`

---

## 4. Service Dependencies

**Dependency Chain:**

```
easyway-agent (PowerShell)
    ↓
chromadb_manager.py (Python venv)
    ↓
ChromaDB (File-based)
    +
Ollama (HTTP API localhost:11434)
    ↓
DeepSeek-R1 (Model in ~/.ollama/models/)
```

**Critical Path:** Se Ollama è down, l'agent fallisce.

---

## 5. Python Environment (Venv)

### 🐍 Virtual Environment (TESS Compliant)

**Path:** `/opt/easyway/lib/python/.venv`

**Activation:**
```bash
source /opt/easyway/lib/python/.venv/bin/activate
```

**Installed Packages:**
- chromadb==1.4.1
- sentence-transformers==5.2.1
- numpy==2.4.1
- pandas==3.0.0

**Lockfile:** `/opt/easyway/lib/python/requirements.lock`

**⚠️ IMPORTANTE**: NO pacchetti installati globalmente. Venv isolato.

---

## 6. Systemd Services

### Ollama Service

**Status:**
```bash
systemctl status ollama
```

**Auto-start:** Enabled

**Memory:** ~4.5GB (peak 9.2GB con inference)

---

## 7. Service Flow (Esempio Pratico)

### Scenario: User Query "Explain GEDI philosophy"

1. **User** invia query via CLI:
   ```bash
   easyway-agent -Query "Explain GEDI philosophy"
   ```

2. **PowerShell Agent** chiama `chromadb_manager.py`:
   ```python
   python3 chromadb_manager.py search "Explain GEDI philosophy"
   ```

3. **ChromaDB** restituisce top-4 documenti rilevanti:
   ```
   - concept/architectural-vision.md (score: 0.92)
   - agents-governance.md (score: 0.87)
   ```

4. **Agent** costruisce prompt:
   ```
   System: You are an expert on EasyWay...
   Context: [doc contents]
   User: Explain GEDI philosophy
   ```

5. **Ollama** (DeepSeek-R1) genera risposta:
   ```bash
   curl http://localhost:11434/v1/chat/completions -d '{...}'
   ```

6. **Agent** logga esecuzione in SQLite:
   ```sql
   INSERT INTO agent_executions (query, answer, timestamp) VALUES (...);
   ```

7. **Response** restituita a user (JSON o plain text)

---

## 8. Performance Notes

|**Metric**|**Valore Tipico**|
|---|---|
|**Query Latency**|3-8 secondi (first token)|
|**Throughput**|~15 tokens/sec (DeepSeek 7B)|
|**Memory Footprint**|~5GB RAM (idle)|
|**Disk I/O**|Basso (ChromaDB file-based)|

---

## 9. Troubleshooting

|**Sintomo**|**Diagnosi**|**Azione**|
|---|---|---|
|**Agent timeout**|Ollama down o slow|`systemctl restart ollama`|
|**"ChromaDB not found"**|Path errato o venv non attivo|Verificare shebang in script Python|
|**Out of memory**|DeepSeek troppo grande|Ridurre context length|
|**Slow inference**|ARM CPU limit|Normale su ARM, considerare quantization inferiore|
