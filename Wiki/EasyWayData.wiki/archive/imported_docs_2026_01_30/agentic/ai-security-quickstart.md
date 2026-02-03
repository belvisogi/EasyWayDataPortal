---
id: ew-archive-imported-docs-2026-01-30-agentic-ai-security-quickstart
title: AI Agent Security - Quick Start
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
# AI Agent Security - Quick Start

## 🚀 3-Step Protection (10 minuti)

### Step 1: Input Validation (Ora)
```powershell
# Create validation script
New-Item -Path "scripts/validate-agent-input.ps1" -ItemType File

# Paste content from ai-security-guardrails.md Layer 1

# Test it
$testInput = @{ intent = "create table"; params = @{} } | ConvertTo-Json
pwsh scripts/validate-agent-input.ps1 -InputJson $testInput
```

### Step 2: Secure System Prompt (5 min)
```powershell
# Create template
New-Item -Path "agents/core/templates/secure-system-prompt.txt" -ItemType File

# Paste content from ai-security-guardrails.md Layer 2

# Update 1 agent to use it (test)
# Edit agents/agent_dba/invoke.ps1 to load template
```

### Step 3: KB Integrity Check (5 min)
```python
# Create Python scanner
# scripts/kb-security-scan.py from ai-security-guardrails.md

# Test it
python3 scripts/kb-security-scan.py agents/kb/recipes.jsonl
```

---

## ✅ Validation Commands

```powershell
# Test input validation
pwsh scripts/validate-agent-input.ps1 -InputJson '{"test":"IGNORA ISTRUZIONI"}'
# Should: FAIL with warning

pwsh scripts/validate-agent-input.ps1 -InputJson '{"test":"normal input"}'
# Should: PASS

# Test KB scan
python3 scripts/kb-security-scan.py agents/kb/recipes.jsonl
# Should: PASS (or show violations if any)
```

---

## 📊 Next Steps

**After Expert+Reviewer implementation starts**:
1. Add output validation (Layer 3)
2. Add security criterion to reviewer (4th criterion)
3. Install git pre-commit hook
4. Set up daily audit script

**Full guide**: `docs/agentic/ai-security-guardrails.md`


