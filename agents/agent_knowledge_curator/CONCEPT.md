# Agent Knowledge Curator - Concept

**Agent Name**: `agent_knowledge_curator`  
**Role**: Maintains ChromaDB indexing registry and auto-sync pipeline  
**Classification**: Meta-agent (gestisce knowledge degli altri agent)

---

## 🎯 Responsabilità

L'agent tiene un **registry** di cosa è indicizzato in ChromaDB e:
1. ✅ Traccia quali file sono stati indicizzati (e quando)
2. ✅ Suggerisce nuovi file da indicizzare (se rispettano criteri)
3. ✅ Identifica file obsoleti/deprecati da rimuovere
4. ✅ Verifica metadata quality (tags, owner, llm_include)
5. ✅ Triggera sync automatico su commit

---

## 📋 Registry Structure

**File**: `agents/agent_knowledge_curator/chromadb_registry.jsonl`

Ogni entry = 1 file indicizzato:

```jsonl
{"file":"Wiki/security/SECURITY_FRAMEWORK.md","status":"indexed","chunks":25,"last_sync":"2026-01-25T18:00:00Z","hash":"a3b2c1","quality_score":0.95,"tags":["domain/security","audience/dev"],"owner":"team-platform"}
{"file":"docs/infra/SERVER_STANDARDS.md","status":"indexed","chunks":15,"last_sync":"2026-01-25T12:00:00Z","hash":"d4e5f6","quality_score":0.88,"tags":["domain/infra"],"owner":"team-platform"}
{"file":"old/deprecated.md","status":"excluded","reason":"deprecated","last_check":"2026-01-25T10:00:00Z"}
{"file":"scripts/test-chromadb.py","status":"pending","reason":"new_file","detected":"2026-01-25T19:30:00Z","should_index":false}
```

**Fields**:
- `file`: Relative path from repo root
- `status`: `indexed | pending | excluded | obsolete`
- `chunks`: Number of chunks generated (if indexed)
- `last_sync`: Timestamp of last ChromaDB sync
- `hash`: File content hash (detect changes)
- `quality_score`: Metadata quality (0-1, based on tags/owner/llm_include)
- `tags`: Extracted from frontmatter
- `owner`: Extracted from frontmatter
- `should_index`: Decision (true/false)
- `reason`: Why excluded/pending

---

## 🤖 Agent Actions

### 1. `knowledge:scan`
**Description**: Scans repo for new/changed files, updates registry

**Workflow**:
```bash
# Agent scans all *.md, *.jsonl, manifest.json
for file in repo:
    if should_index(file):
        current_hash = hash(file)
        
        if file not in registry:
            → Add as "pending"
        elif registry[file].hash != current_hash:
            → Mark as "outdated", re-index needed
        else:
            → Skip (up to date)
```

**Output**: Updated registry + list of files to sync

---

### 2. `knowledge:suggest`
**Description**: Suggests new files to index based on criteria

**Criteria**:
```python
def should_index(file_path):
    # Include
    if file_path.endswith('.md'): 
        # Check frontmatter
        if has_frontmatter(file_path):
            fm = parse_frontmatter(file_path)
            if fm.get('llm', {}).get('include') == True:
                return True, "llm_include=true"
        
        # Default: Wiki and docs YES
        if '/Wiki/' in file_path or '/docs/' in file_path:
            return True, "wiki/docs default"
    
    if file_path.endswith('.jsonl') and '/kb/' in file_path:
        return True, "knowledge recipes"
    
    if file_path.name == 'manifest.json' and '/agents/' in file_path:
        return True, "agent manifest"
    
    # Exclude
    if '/node_modules/' in file_path: return False, "dependencies"
    if '/old/' in file_path: return False, "deprecated"
    if '/.git/' in file_path: return False, "version control"
    if file_path.endswith(('.log', '.tmp')): return False, "temporary"
    
    return False, "no match"
```

**Output**: 
```json
{
  "to_index": [
    {"file": "docs/new_doc.md", "reason": "wiki/docs default", "priority": "high"},
    {"file": "agents/agent_new/manifest.json", "reason": "agent manifest", "priority": "medium"}
  ],
  "to_exclude": [
    {"file": "old/legacy.md", "reason": "deprecated"}
  ]
}
```

---

### 3. `knowledge:sync`
**Description**: Syncs pending/outdated files to ChromaDB

**Workflow**:
```python
async def sync_to_chromadb(files):
    for file in files:
        # 1. Load file
        content = read_file(file.path)
        
        # 2. Chunk (if markdown)
        if file.path.endswith('.md'):
            chunks = chunk_markdown(content, max_tokens=400)
        elif file.path.endswith('.jsonl'):
            chunks = chunk_jsonl(content)  # 1 recipe = 1 chunk
        
        # 3. Generate embeddings
        for chunk in chunks:
            embedding = await openai.embeddings.create(
                model='text-embedding-ada-002',
                input=chunk.content
            )
            
            # 4. Upload to ChromaDB
            chroma.add(
                ids=[chunk.id],
                documents=[chunk.content],
                embeddings=[embedding.data[0].embedding],
                metadatas=[chunk.metadata]
            )
        
        # 5. Update registry
        registry.update({
            "file": file.path,
            "status": "indexed",
            "chunks": len(chunks),
            "last_sync": now(),
            "hash": hash(content)
        })
```

**Output**: 
```json
{
  "synced": 15,
  "chunks_added": 237,
  "errors": 0,
  "duration_ms": 4523
}
```

---

### 4. `knowledge:quality-check`
**Description**: Verifies metadata quality of indexed files

**Checks**:
```python
def quality_check(file):
    score = 0.0
    issues = []
    
    # Frontmatter exists? (+0.2)
    if has_frontmatter(file):
        score += 0.2
    else:
        issues.append("missing_frontmatter")
    
    # Has tags? (+0.3)
    fm = parse_frontmatter(file)
    if fm.get('tags') and len(fm['tags']) > 0:
        score += 0.3
    else:
        issues.append("missing_tags")
    
    # Has owner? (+0.2)
    if fm.get('owner'):
        score += 0.2
    else:
        issues.append("missing_owner")
    
    # Has llm.include? (+0.1)
    if fm.get('llm', {}).get('include') is not None:
        score += 0.1
    
    # Has summary? (+0.2)
    if fm.get('summary'):
        score += 0.2
    else:
        issues.append("missing_summary")
    
    return {"score": score, "issues": issues}
```

**Output**:
```json
{
  "files_checked": 405,
  "avg_quality": 0.85,
  "below_threshold": [
    {"file": "Wiki/old_page.md", "score": 0.4, "issues": ["missing_tags", "missing_owner"]}
  ]
}
```

---

### 5. `knowledge:prune`
**Description**: Removes obsolete chunks from ChromaDB

**Criteria for removal**:
- File deleted from repo
- File moved to `/old/`
- File marked as `status: deprecated` in frontmatter
- File not modified in >6 months AND usage_count == 0

**Workflow**:
```python
def prune_chromadb():
    # Get all indexed files from registry
    indexed_files = registry.where(status="indexed")
    
    for file in indexed_files:
        # Check if file still exists
        if not os.path.exists(file.path):
            # Delete from ChromaDB
            chroma.delete(where={"source": file.path})
            
            # Update registry
            registry.update(file.path, status="removed", reason="file_deleted")
        
        # Check if deprecated
        fm = parse_frontmatter(file.path)
        if fm.get('status') == 'deprecated':
            chroma.delete(where={"source": file.path})
            registry.update(file.path, status="excluded", reason="deprecated")
```

---

## 🔄 CI/CD Integration

### Trigger on Git Commit

**Azure DevOps Pipeline**:

```yaml
# azure-pipelines-knowledge-sync.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - 'Wiki/**/*.md'
      - 'docs/**/*.md'
      - 'agents/**/manifest.json'
      - 'agents/kb/*.jsonl'

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: NodeTool@0
  inputs:
    versionSpec: '20.x'

- script: |
    # Run agent_knowledge_curator
    node agents/agent_knowledge_curator/run.js scan
    node agents/agent_knowledge_curator/run.js sync
  displayName: 'Auto-sync Knowledge Base'
  env:
    CHROMA_HOST: $(CHROMA_HOST)
    OPENAI_API_KEY: $(OPENAI_API_KEY)
```

**Workflow**:
```
Git Push → Pipeline Trigger
  → Agent scans changed files
  → Agent updates registry
  → Agent syncs to ChromaDB
  → ChromaDB updated (agents have new knowledge!)
```

---

## 📊 Registry Analytics

**Agent può generare report**:

```json
{
  "total_files_tracked": 405,
  "indexed": 348,
  "pending": 12,
  "excluded": 45,
  "total_chunks": 3247,
  "avg_chunks_per_file": 9.3,
  "storage_mb": 8.5,
  "quality_distribution": {
    "high (>0.8)": 312,
    "medium (0.5-0.8)": 28,
    "low (<0.5)": 8
  },
  "last_sync": "2026-01-25T19:00:00Z",
  "sync_frequency": "every_commit"
}
```

**Usage Analytics** (from ChromaDB query logs):
```json
{
  "most_queried_files": [
    {"file": "Wiki/security/SECURITY_FRAMEWORK.md", "queries": 142},
    {"file": "docs/infra/SERVER_STANDARDS.md", "queries": 89},
    {"file": "agents/kb/recipes.jsonl", "queries": 67}
  ],
  "unused_files": [
    {"file": "Wiki/old_concept.md", "queries": 0, "indexed_days_ago": 120}
  ]
}
```

---

## 🎯 Manifest Example

**File**: `agents/agent_knowledge_curator/manifest.json`

```json
{
  "name": "Agent_Knowledge_Curator",
  "classification": "meta",
  "role": "ChromaDB Registry Manager",
  "description": "Maintains ChromaDB indexing registry, auto-syncs knowledge, quality checks metadata",
  "security": {
    "required_group": "easyway-dev",
    "rationale": "Curator reads all docs but doesn't modify DB/config",
    "can_sudo": false
  },
  "allowed_paths": [
    "Wiki/**",
    "docs/**",
    "agents/**",
    "db/**",
    "scripts/**"
  ],
  "actions": [
    {
      "name": "knowledge:scan",
      "description": "Scans repo for new/changed files, updates registry",
      "params": {
        "scope": {"type": "string", "enum": ["all", "wiki", "docs", "agents"], "default": "all"}
      }
    },
    {
      "name": "knowledge:suggest",
      "description": "Suggests new files to index based on criteria",
      "params": {}
    },
    {
      "name": "knowledge:sync",
      "description": "Syncs pending/outdated files to ChromaDB",
      "params": {
        "files": {"type": "array", "required": false}
      }
    },
    {
      "name": "knowledge:quality-check",
      "description": "Verifies metadata quality of indexed files",
      "params": {
        "min_score": {"type": "number", "default": 0.7}
      }
    },
    {
      "name": "knowledge:prune",
      "description": "Removes obsolete chunks from ChromaDB",
      "params": {
        "dry_run": {"type": "boolean", "default": true}
      }
    },
    {
      "name": "knowledge:report",
      "description": "Generates analytics report on knowledge base",
      "params": {}
    }
  ],
  "schedule": {
    "scan": "on_commit",
    "quality_check": "weekly",
    "prune": "monthly"
  },
  "knowledge_sources": [
    "agents/agent_knowledge_curator/chromadb_registry.jsonl",
    "docs/agentic/CHROMADB_INDEXING_STRATEGY.md"
  ]
}
```

---

## 💡 Benefits

### 1. **Zero Manual Work**
- Git commit → Auto-sync
- No need to remember "did I index this?"

### 2. **Quality Assurance**
- Auto-detect missing metadata
- Suggest improvements

### 3. **Knowledge Hygiene**
- Prune deprecated content
- Keep ChromaDB lean and relevant

### 4. **Auditability**
- Full history in registry
- Track what was indexed when

### 5. **Multi-Agent Coordination**
- Other agents can query registry:
  ```
  Agent DBA: "Was SECURITY_FRAMEWORK.md indexed?"
  Curator: "Yes, 25 chunks, last sync 2h ago, quality 0.95"
  ```

---

## 🚀 Quick Start Implementation

**Step 1**: Create agent structure
```bash
mkdir -p agents/agent_knowledge_curator
touch agents/agent_knowledge_curator/manifest.json
touch agents/agent_knowledge_curator/chromadb_registry.jsonl
touch agents/agent_knowledge_curator/run.js
```

**Step 2**: Initial scan
```bash
node agents/agent_knowledge_curator/run.js scan --init
# Scans all files, creates initial registry
```

**Step 3**: Manual sync (test)
```bash
node agents/agent_knowledge_curator/run.js sync --dry-run
# Shows what would be synced
```

**Step 4**: Enable CI/CD
```bash
# Add pipeline yaml
# Push to Git
# Auto-sync active!
```

---

## 🎯 Roadmap

### Phase 1 (MVP)
- [x] Concept design (this doc)
- [ ] Basic registry structure (JSONL)
- [ ] `knowledge:scan` implementation
- [ ] `knowledge:sync` basic (markdown only)

### Phase 2
- [ ] `knowledge:quality-check`
- [ ] `knowledge:suggest` with AI (suggest missing tags)
- [ ] CI/CD integration

### Phase 3
- [ ] `knowledge:prune` with usage analytics
- [ ] `knowledge:report` dashboard
- [ ] Multi-agent coordination (registry API)

---

**Owner**: team-platform  
**Status**: Concept (ready for implementation)  
**Priority**: HIGH (strategic enabler for all agents)
