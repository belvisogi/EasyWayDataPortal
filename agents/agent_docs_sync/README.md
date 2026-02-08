# agent_docs_sync
**Role**: Agent_Docs_Sync | **Level**: 2 (LLM-powered) | **Version**: 2.0.0

## Overview
Mantiene allineamento tra documentazione e codice: valida tag metadata, verifica cross-references, suggerisce aggiornamenti docs quando script cambiano. Usa DeepSeek LLM per analisi semantica dei contenuti.

## LLM Integration (Level 2)
- **Provider**: DeepSeek (deepseek-chat)
- **Use Cases**: doc alignment analysis, metadata quality check, cross-ref suggestions, tag proposals
- **Cost**: ~$0.00025/call, ~$0.03/month
- **Fallback**: skip_llm_analysis (funziona senza LLM, solo rule-based)

## Capabilities
- **docs:check** - Verifica allineamento docs/scripts con analisi semantica LLM
- **docs:validate** - Valida metadata YAML frontmatter e taxonomy compliance
- **docs:report** - Genera report coverage con sintesi LLM
- **docs:sync** - Sincronizza docs da script changes con diff LLM-aware
- **docs:scan** - Propone TAG basandosi sul contenuto reale dei file

## Architecture
- **Scripts**: `scripts/pwsh/agent-docs-sync.ps1`, `scripts/pwsh/agent-docs-scanner.ps1`
- **Helpers**: `parse-metadata.ps1`, `validate-cross-refs.ps1`
- **Manifest**: manifest.json (v2.0)
- **System Prompt**: PROMPTS.md
- **Validation Rules**: priority.json
- **Templates**: templates/intent.*.sample.json

## Usage
```bash
# Check allineamento completo
axctl --intent docs-check

# Valida metadata di un file specifico
pwsh scripts/pwsh/agent-docs-sync.ps1 -Action validate -Path Rules/ADO_EXPORT_GUIDE.md

# Sync basato su cambio script
pwsh scripts/pwsh/agent-docs-sync.ps1 -Action sync -ChangedFile agent-ado-userstory.ps1
```

## Upgrade Log
- **v1.0.0**: Rule-based docs alignment (Level 1)
- **v2.0.0**: DeepSeek LLM integration, priority.json, templates, PROMPTS.md (Level 2)
