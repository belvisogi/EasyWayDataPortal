---
id: ew-archive-imported-docs-2026-01-30-agentic-chromadb-indexing-strategy
title: ChromaDB Indexing Strategy - Decision Matrix
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
# ChromaDB Indexing Strategy - Decision Matrix

**Date**: 2026-01-25  
**Objective**: Definire cosa indicizzare in ChromaDB e perché

---

## 🎯 Principi Guida

### ✅ EMBED (Indicizza):
1. **Documentazione che cambia** (Wiki, README)
2. **Knowledge operativo** (come fare X, best practices)
3. **Code come reference** (SP signatures, API endpoints)
4. **Recipes/Patterns** (intent → azione)

### ❌ NON Embed:
1. **Codice completo** (troppo, va in code search separato)
2. **Dati utente/runtime** (GDPR, volatilità)
3. **Build artifacts** (node_modules, out/, dist/)
4. **Config con secrets** (.env, credentials)

---

## 📊 Decision Matrix - EasyWayDataPortal Folders

| Folder | Embed? | Priority | Rationale | Chunks Stimate |
|--------|--------|----------|-----------|----------------|
| **Wiki/** | ✅ YES | 🔴 HIGH | Knowledge base principale, agent lo consulta sempre | ~2500 |
| **docs/** | ✅ YES | 🔴 HIGH | Architecture, security framework, standards | ~500 |
| **scripts/** | ⚠️ PARTIAL | 🟡 MEDIUM | Solo README.md e headers/docstrings, non code completo | ~200 |
| **agents/** | ⚠️ PARTIAL | 🟡 MEDIUM | manifest.json + README.md, non logs | ~150 |
| **db/migrations/** | ⚠️ PARTIAL | 🟡 MEDIUM | Solo DDL/SP signatures, non full code | ~300 |
| **portal-api/** | ⚠️ PARTIAL | 🟢 LOW | Solo API specs, non implementation | ~100 |
| **tests/** | ❌ NO | - | Non serve agli agent per decision-making | 0 |
| **.git/** | ❌ NO | - | Metadata di versioning, non knowledge | 0 |
| **node_modules/** | ❌ NO | - | Dependencies esterne | 0 |
| **old/** | ❌ NO | - | Archivio, già deprecato | 0 |

**Total Chunks Estimate**: ~3750 chunks (@ 400 tokens/chunk)

---

## 🗂️ Dettaglio per Folder

### 1. Wiki/ - ✅ EMBED (Priority: HIGH)

**Cosa indicizzare**:
```
Wiki/EasyWayData.wiki/**/*.md
```

**Strategia**:
- Chunking per sezione (H2/H3 headers)
- Frontmatter metadata → vector metadata
- Include: runbooks, control-plane, security, orchestrations, domains

**Esclusioni**:
```
Wiki/.obsidian/          # Config Obsidian (no)
Wiki/logs/               # Runtime logs (no)
Wiki/.attachments/       # Immagini (no, troppo grandi)
```

**Metadata estratti**:
```json
{
  "tags": ["domain/security", "audience/dev"],
  "owner": "team-platform",
  "status": "active",
  "llm_include": true
}
```

**Chunks stimate**: ~2500 (Wiki ha ~100 pagine × 25 chunks avg)

---

### 2. docs/ - ✅ EMBED (Priority: HIGH)

**Cosa indicizzare**:
```
docs/infra/*.md          # Server standards, security framework
docs/agentic/*.md        # Agentic readiness, templates
docs/*.md                # Root docs (TEAM_WISDOM, VALUTAZIONE)
```

**Strategia**:
- Documenti lunghi → chunk per sezione
- Technical docs → alta priorità per agent_dba

**Esclusioni**:
```
docs/old/                # Se esiste
docs/.DS_Store           # OS files
```

**Chunks stimate**: ~500 (30 docs × 15-20 chunks avg)

---

### 3. scripts/ - ⚠️ EMBED PARTIAL (Priority: MEDIUM)

**Cosa indicizzare**:
```
scripts/*/README.md      # Documentation
scripts/**/*.ps1         # Solo docstrings/headers, non full code
scripts/**/*.sh          # Headers + usage examples
```

**Strategia**:
- Extract docstrings con regex
- Solo "what it does" + "how to use", no implementation details

**Esempio chunk**:
```json
{
  "content": "check-agent-permission.sh: Verifies user group membership before agent execution. Usage: ./check-agent-permission.sh <agent> <group>",
  "metadata": {
    "source": "scripts/agents/check-agent-permission.sh",
    "type": "script",
    "category": "rbac-enforcement"
  }
}
```

**Esclusioni**:
```
scripts/node_modules/    # Dependencies
scripts/**/*.log         # Logs
```

**Chunks stimate**: ~200 (50 scripts × 4 chunks header/docs)

---

### 4. agents/ - ⚠️ EMBED PARTIAL (Priority: MEDIUM)

**Cosa indicizzare**:
```
agents/*/manifest.json   # Agent capabilities, actions, security
agents/*/README.md       # Agent documentation
agents/kb/*.jsonl        # Recipes! (intent → action mapping)
```

**Strategia**:
- `manifest.json` → 1 chunk con full JSON (searchable)
- `recipes.jsonl` → ogni recipe = 1 chunk
- KB files → embeddings per semantic search

**Esempio chunk da manifest**:
```json
{
  "content": "Agent DBA: Manages database migrations, drift checks, RLS rollout. Actions: db-user:create, db-table:create, db-doc:ddl-inventory. Required group: easyway-admin",
  "metadata": {
    "source": "agents/agent_dba/manifest.json",
    "agent": "agent_dba",
    "classification": "brain",
    "security_group": "easyway-admin"
  }
}
```

**Esclusioni**:
```
agents/logs/             # Runtime logs
agents/data/             # Temporary data
agents/**/*.pyc          # Compiled files
```

**Chunks stimate**: ~150 (10 agents × 5 chunks + 100 recipes)

---

### 5. db/migrations/ - ⚠️ EMBED PARTIAL (Priority: MEDIUM)

**Cosa indicizzare**:
```
db/migrations/**/*.sql   # Solo DDL signatures, SP headers
db/README.md             # Migration strategy
```

**Strategia**:
- Extract solo:
  - `CREATE TABLE` statements (schema)
  - `CREATE PROCEDURE` signatures (parameters)
  - Comments/descriptions
- NO: Full SP implementation code

**Esempio chunk**:
```json
{
  "content": "PORTAL.sp_insert_user: Creates new user. Params: @tenant_id, @email, @name, @surname, @profile_code. Returns: @user_ndg",
  "metadata": {
    "source": "db/migrations/V011__stored_procedures_users.sql",
    "type": "stored_procedure",
    "schema": "PORTAL",
    "table": "USERS"
  }
}
```

**Chunks stimate**: ~300 (50 migrations × 6 chunks avg)

---

### 6. portal-api/ - ⚠️ EMBED PARTIAL (Priority: LOW)

**Cosa indicizzare**:
```
portal-api/README.md
portal-api/src/routes/*.ts  # Solo JSDoc/OpenAPI specs
portal-api/package.json     # Dependencies info
```

**Strategia**:
- Extract API endpoint signatures
- NO: Implementation details

**Esempio chunk**:
```json
{
  "content": "POST /api/users: Creates new user. Body: {tenant_id, email, name, surname}. Auth: Required. Calls: PORTAL.sp_insert_user",
  "metadata": {
    "source": "portal-api/src/routes/users.ts",
    "method": "POST",
    "endpoint": "/api/users",
    "auth_required": true
  }
}
```

**Chunks stimate**: ~100 (20 endpoints × 5 chunks avg)

---

## 🚫 Cosa NON Indicizzare (e Perché)

### ❌ tests/
**Perché**: Test code non è knowledge operativo per agent. Agent non deve "sapere come testare", deve sapere "cosa fare".

### ❌ node_modules/, .git/, build artifacts
**Perché**: Dependencies esterne, non knowledge nostro. Troppo rumore.

### ❌ .env, secrets, config files con credentials
**Perché**: Security risk. Vector DB potrebbe leakare secrets in search results.

### ❌ old/, archive/
**Perché**: Deprecated. Agent deve usare knowledge attuale, non storia.

### ❌ logs/ (runtime)
**Perché**: Troppo volatile, non knowledge duraturo. Analytics è altro dominio.

### ❌ Immagini/video (.png, .jpg, .mp4)
**Perché**: Embedding di immagini è dominio separato (vision models). Per ora skip.

---

## 📐 Struttura Chunk Metadata

**Standard metadata per ogni chunk**:
```json
{
  "id": "wiki_security_rbac_001",
  "content": "...",
  "content_vector": [0.123, -0.456, ...],
  "metadata": {
    "source": "Wiki/security/SECURITY_FRAMEWORK.md",
    "source_type": "wiki|docs|script|agent|db",
    "section": "RBAC Groups",
    "tags": ["domain/security", "audience/dev"],
    "owner": "team-platform",
    "llm_include": true,
    "last_updated": "2026-01-25T12:00:00Z",
    "chunk_index": 1,
    "total_chunks": 25
  }
}
```

---

## 🎯 Filtri per Agent

**Ogni agent cerca nel suo scope**:

```python
# Agent DBA search
results = chroma.query(
    query_texts=["how to create user"],
    where={
        "$or": [
            {"tags": {"$contains": "domain/db"}},
            {"tags": {"$contains": "agent/dba"}},
            {"source_type": {"$in": ["db", "wiki"]}}
        ]
    },
    n_results=5
)
```

**Agent Security search**:
```python
results = chroma.query(
    query_texts=["RBAC groups"],
    where={
        "tags": {"$contains": "domain/security"}
    }
)
```

---

## 🚀 Implementation Roadmap

### Phase 1: Core Knowledge (MVP)
**Target**: 2500 chunks

1. ✅ `Wiki/` → Full indexing
2. ✅ `docs/infra/` → Full indexing
3. ✅ `agents/kb/*.jsonl` → Recipes

**Estimate**: 3 giorni (chunking + embedding + upload)

### Phase 2: Extended Knowledge
**Target**: +1000 chunks

4. ⚠️ `scripts/*/README.md` → Documentation
5. ⚠️ `db/migrations/` → SP signatures  
6. ⚠️ `agents/manifest.json` → Agent capabilities

**Estimate**: 2 giorni

### Phase 3: API Specs
**Target**: +200 chunks

7. ⚠️ `portal-api/` → Endpoint specs

**Estimate**: 1 giorno

---

## 💾 Storage Estimate

**Total chunks**: ~3750  
**Avg chunk size**: 400 tokens = ~1.6 KB (text + metadata)  
**Total size**: 3750 × 1.6 KB = **~6 MB**

**ChromaDB storage**: ~10 MB (with indexes)

**Embedding cost (one-time)**:
- 3750 chunks × 400 tokens = 1.5M tokens
- OpenAI text-embedding-ada-002: $0.0001/1K tokens
- Cost: **~$0.15** (one-time)

**Incremental (weekly)**:
- ~50 new chunks/week (docs updates)
- Cost: **~$0.002/week** = €0.10/month

---

## 🎬 Esempio Pipeline Script

```python
# Pseudo-code chunking strategy
def should_index(file_path):
    # Include
    if file_path.endswith('.md'): return True
    if file_path.endswith('.jsonl') and 'kb/' in file_path: return True
    if file_path.name == 'manifest.json': return True
    
    # Exclude
    if '/node_modules/' in file_path: return False
    if '/old/' in file_path: return False
    if '/.git/' in file_path: return False
    if file_path.endswith('.log'): return False
    if file_path.endswith(('.png', '.jpg', '.mp4')): return False
    
    return False

def extract_chunks(file_path):
    if file_path.endswith('.md'):
        return chunk_markdown(file_path, max_tokens=400)
    elif file_path.endswith('.jsonl'):
        return chunk_jsonl(file_path)  # 1 recipe = 1 chunk
    elif file_path.endswith('manifest.json'):
        return chunk_manifest(file_path)
    elif file_path.endswith('.sql'):
        return extract_sp_signatures(file_path)
    else:
        return []
```

---

## 🏆 Success Criteria

**Dopo indexing completo**:

- ✅ Agent trova risposta in <2 secondi
- ✅ Precision > 80% (risultati rilevanti)
- ✅ Coverage > 90% (domande con risposta in KB)
- ✅ No false positives su secrets/credentials

---

**Conclusion**: Indicizza **knowledge duraturo e operativo**, skip **code implementation e runtime data**.

**Next**: Vuoi che facciamo Phase 1 (Wiki + docs/infra) come quick win? 🚀


