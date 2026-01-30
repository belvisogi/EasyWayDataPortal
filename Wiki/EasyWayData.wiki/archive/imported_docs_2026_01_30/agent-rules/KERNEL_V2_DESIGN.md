# 🚀 Axet Kernel v2.0 - Architecture Design

**Data**: 2026-01-13  
**Status**: Design Phase Complete, Implementation Starting

---

## 📋 Vision

Trasformare Axet da kernel monolitico a sistema modulare context-aware ispirato a **MCP (Model Context Protocol)** e best practices LLM optimization.

### Obiettivi Quantificabili
- **-60% token usage** (12K → 4.5K tokens/request)
- **-66% response time** (1.8s → 0.6s)
- **60% cache hit rate** (da 0%)
- **-66% cost/request** ($0.15 → $0.05)

---

## 🎯 8 Pilastri Architetturali

### 1. Context Management Adattivo
**Problem**: Carica tutto il context sempre, anche se non rilevante  
**Solution**: Tag-based filtering, priority loading  
**Impact**: -60% tokens

### 2. Progressive Disclosure
**Problem**: Full manifest always loaded  
**Solution**: Lightweight metadata → Full on-demand (Anthropic pattern)  
**Impact**: -80% initial load

### 3. Hierarchical Agent Routing
**Problem**: Carica tutto l'agent fleet  
**Solution**: Route by category/domain/capabilities  
**Impact**: -80% agents loaded

### 4. Smart Recipe Discovery
**Problem**: Linear search, no metadata  
**Solution**: Query engine con tags, cost, complexity  
**Impact**: 95% precision, <50ms discovery

### 5. MCP-Like Modularity
**Problem**: Monolithic agents  
**Solution**: Independent servers con tools/resources exposed  
**Impact**: True modularity, deploy indipendente

### 6. Execution Cost Tracking
**Problem**: No visibility su token/cost  
**Solution**: Track tokens, time, cost, cache per action  
**Impact**: Full observability, budget control

### 7. Semantic Caching
**Problem**: No cache, repeat queries costly  
**Solution**: Semantic similarity cache con TTL  
**Impact**: 60% hit rate, instant cached responses

### 8. Context Compression
**Problem**: Full docs always loaded  
**Solution**: Summaries + index, expand on-demand  
**Impact**: -70% context size

---

## 🏗️ Architecture Layers

```
Axet Kernel v2.0
│
├─ Context Layer
│  ├─ ContextLoader          # Adaptive loading by task
│  ├─ LightweightLoader       # Progressive disclosure
│  └─ ContextCompressor       # Summaries + compression
│
├─ Routing Layer
│  ├─ AgentRouter             # Hierarchical by metadata
│  └─ RecipeQueryEngine       # Smart discovery
│
├─ Execution Layer
│  ├─ ServerClient            # MCP-like server protocol
│  ├─ ExecutionTracker        # Cost/token tracking
│  └─ SemanticCache           # Query similarity cache
│
└─ Configuration
   ├─ context-strategies.yaml  # Task → docs mapping
   ├─ compression-policies.yaml # Compression rules
   ├─ execution-budgets.yaml   # Token/cost limits
   └─ agents/index.yaml        # Agent metadata index
```

---

## 📦 New Directory Structure

```
Rules.Vault/
├─ core/                      # NEW: Core v2.0 modules
│  ├─ context-loader.js
│  ├─ lightweight-loader.js
│  ├─ context-compressor.js
│  ├─ agent-router.js
│  ├─ recipe-query.js
│  ├─ server-client.js
│  ├─ execution-tracker.js
│  └─ semantic-cache.js
│
├─ servers/                   # NEW: MCP-style servers
│  ├─ ado-server/
│  │  ├─ manifest.json
│  │  ├─ tools.json
│  │  ├─ resources.json
│  │  └─ handler.ps1
│  ├─ docs-server/
│  └─ wiki-server/
│
└─ agents/                    # ENHANCED: Add metadata
   ├─ index.yaml              # NEW: Agent registry
   └─ agent_*/                # Add category/domain/capabilities

Rules/
├─ context-strategies.yaml    # NEW: Task routing rules
├─ compression-policies.yaml  # NEW: Compression config
├─ execution-budgets.yaml     # NEW: Cost limits
└─ KERNEL_V2_DESIGN.md        # This file
```

---

## 🗓️ Implementation Roadmap

### Phase 1: Foundation (Week 1-2) 🟢 IN PROGRESS
- [/] Context Management Adattivo
- [ ] Progressive Disclosure
- [ ] Agents Index + metadata

**Deliverables**:
- `core/context-loader.js`
- `context-strategies.yaml`
- `agents/index.yaml`
- Context loading -60% tokens

### Phase 2: Intelligence (Week 3-4)
- [ ] Hierarchical Agent Routing
- [ ] Smart Recipe Discovery
- [ ] Execution Cost Tracking

**Deliverables**:
- `core/agent-router.js`
- `core/recipe-query.js`
- `core/execution-tracker.js`
- Routing accuracy 98%+

### Phase 3: Optimization (Week 5-6)
- [ ] Semantic Caching
- [ ] Context Compression
- [ ] Performance tuning

**Deliverables**:
- `core/semantic-cache.js`
- `core/context-compressor.js`
- `compression-policies.yaml`
- 60% cache hit rate

### Phase 4: Modularity (Week 7-8)
- [ ] MCP-Like Server Migration
- [ ] Server Client
- [ ] Testing & Documentation

**Deliverables**:
- `servers/*` migrati
- `core/server-client.js`
- Full backward compatibility
- v2.0 GA release

---

## 📊 Success Metrics

| Metric | v1.0 Current | v2.0 Target | Improvement |
|--------|--------------|-------------|-------------|
| **Token/request** | 12,000 | 4,500 | -62% ✅ |
| **Response time** | 1.8s | 0.6s | -66% ✅ |
| **Cache hit rate** | 0% | 60% | +60pp ✅ |
| **Cost/request** | $0.15 | $0.05 | -66% ✅ |
| **Agent load** | 800ms | 250ms | -69% ✅ |
| **Accuracy** | 100% | 95% | -5% ⚠️ acceptable |

---

## 🔬 Research Foundation

Sistema basato su:
- ✅ **MCP (Model Context Protocol)**: Modular server architecture
- ✅ **Anthropic Progressive Disclosure**: Load lightweight → full on-demand
- ✅ **Hierarchical RAG**: Multi-level document indexing
- ✅ **Semantic Caching**: Query similarity, non exact match
- ✅ **Token Optimization**: Context compression, summary, index-only

**References**:
- Model Context Protocol Spec (Anthropic)
- RAG Optimization Papers (2024)
- LLM Context Management Best Practices

---

## 💡 Key Innovations

1. **Context Budget per Task**: `ado-query` ha max 5K tokens, non 12K
2. **Semantic Cache**: "mostra pbi 184797" ≈ "visualizza work item 184797"
3. **Progressive Manifests**: Leggi solo metadata, full se rilevante
4. **MCP Servers**: Agents come servizi indipendenti
5. **Cost Tracking**: Dashboard real-time token/cost/cache

---

## 🚨 Backward Compatibility

- ✅ **100% backward compatible**: v1.0 API unchanged
- ✅ **Opt-in v2**: Flag `--v2` per nuove features
- ✅ **Gradual migration**: Agent by agent
- ✅ **Fallback**: Se v2 fail → v1.0 automatico

---

## 🔗 Related Documentation

- [Implementation Plan](../../../.gemini/antigravity/brain/.../implementation_plan.md) - Dettagli tecnici completi
- [TAGGING_SYSTEM.md](TAGGING_SYSTEM.md) - Sistema tag gerarchico (base per routing)
- [AGENT_DOCS_SYNC.md](AGENT_DOCS_SYNC.md) - Agent manutenzione docs
- [GOVERNANCE.md](GOVERNANCE.md) - Execution policy

---

**Version**: 2.0.0-alpha  
**Status**: Phase 1 in corso  
**Lead**: Axet Architecture Team  
**Review**: 2026-01-13
