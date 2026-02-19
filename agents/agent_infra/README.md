# agent_infra
**Role**: Agent_Infra | **Level**: L2 | **Version**: 2.0.0

## Overview
IaC/Terraform governato con AI-driven drift analysis. Level 2 agent con DeepSeek LLM e RAG su Wiki infra.

## Capabilities

| Action | Type | Description |
|--------|------|-------------|
| `infra:terraform-plan` | Scripted (L1) | terraform init/validate/plan — WhatIf-by-default, no apply |
| `infra:drift-check` | LLM+RAG (L2) | AI drift assessment: confronta infra reale vs IaC, classifica severita, propone remediation |

## Architecture
- **Script**: `scripts/pwsh/agent-infra.ps1`
- **Manifest**: `manifest.json` (v2.0.0)
- **System Prompt**: `PROMPTS.md`
- **Skills required**: `retrieval.llm-with-rag`, `retrieval.rag-search`
- **LLM**: DeepSeek `deepseek-chat` (migrato da OpenAI gpt-4o)
- **RAG**: Qdrant `easyway_wiki`, domini: infrastructure, terraform, deploy, dr

## Usage

```powershell
# Terraform plan (scripted, WhatIf)
pwsh scripts/pwsh/agent-infra.ps1 -Action 'infra:terraform-plan' -WhatIf -IntentPath agents/agent_infra/templates/intent.infra-terraform-plan.sample.json

# Drift check (LLM+RAG)
pwsh scripts/pwsh/agent-infra.ps1 -Action 'infra:drift-check' -Query "Verificare se le App Service hanno le impostazioni di scaling configurate in Terraform" -JsonOutput
```

## Intent Templates
- `templates/intent.infra-terraform-plan.sample.json`
- `templates/intent.infra-drift-check.sample.json`

## Guardrails
- **Apply bloccato**: mai eseguire `terraform apply` senza `Human_Governance_Approval`
- **WhatIf default**: ogni plan e' simulazione salvo `-WhatIf:$false`
- **Injection defense**: RAG context isolato in `[EXTERNAL_CONTEXT_START/END]`
