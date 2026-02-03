---
id: rag-documentation-best-practices
title: RAG-Optimized Documentation Best Practices
summary: Linee guida per scrivere documentazione ottimizzata per Retrieval-Augmented Generation
tags: [domain/docs, layer/howto, audience/dev, audience/architect, privacy/internal, language/it, rag, best-practices, agents]
status: active
owner: team-ai
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 300-500
entities: [RAG, LLM, embeddings, chunking, retrieval]
---

# 🎯 RAG-Optimized Documentation Best Practices

**Obiettivo**: Scrivere documentazione che funziona perfettamente con sistemi RAG (Retrieval-Augmented Generation).

---

## 🧩 Chunking Strategy

### Chunk Size Ideale
- **Target**: 200-600 tokens (~150-450 parole)
- **Perché**: Balance tra contesto e precisione
  - Troppo piccolo → Perde contesto
  - Troppo grande → Rumore nel retrieval

### Come Controllare
```yaml
llm:
  chunk_hint: 300-400  # Tokens per chunk
```

**Regola pratica**: Ogni `##` section dovrebbe essere 1-3 chunk.

---

## 📝 Self-Contained Sections

### ❌ Cattivo Esempio
```markdown
## Installation
See above for prerequisites.
Run the command.
```

**Problema**: "above" e "the command" sono vaghi.

### ✅ Buon Esempio
```markdown
## Installation

**Prerequisites**: Ubuntu 22.04, Docker 24+

Run:
```bash
docker compose up -d
```

**Perché funziona**: Chunk standalone, retrieval preciso.

---

## 🏷️ Metadata Ricco

### Facet Tags
```yaml
tags: [domain/api, layer/howto, audience/dev, privacy/internal, language/it]
```

**Benefici**:
- Filtering: `WHERE tags CONTAINS 'domain/api'`
- Boost: Semantic + metadata hybrid search

### Entities
```yaml
entities: [PostgreSQL, Redis, n8n, MinIO]
```

**Benefici**:
- Named Entity Recognition (NER) pre-computed
- Entity-based retrieval: "Trova doc su PostgreSQL"

---

## 🔗 Link Espliciti

### ❌ Cattivo
```markdown
Come spiegato prima, usa il comando.
```

### ✅ Buono
```markdown
Come spiegato in [Server Setup](./server-setup.md#installation), usa:
```bash
sudo systemctl start service
```
```

**Perché**: RAG può seguire link e fare multi-hop retrieval.

---

## 📊 Structured Content

### Use Tables
```markdown
| Feature | Status | Owner |
|---------|--------|-------|
| Auth    | ✅     | @team-security |
| API     | 🚧     | @team-backend |
```

**Benefici**: Parsing strutturato, Q&A preciso.

### Use Lists
```markdown
**Prerequisites**:
1. Node.js 20+
2. PostgreSQL 15+
3. Redis 7+
```

**Benefici**: Extraction facile, checklist-based retrieval.

---

## 🎨 Code Blocks

### Always Specify Language
```markdown
```python
def hello():
    return "world"
```
```

**Benefici**: Syntax highlighting + code-specific embeddings.

### Add Context
```markdown
**File**: `src/utils/db.py`
```python
def connect():
    # ...
```
```

**Benefici**: RAG sa dove applicare il codice.

---

## 🚫 Anti-Patterns

### 1. Riferimenti Vaghi
❌ "Come visto sopra"  
✅ "Come spiegato in [Section](#section)"

### 2. Sinonimi Non Controllati
❌ `agentic`, `agent-based`, `ai-agents`  
✅ `agents` (canonical)

### 3. Chunk Troppo Grandi
❌ Sezione da 2000 token  
✅ Split in sub-sections

### 4. Metadata Mancante
❌ No `chunk_hint`, no `entities`  
✅ Frontmatter completo

---

## 🧪 Testing RAG Quality

### 1. Chunk Size Distribution
```bash
# Verifica che 90% chunk siano 200-600 tokens
python scripts/analyze_chunks.py
```

### 2. Retrieval Precision
```bash
# Top-3 precision su query di test
python scripts/test_rag_retrieval.py
```

### 3. Human Eval
- Query: "Come faccio X?"
- Expected: Doc corretto in top-3
- Metric: Success rate >80%

---

## 📚 Checklist per Autori

Prima di committare un doc:

- [ ] Frontmatter completo (facets + free tags)
- [ ] `chunk_hint` specificato (200-600)
- [ ] `entities` elencate
- [ ] Ogni `##` section è self-contained
- [ ] Link espliciti (no "sopra", "sotto")
- [ ] Code blocks con language
- [ ] Tables per dati strutturati
- [ ] No sinonimi (usa canonical tags)

---

## 🔗 Risorse

- [Documentation Quality Framework](./documentation-quality-framework.md)
- [Tagging Howto](../onboarding/howto-tagging.md)
- [Audit Guide](./docs-audit-guide.md)

---

**Maintained by**: EasyWay AI Team  
**Version**: 1.0 (2026-02-03)
