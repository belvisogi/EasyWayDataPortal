---
title: "Tagging System - Hierarchical Metadata Framework"
category: governance
domain: docs
features:
  - taxonomy
  - hierarchical
  - metadata
entities: []
tags: [tagging, metadata, taxonomy, llm-optimization]
id: ew-archive-imported-docs-2026-01-30-agent-rules-tagging-system
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
---

# 🏷️ Sistema di Tagging Gerarchico - Documentazione

## 📋 Overview

Sistema di tagging a **3 livelli gerarchici** per ottimizzare il caricamento selettivo della documentazione da parte degli LLM.

**Obiettivo**: Ridurre del 60% i token caricati, caricando solo documenti rilevanti per il task corrente.

---

## 🎯 Tassonomia (3 Livelli)

### Livello 1: CATEGORY (Macro Area)
- `core` - Regole base, execution, mindset
- `ado` - Azure DevOps specifico
- `wiki` - Documentazione/Wiki management
- `governance` - Orchestration, policy, safety
- `tools` - Scripts helper, utilities
- `troubleshoot` - FAQ, debugging

### Livello 2: DOMAIN (Area Funzionale)
```yaml
core:
  - execution   # Autonomous execution rules
  - tasks       # Task-oriented workflows
  - reference   # Master reference docs

ado:
  - query       # PBI get, children, export
  - pipeline    # Pipeline operations
  - creation    # Create PBI, test cases

wiki:
  - review      # Wiki normalize & review
  - glossary    # Glossario termini

governance:
  - orchestrator # orchestrator.js
  - recipes      # KB recipes.jsonl
  - manifests    # Agent manifests

tools:
  - export       # Helper export tools
  - context      # Context management

troubleshoot:
  - ado-qa       # ADO FAQ
  - general      # General troubleshooting
```

### Livello 3: FEATURE (Funzionalità Specifica)
```yaml
ado/query:
  - pbi-get          # Vista 360° work item
  - pbi-children     # Navigazione gerarchica
  - export-print     # Export con stampa auto

ado/pipeline:
  - get-runs         # Build/Release linkate
  - list             # Lista pipeline
  - history          # Storico esecuzioni

wiki/review:
  - auto-detect      # Auto-detect wiki path
  - glossary-check   # Check glossario
  - normalize        # Normalizzazione docs
```

---

## 📝 Formato Tag

### Documenti .md (YAML Frontmatter)
```yaml
---
title: "ADO Export Guide"
category: ado
domain: query
features:
  - pbi-get
  - pbi-children
  - export-print
tags:
  - ado
  - query
  - export
  - pbi
priority: medium
audience:
  - ai-assistant
  - developer
script-refs:
  - agent-ado-governance.ps1
  - show-last-export.ps1
last-updated: 2026-01-12
related:
  - EXECUTION_RULES.md
  - RULES_MASTER.md
---
```

### Script .ps1 (PowerShell .METADATA Block)
```powershell
<#
.SYNOPSIS
  Vista 360° work item ADO

.METADATA
  category: ado
  domain: query
  tags: ado, query, pbi
  safe-to-auto-run: true
  related-docs:
    - Rules/ADO_EXPORT_GUIDE.md
    - Rules/EXECUTION_RULES.md
  dependencies:
    - Get-AdoAuthHeader

.DESCRIPTION
  Retrieves work item with full 360° view.
#>
```

**Nota**: Script .ps1 hanno metadata MINIMAL (solo category, domain, 3-5 tags), documenti .md hanno metadata COMPLETA.

---

## 🔍 Sistema Priorità

```yaml
Priority Levels:
  critical: Load sempre (EXECUTION_RULES)
  high:     Load per maggior parte task (RULES_MASTER, TASK_RULES)
  medium:   Load solo se dominio rilevante (ADO_EXPORT_GUIDE, WIKI_REVIEW_GUIDE)
  low:      Load solo se feature specifica (GOVERNANCE, QA_TROUBLESHOOTING)
```

---

## 💡 Use Cases

### Use Case: "Mostra PBI 184797"

**LLM Query Logic**:
```
Task: ado-query
Tags needed: #ado #query #pbi-get

Load:
  - EXECUTION_RULES.md (critical)
  - RULES_MASTER.md (high, quick ref)
  - ADO_EXPORT_GUIDE.md (medium, domain match)

Skip:
  - WIKI_REVIEW_GUIDE.md (non rilevante)
  - GOVERNANCE.md (non rilevante)
```

**Risparmio**: 60% token (-6 file non caricati)

---

## 📊 Mappatura File Esistenti

| File | Category | Domain | Features | Priority |
|------|----------|--------|----------|----------|
| EXECUTION_RULES.md | core | execution | autonomous, safe-commands | critical |
| TASK_RULES.md | core | tasks | workflows, templates | high |
| RULES_MASTER.md | core | reference | complete | high |
| ADO_EXPORT_GUIDE.md | ado | query | pbi-get, export, pipeline | medium |
| WIKI_REVIEW_GUIDE.md | wiki | review | auto-detect, glossary | medium |
| GOVERNANCE.md | governance | orchestrator | recipes, manifests | medium |
| QA_TROUBLESHOOTING.md | troubleshoot | ado-qa | faq | low |

---

## 🔗 File Index (DOCS_INDEX.yaml)

Vedi [`DOCS_INDEX.yaml`](DOCS_INDEX.yaml) per la mappatura completa di:
- Documenti con metadata
- Script con metadata
- Cross-references bidirezionali
- Dependency graph

---

## 📚 Ricerca Scientifica

Sistema basato su best practices validate:
- ✅ **Hierarchical RAG** (2024): Multi-level document indexing
- ✅ **Metadata Filtering**: Industry standard per RAG optimization
- ✅ **Progressive Disclosure** (Anthropic): Load by relevance
- ✅ **Context-Aware Retrieval**: Semantic layer via metadata

**References**:
- PageIndex: Hierarchical tree indexes for LLM navigation
- Anthropic Agent Skills: YAML frontmatter pattern
- RAG Optimization Papers: Metadata filtering reduces search space 60%+

---

## 🛠️ Implementazione

### Phase 1: Metadata Setup
1. Aggiungere frontmatter YAML a tutti .md
2. Aggiungere .METADATA a script principali .ps1
3. Creare DOCS_INDEX.yaml

### Phase 2: Agent Integration
1. `agent_docs_sync` valida metadata
2. Check cross-references .md ↔ .ps1
3. Report coverage e orphaned files

### Phase 3: LLM Integration
1. `ai-context-refresh.ps1` usa tag filtering
2. Load selettivo basato su task type
3. Progressive disclosure (critical → high → medium)

---

## ✅ Validation

Tool: `agent_docs_sync`
```powershell
# Check alignment
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action check

# Validate metadata
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action validate

# Report coverage
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action report
```

---

**Versione**: 1.0  
**Data**: 2026-01-12  
**Status**: Design completo, Phase 1 in corso



