# agent_pr_manager
**Role**: Agent_PR_Manager | **Level**: 2 (LLM-powered) | **Version**: 2.0.0

## Overview
Gestione Pull Request lifecycle: analizza changes, genera descrizioni intelligenti, propone reviewer, valida gates pre-merge. Usa DeepSeek LLM per generare PR description context-aware e analisi di impatto.

## LLM Integration (Level 2)
- **Provider**: DeepSeek (deepseek-chat)
- **Use Cases**: PR description generation, change impact analysis, reviewer suggestion, gates validation
- **Cost**: ~$0.00025/call, ~$0.03/month
- **Fallback**: skip_llm_analysis (genera descrizione template-based senza LLM)

## Capabilities
- **pr:create** - Crea PR con descrizione LLM-generated basata sui diff
- **pr:analyze** - Analisi impatto cambiamenti con LLM reasoning
- **pr:suggest-reviewers** - Suggerisce reviewer basandosi su ownership map
- **pr:validate-gates** - Valida gates pre-merge (CI, tests, governance)

## Architecture
- **Script**: `scripts/pwsh/agent-pr.ps1`
- **Manifest**: manifest.json (v2.0)
- **System Prompt**: PROMPTS.md
- **Validation Rules**: priority.json
- **Templates**: templates/intent.*.sample.json

## Usage
```bash
# Crea PR con descrizione auto-generata (preview)
axctl --intent pr-create --whatIf

# Analizza impatto cambiamenti
axctl --intent pr-analyze --scope full

# Valida gates prima del merge
axctl --intent pr-validate-gates --strict
```

## Branching Strategy
- feature/* → develop (standard PR)
- develop → release/* (release PR, requires gates)
- release/* → main (production, requires Human_Governance_Approval)

## Upgrade Log
- **v2.0.0**: Created as Level 2 agent with DeepSeek LLM, priority.json, templates, PROMPTS.md
