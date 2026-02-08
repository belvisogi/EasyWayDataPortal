# Agent Security

**Version:** 2.0.0
**Evolution Level:** 2 (LLM-powered)
**LLM Provider:** DeepSeek (deepseek-chat)
**Status:** Production Ready
**Owner:** team-platform

---

## Overview

Security agent per gestione governance-driven di segreti, identity, accessi e AI-driven threat analysis.

**Capabilities:**
- **security:analyze** - AI threat assessment (DeepSeek LLM) su configurazioni, codice, infrastruttura
- **kv-secret:set** - Imposta/aggiorna secrets in Azure Key Vault
- **kv-secret:reference** - Genera Key Vault references per App Settings
- **access-registry:propose** - Propone entry nel registro accessi (audit trail)

## Quick Start

```powershell
# AI Security Analysis (usa DeepSeek)
pwsh scripts/pwsh/agent-security.ps1 -Action "security:analyze" `
  -Query "Analizza la configurazione Docker del nostro stack" `
  -Provider DeepSeek -Model deepseek-chat -ApiKey $env:DEEPSEEK_API_KEY

# Set secret in Key Vault (WhatIf mode)
pwsh scripts/pwsh/agent-security.ps1 -Action "kv-secret:set" `
  -VaultName "easyway-vault" -SecretName "db--portal--connstring" `
  -SecretValue "..." -WhatIf

# Get Key Vault reference
pwsh scripts/pwsh/agent-security.ps1 -Action "kv-secret:reference" `
  -VaultName "easyway-vault" -SecretName "db--portal--connstring"

# Via intent file
pwsh scripts/pwsh/agent-security.ps1 -IntentPath "agents/agent_security/templates/intent.security-analyze.sample.json"
```

## File Structure

```
agents/agent_security/
├── manifest.json                 # Agent config v2.0 (con llm_config)
├── priority.json                 # Validation rules & guardrails
├── PROMPTS.md                    # System prompt per DeepSeek
├── README.md                     # This file
├── memory/
│   └── context.json              # Agent memory (stats, knowledge, llm_usage)
└── templates/
    ├── intent.security-analyze.sample.json
    ├── intent.kv-secret-set.sample.json
    ├── intent.kv-secret-reference.sample.json
    └── intent.access-registry-propose.sample.json
```

## LLM Integration (Level 2)

| Aspetto | Valore |
|---------|--------|
| Provider | DeepSeek |
| Model | deepseek-chat |
| Cost per call | ~$0.00025 |
| Monthly estimate | ~$0.05 |
| Temperature | 0.1 |
| Max tokens | 1000 |

Lo script supporta anche Ollama e OpenAI tramite il parametro `-Provider`.

## Guardrails (priority.json)

- **no-secret-in-logs**: Mai loggare valori segreti
- **kv-naming**: Pattern `<system>--<area>--<name>`
- **prod-approval-required**: Operazioni prod richiedono Human_Governance_Approval
- **llm-no-secrets-in-prompt**: Mai inviare valori segreti al LLM

## Actions

| Action | Description | LLM | Approval |
|--------|-------------|-----|----------|
| `security:analyze` | AI threat assessment | Si | No |
| `kv-secret:set` | Set/update secret in KV | No | Prod: Si |
| `kv-secret:reference` | Get KV reference string | No | No |
| `access-registry:propose` | Propose access entry | No | No |

## Migration from v1.0

Changes in v2.0:
- Added `llm_config` with DeepSeek integration
- Added `skills_required` / `skills_optional`
- Enhanced `priority.json` with LLM guardrails and prod approval rules
- Added 4 intent templates
- Enhanced `memory/context.json` with knowledge tracking and LLM usage
- Structured `allowed_paths` as read/write
- Structured `knowledge_sources` with priority
