---
title: "Agent Docs Sync - Documentation Maintenance"
category: governance
domain: docs
features:
  - validation
  - sync
  - maintenance
entities: []
tags: [agent, docs, sync, validation, metadata]
id: ew-archive-imported-docs-2026-01-30-agent-rules-agent-docs-sync
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
---

# 🤖 Agent Docs Sync - Documentazione

## 📋 Overview

Agent LLM dedicato alla manutenzione automatica della documentazione. Mantiene allineamento tra documenti (.md) e codice (.ps1), valida metadata, verifica cross-references.

**Location**: `Rules.Vault/agents/agent_docs_sync/`

---

## 🎯 Responsabilità

1. **Auto-Sync**: Quando script cambia → verifica docs alignment
2. **Validation**: Tag consistency (.md ↔ .ps1)
3. **Maintenance**: Link bidirezionali, orphaned files, coverage report

---

## 📂 Struttura

```
Rules.Vault/agents/agent_docs_sync/
├── manifest.json           # Agent definition + actions
├── parse-metadata.ps1      # Helper: parse YAML/METADATA
└── validate-cross-refs.ps1 # Helper: cross-ref validator

Rules.Vault/scripts/ps/
└── agent-docs-sync.ps1     # Main orchestrator
```

---

## ⚙️ Actions

### 1. docs:check (Safe, Auto-Run)
Verifica allineamento docs ↔ scripts.

```powershell
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action check -Scope all
```

**Output**:
- ✅/❌ Per ogni coppia doc-script
- Issues list (category mismatch, missing refs, etc.)

**Checks**:
- Category match
- Domain match
- Bidirectional references (doc → script, script → doc)

---

### 2. docs:validate (Safe, Auto-Run)
Valida metadata YAML frontmatter e .METADATA blocks.

```powershell
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action validate
```

**Validates**:
- Required fields (category, domain, tags)
- Valid category values
- Taxonomy compliance

---

### 3. docs:report (Safe, Auto-Run)
Genera report su coverage, orphaned files, tag statistics.

```powershell
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action report -Format markdown
```

**Formats**: console, markdown, json

---

### 4. docs:sync (Require Approval)
Sincronizza docs basandosi su script changes. Genera PR con update suggeriti.

```powershell
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action sync -ChangedFile agent-ado-scrummaster.ps1
```

**Workflow**:
1. Parse changed script metadata
2. Find related docs via `related-docs` field
3. Check alignment
4. Generate PR con suggested updates
5. Update `last-updated` timestamps

---

## 🔧 Helper Functions

### parse-metadata.ps1

**`Get-MarkdownMetadata`**:
- Estrae YAML frontmatter da .md
- Parse key-value pairs
- Supporta arrays `[item1, item2]`

**`Get-ScriptMetadata`**:
- Estrae .METADATA block da .ps1
- Parse PowerShell comment block
- Supporta multi-line arrays

### validate-cross-refs.ps1

**`Test-DocScriptAlignment`**:
- Compara metadata doc vs script
- Check category/domain match
- Valida bidirectional references
- Ritorna PSCustomObject con Aligned + Issues

---

## 📊 Execution Policy

```json
{
  "autonomous_execution": true,
  "safe_actions": [
    "docs:check",
    "docs:validate",
    "docs:report"
  ],
  "require_approval": [
    "docs:sync"
  ]
}
```

**Rationale**: Check/validate/report sono read-only. Sync modifica file quindi gated.

---

## 🔄 Workflow Automatico

### Git Hook Integration (Future)

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Check if any .ps1 changed
changed_scripts=$(git diff --cached --name-only | grep '\.ps1$')

if [ -n "$changed_scripts" ]; then
  echo "Running docs alignment check..."
  pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action check
  
  if [ $? -ne 0 ]; then
    echo "❌ Docs misalignment detected!"
    echo "Run 'docs:sync' to fix or commit with --no-verify"
    exit 1
  fi
fi
```

---

## 📝 KB Recipes

```jsonl
{"id":"kb-docs-check","trigger":"check documentazione","intent":"docs:check","autoExecute":true,"safe":true}
{"id":"kb-docs-validate","trigger":"valida metadata","intent":"docs:validate","autoExecute":true,"safe":true}
{"id":"kb-docs-report","trigger":"report documentazione","intent":"docs:report","autoExecute":true,"safe":true}
```

---

## 🎯 Use Cases

### Use Case 1: Developer aggiunge parametro a script
```
1. Edit: agent-ado-scrummaster.ps1 (adds -WithHistory param)
2. Git Hook: Triggers docs:check
3. Agent: Detects ADO_EXPORT_GUIDE.md missing example
4. Agent: Runs docs:sync
5. Agent: Generates PR with updated doc + example
6. Developer: Reviews & merges PR
```

### Use Case 2: Weekly audit
```powershell
# Cron job: Every Monday 9am
pwsh Rules.Vault/scripts/ps/agent-docs-sync.ps1 -Action report -Format markdown > weekly-docs-audit.md
```

---

## 🔍 Metadata Validation Rules

### Required Fields (.md)
- `category` (one of: core, ado, wiki, governance, tools, troubleshoot)
- `domain` (based on category)
- `tags` (array, min 1 tag)

### Required Fields (.ps1)
- `category`
- `domain`
- `tags` (comma-separated, max 5)
- `related-docs` (array of .md files)

### Cross-Reference Rules
- Doc `script-refs` MUST reference existing .ps1
- Script `related-docs` MUST reference existing .md
- Bidirectional: If doc→script, then script→doc

---

## 📊 Metrics

Agent tracks:
- **Coverage**: % files with metadata
- **Alignment**: % docs aligned with scripts
- **Orphans**: Files senza cross-references
- **Tag Consistency**: Category/domain violations

**Target KPIs**:
- Coverage: 100%
- Alignment: 95%+
- Orphans: 0
- Violations: 0

---

## 🚀 Roadmap

### Phase 1: Core Functionality (Done)
- ✅ Agent structure + manifest
- ✅ Helper scripts (parse, validate)
- ✅ Actions: check, validate, report
- ✅ KB recipes integration

### Phase 2: Metadata Setup (In Progress)
- [ ] Add frontmatter to all .md
- [ ] Add .METADATA to key .ps1
- [ ] Create DOCS_INDEX.yaml

### Phase 3: Auto-Sync (Future)
- [ ] Implement docs:sync logic
- [ ] PR auto-generation
- [ ] Git hook integration

### Phase 4: AI Integration (Future)
- [ ] ai-context-refresh.ps1 uses tags
- [ ] Smart doc loading by task type
- [ ] Progressive disclosure

---

## 📚 Related Documentation

- [TAGGING_SYSTEM.md](TAGGING_SYSTEM.md) - Sistema tagging gerarchico
- [DOCS_INDEX.yaml](DOCS_INDEX.yaml) - File index completo
- [EXECUTION_RULES.md](EXECUTION_RULES.md) - Autonomous execution rules
- [GOVERNANCE.md](GOVERNANCE.md) - Orchestration & governance

---

**Agent**: `agent_docs_sync`  
**Versione**: 1.0  
**Data**: 2026-01-12  
**Status**: Production-ready (Phase 1 complete)



