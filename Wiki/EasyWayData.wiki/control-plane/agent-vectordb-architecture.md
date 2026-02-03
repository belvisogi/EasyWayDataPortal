---
id: ew-agent-vectordb-architecture
title: Agent-First Architecture con Vector Database
summary: Architettura completa del portale EasyWay dove tutte le operazioni passano attraverso agent che interrogano un vector database (Azure AI Search) per knowledge retrieval, eliminando la necessità di query dirette dall'utente.
owner: team-platform, team-architecture
status: active
tags: [domain/control-plane, layer/reference, audience/architect, audience/dev, privacy/internal, language/it, agents, vector-db, rag, azure-ai-search]
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: []
entities: []
updated: '2026-01-13'
---

[[../start-here.md|Home]] > Architecture > Reference

# Agent-First Architecture con Vector Database

## Vision

**Portale EasyWay = 100% Agent-Driven**

L'utente **non scrive query**, **non naviga Wiki manualmente**. L'utente **chatta con agent** che:
1. Capiscono l'intent (semantic understanding)
2. Cercano knowledge nel vector DB (Wiki + Code + Recipes)
3. Eseguono operazioni via stored procedures
4. Ritornano risultati strutturati e leggibili

---

## Architettura Complessiva

```mermaid
graph TB
    subgraph "User Interface"
        UI[Portal UI - Chat Interface]
    end
    
    subgraph "Agent Layer"
        AC[Agent Chat API]
        AO[Agent Orchestrator]
        AG1[Agent DBA]
        AG2[Agent Security]
        AG3[Agent Docs]
    end
    
    subgraph "Knowledge Layer"
        VDB[(Vector DB<br/>Azure AI Search)]
        KB[Knowledge Base<br/>chunks + embeddings]
    end
    
    subgraph "Data Layer"
        SQLDB[(SQL Server)]
        SP[Stored Procedures]
    end
    
    subgraph "Source of Truth"
        GIT[Git Repo]
        WIKI[Wiki Markdown]
        CODE[Code + Flyway]
        REC[Recipes JSONL]
    end
    
    UI -->|Chat message| AC
    AC -->|Route intent| AO
    AO -->|Invoke| AG1
    AO -->|Invoke| AG2
    AO -->|Invoke| AG3
    
    AG1 -->|Semantic search| VDB
    AG2 -->|Semantic search| VDB
    AG3 -->|Semantic search| VDB
    
    VDB -->|Return context| AG1
    VDB -->|Return context| AG2
    
    AG1 -->|Execute| SP
    SP -->|CRUD| SQLDB
    
    GIT -->|CI/CD Pipeline| KB
    WIKI -->|Chunking| KB
    CODE -->|Indexing| KB
    REC -->|Embedding| KB
    KB -->|Sync| VDB
    
    AG1 -.->|Log execution| SQLDB
    SP -.->|AI-readable logs| SQLDB
```sql

---

## Principi Fondamentali

### 1. **Agent-First, No Direct Query**

**❌ OLD (Portale Tradizionale)**:
```sql
User → UI → SQL Query → Display Results
```sql

**✅ NEW (Agent-First)**:
```sql
User → Chat → Agent → Vector Search + SP Execution → Structured Answer
```sql

**Esempio**:
```sql
User: "Dammi lista utenti tenant TEN001"

❌ OLD: User scrive SELECT * FROM PORTAL.USERS WHERE tenant_id='TEN001'
✅ NEW: Agent capisce intent → Cerca in vector DB quale SP usare 
        → Esegue sp_get_users_by_tenant → Ritorna lista formattata
```sql

---

### 2. **Vector DB = Single Knowledge Source**

**Tutti i contenuti indicizzati**:
- ✅ Wiki markdown (chunked per sezione)
- ✅ Code snippets (Flyway migrations, SP, TypeScript)
- ✅ Recipes (intent → procedure mapping)
- ✅ Documentation (API specs, guides)

**NOT Indexed**:
- ❌ Data utente (GDPR, privacy)
- ❌ Credentials (security)
- ❌ Logs runtime (troppo volatile)

---

### 3. **Hybrid Search Strategy**

**Layer 1 - Exact Match** (Latency: ~10ms):
```typescript
// recipes.jsonl lookup
const recipe = recipes.find(r => 
  r.intent === extractedIntent(userMessage)
);
```sql

**Layer 2 - SQL/SP Index** (Latency: ~50ms):
```sql
-- Index di SP esistenti
SELECT name, description 
FROM sys.procedures 
WHERE name LIKE 'sp_' + @search_term
```sql

**Layer 3 - Vector Semantic** (Latency: ~200ms):
```typescript
// Azure AI Search hybrid query
const results = await azureSearch.search(userMessage, {
  semanticConfiguration: 'wiki-semantic',
  select: ['content', 'source', 'tags'],
  top: 5
});
```sql

**Decision Tree**:
```sql
User query → Try Layer 1 (exact)
            ↓ No match?
            → Try Layer 2 (SQL index)
            ↓ No match?
            → Layer 3 (vector semantic)
            ↓
            Return best match (confidence score)
```sql

---

## Vector Database Design

### Schema Chunks

**Ogni chunk nel vector DB**:
```json
{
  "id": "wiki_db_users_create_001",
  "content": "Per creare un utente: usa sp_insert_user con parametri...",
  "content_embedding": [0.123, -0.456, ...],  // 1536 dimensions
  "metadata": {
    "source": "Wiki/db/users.md",
    "source_type": "wiki",
    "section": "Create User",
    "tags": ["domain/db", "users", "crud"],
    "code_refs": [
      "db/flyway/sql/V_011__stored_procedures_users_read.sql#L45",
      "easyway-portal-api/src/routes/users.ts#L89"
    ],
    "stored_procedure": "PORTAL.sp_insert_user",
    "last_updated": "2026-01-13T10:30:00Z",
    "confidence_score": 0.92,
    "author": "team-platform"
  }
}
```sql

**Indici Azure AI Search**:

**Index 1: `wiki-chunks`**
- Content chunked da Wiki markdown
- Embeddings: text-embedding-ada-002
- ~2000 chunks (attuale), growing

**Index 2: `code-snippets`**
- Function/SP signatures + docstrings
- Embeddings: code-specific model
- ~500 snippets

**Index 3: `recipes`**
- Intent → Procedure mapping
- Embeddings + exact match
- ~200 recipes (da recipes.jsonl)

---

## Agent Workflow (Detailed)

### Fase 1: Intent Understanding

```typescript
// In AgentChatService
async processMessage(message: string, context: ConversationContext) {
  // 1. Extract intent
  const intent = await this.extractIntent(message);
  // Result: { type: 'db-user:list', params: { tenant_id: 'TEN001' } }
  
  // 2. Determine agent
  const agent = this.selectAgent(intent);
  // Result: 'agent_dba'
  
  // 3. Search knowledge
  const knowledge = await this.searchKnowledge(message, { agent, intent });
  
  return { intent, agent, knowledge };
}
```sql

---

### Fase 2: Knowledge Retrieval

```typescript
async searchKnowledge(query: string, context: any) {
  // Layer 1: Exact match recipes
  const recipe = await this.searchRecipes(context.intent);
  if (recipe && recipe.confidence > 0.9) {
    return {
      source: 'recipes',
      result: recipe,
      confidence: recipe.confidence
    };
  }
  
  // Layer 2: SP index
  if (context.agent === 'agent_dba') {
    const sp = await this.searchStoredProcedures(query);
    if (sp) {
      return {
        source: 'sp_index',
        result: sp,
        confidence: 0.85
      };
    }
  }
  
  // Layer 3: Vector semantic search
  const vectorResults = await azureSearch.search(query, {
    searchFields: ['content'],
    select: ['content', 'metadata'],
    filter: `metadata/tags/any(t: t eq '${context.agent}')`,
    top: 3,
    semanticConfiguration: 'default'
  });
  
  return {
    source: 'vector_db',
    results: vectorResults.results,
    confidence: vectorResults.results[0]?.score || 0.5
  };
}
```sql

---

### Fase 3: Execution

```typescript
async executeWithKnowledge(knowledge: KnowledgeResult, params: any) {
  if (knowledge.source === 'recipes') {
    // Execute stored procedure from recipe
    const sp = knowledge.result.stored_procedure;
    const result = await this.executeStoredProcedure(sp, params);
    
    return {
      status: result.status,
      data: result.data,
      metadata: {
        sp_executed: sp,
        duration_ms: result.duration_ms,
        rows_affected: result.rows_affected
      }
    };
  }
  
  if (knowledge.source === 'vector_db') {
    // Generate answer from context
    const answer = await this.generateAnswer(knowledge.results, params);
    
    return {
      status: 'OK',
      answer: answer.text,
      sources: knowledge.results.map(r => r.metadata.source),
      confidence: knowledge.confidence
    };
  }
}
```sql

---

## CI/CD Pipeline (Git → Vector DB)

### Workflow Completo

```mermaid
sequenceDiagram
    participant Dev
    participant Git
    participant Pipeline
    participant Chunker
    participant Embedder
    participant VectorDB
    participant Agent
    
    Dev->>Git: Commit Wiki changes
    Git->>Pipeline: Trigger on push (main)
    Pipeline->>Chunker: Extract changed files
    Chunker->>Chunker: Split markdown by sections
    Chunker->>Embedder: Send chunks
    Embedder->>Embedder: Generate embeddings (OpenAI)
    Embedder->>VectorDB: Upload chunks + embeddings
    VectorDB->>VectorDB: Index new content
    VectorDB-->>Agent: New knowledge available!
```sql

---

### Script Pipeline (Azure DevOps)

```yaml
# azure-pipelines-vectordb-sync.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - Wiki/**/*.md
      - docs/**/*.md
      - agents/kb/*.jsonl
      - db/flyway/sql/**/*.sql

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: NodeTool@0
  inputs:
    versionSpec: '20.x'

- script: |
    npm install
    npm run vectordb:sync
  displayName: 'Sync to Vector DB'
  env:
    AZURE_SEARCH_ENDPOINT: $(AZURE_SEARCH_ENDPOINT)
    AZURE_SEARCH_KEY: $(AZURE_SEARCH_KEY)
    OPENAI_API_KEY: $(OPENAI_API_KEY)
```sql

---

### Script Sync (TypeScript)

```typescript
// scripts/vectordb-sync.ts
import { AzureKeyCredential, SearchClient } from '@azure/search-documents';
import { OpenAI } from 'openai';
import { readFileSync, readdirSync } from 'fs';

const searchClient = new SearchClient(
  process.env.AZURE_SEARCH_ENDPOINT!,
  'wiki-chunks',
  new AzureKeyCredential(process.env.AZURE_SEARCH_KEY!)
);

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function syncWikiToVectorDB() {
  const wikiFiles = getChangedFiles('Wiki/**/*.md');
  
  for (const file of wikiFiles) {
    const content = readFileSync(file, 'utf-8');
    const chunks = chunkMarkdown(content, { maxTokens: 400 });
    
    for (const chunk of chunks) {
      const embedding = await openai.embeddings.create({
        model: 'text-embedding-ada-002',
        input: chunk.content
      });
      
      await searchClient.uploadDocuments([{
        id: chunk.id,
        content: chunk.content,
        contentVector: embedding.data[0].embedding,
        metadata: {
          source: file,
          section: chunk.section,
          tags: extractTags(chunk.frontmatter)
        }
      }]);
    }
  }
  
  console.log(`Synced ${wikiFiles.length} files to vector DB`);
}
```sql

---

## Benefits (Agent-First + Vector DB)

### 1. **Zero Learning Curve per User**

**Tradizionale**:
```sql
User deve imparare:
- SQL syntax
- Table schema
- SP signatures
- Wiki navigation
```sql

**Agent-First**:
```sql
User: "dammi utenti"
Agent: capisce, cerca, esegue, risponde
```sql

---

### 2. **Self-Service Completo**

**Scenario**: User vuole creare nuova tabella

```sql
User: "Vorrei creare una tabella PRODUCTS con id, name, price"

Agent (vector search):
  → Trova: "Wiki/db/table-create.md" (confidence 0.92)
  → Trova: "Recipe: db-table:create"
  → Trova: "SP: PORTAL.sp_generate_table_ddl"

Agent (execution):
  → Genera Flyway migration
  → Propone PR
  → Chiede approvazione

User: "Approva"

Agent:
  → Commit migration
  → Esegue Flyway migrate
  → Aggiorna Wiki inventory
  → Risponde: "✅ Tabella creata, DDL: [link]"
```sql

**Tutto senza**:
- Scrivere SQL
- Cercare documentazione
- Aprire PR manualmente

---

### 3. **Knowledge Always Updated**

**Problema tradizionale**:
```sql
Dev aggiorna Wiki → User non sa → User usa info vecchia
```sql

**Con Vector DB**:
```sql
Dev commit Wiki → Pipeline sync → Vector DB aggiornato
→ Agent risponde con info nuova (automatic)
```sql

**Zero lag** tra code/wiki update e agent knowledge!

---

## Governance & Security

### Access Control

**Vector DB filtering**:
```typescript
// Agent can only access allowed scopes
const results = await azureSearch.search(query, {
  filter: `metadata/tags/any(t: t eq 'privacy/internal') 
           AND metadata/tags/any(t: t eq 'audience/${user.role}')`
});
```sql

**Esempio**:
- User role `dev` → Vede wiki internal + code
- User role `business` → Vede solo wiki business, no code

---

### Audit Trail

**Ogni query loggata**:
```sql
-- STATS_EXECUTION_LOG già esiste
INSERT INTO PORTAL.STATS_EXECUTION_LOG (
  proc_name, 
  operation_types, 
  agent_id,
  user_query,
  vector_search_results,
  confidence_score
) VALUES (
  'agent_chat_query',
  'SELECT',
  'agent_dba',
  'dammi lista utenti',
  '[{"source":"Wiki/db/users.md","score":0.92}]',
  0.92
);
```sql

**Analytics**:
- Quali query più frequenti?
- Quali parti Wiki più consultate?
- Agent accuracy (confidence scores)?

---

## Roadmap Implementazione

### Phase 1: MVP (Current, No Vector DB)
- ✅ Agent chat API
- ✅ Recipes exact match
- ✅ Stored procedures
- ✅ Basic logging

### Phase 2: Vector DB Setup (Next Sprint)
- ⏳ Azure AI Search setup
- ⏳ Chunking strategy (Wiki → chunks)
- ⏳ Embedding generation pipeline
- ⏳ CI/CD sync (Git → Vector DB)

### Phase 3: Hybrid Search (Sprint 3)
- ⏳ Layer 1 + 2 + 3 integration
- ⏳ Confidence scoring
- ⏳ Fallback logic

### Phase 4: Advanced Features (Sprint 4+)
- ⏳ Multi-agent orchestration (Expert + Reviewer)
- ⏳ Graph knowledge (relazioni tra chunks)
- ⏳ Agentic workflows (multi-step)

---

## Metrics & KPIs

**Success Criteria** (dopo 3 mesi):

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Agent accuracy (intent) | >85% | TBD | ⏳ |
| Vector search precision | >80% | TBD | ⏳ |
| User satisfaction | >4/5 | TBD | ⏳ |
| Avg response time | <2s | TBD | ⏳ |
| Self-service rate | >70% | TBD | ⏳ |
| Manual Wiki search | <10% | TBD | ⏳ |

---

## Costi Stimati

### Azure AI Search
```sql
Tier: Basic
Storage: 15 GB (2000 chunks * 5KB avg + 500 code snippets)
Replicas: 2
Cost: ~€70/month
```sql

### OpenAI Embeddings
```sql
Model: text-embedding-ada-002
Usage: 2000 chunks * 400 tokens avg = 800K tokens
Cost (one-time): ~€0.10
Cost (incremental, 100 chunks/month): ~€1/month
```sql

### Azure Blob Storage (chunks backup)
```sql
Storage: 5 GB
Cost: ~€0.50/month
```sql

**Total**: ~€71.50/month

**ROI Calculation**:
- 1000 agent queries/month
- 10 min saved per query (vs manual Wiki search)
- 1000 * 10 min = 167 hours/month saved
- Cost per query: €0.07
- **If dev time > €25/hour → ROI positive**

---

## Vedi Anche

### Wiki Correlate
- [Agent Chat Interface](../UX/agent-chat-interface.md) - UI specification
- [AI Security Guardrails](../../../scripts/docs/agentic/ai-security-guardrails.md) - Security layer
- [Multi-Agent Orchestration](./agent-orchestration-weighting.md) - Expert + Reviewer

### Technical Docs
- `docs/agentic/vector-db-setup.md` - Setup guide (TBD)
- `docs/agentic/chunking-strategy.md` - Chunking best practices (TBD)
- `docs/agentic/embedding-pipeline.md` - CI/CD pipeline (TBD)

### Code References
- `scripts/vectordb-sync.ts` - Sync script (TBD)
- `easyway-portal-api/src/services/knowledge-search.service.ts` - Search service (TBD)

---

**Owner**: team-platform, team-architecture  
**Status**: Design complete, implementation planned  
**Priority**: HIGH (strategic direction)  
**Next**: Phase 2 kickoff (Vector DB setup)






