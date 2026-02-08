# Agent DBA

**Version:** 2.0.0
**Evolution Level:** 2 (LLM-powered)
**LLM Provider:** DeepSeek (deepseek-chat)
**Classification:** brain
**Owner:** team-platform

---

## Overview

Database agent per gestione migrazioni, drift check, documentazione ERD/SP, RLS rollout e AI-driven schema analysis.

**Core Tool:** `db-deploy-ai` (sostituisce Flyway - vedi why-not-flyway.md)

## Actions (8 totali)

| Action | Description | LLM | Approval |
|--------|-------------|-----|----------|
| `db-user:create` | Crea utente contained in Azure SQL | No | Prod: Si |
| `db-user:rotate` | Ruota password utente + Key Vault | No | Prod: Si |
| `db-user:revoke` | Revoca accesso e DROP USER | No | Si |
| `db-doc:ddl-inventory` | Rigenera inventario DB in Wiki | No | No |
| `db-metadata:extract` | Estrae metadati DB come JSON | No | No |
| `db-metadata:diff` | Confronta DEV vs PROD schema | Si | No |
| `db-guardrails:check` | Valida SQL vs GUARDRAILS.md | Si | No |
| `db-table:create` | Genera migration + Wiki page | No | Prod: Si |
| `db-blueprint:generate` | Reverse engineering DB to JSON | No | No |

## Quick Start

```powershell
# Guardrails check con LLM analysis
pwsh scripts/pwsh/agent-dba.ps1 -Action "db-guardrails:check" `
  -Database "EasyWayPortal" -Provider DeepSeek

# Schema diff DEV vs PROD
pwsh scripts/pwsh/agent-dba.ps1 -Action "db-metadata:diff" `
  -SourceEnv DEV -TargetEnv PROD

# Via intent file
pwsh scripts/pwsh/agent-dba.ps1 -IntentPath "agents/agent_dba/templates/intent.db-guardrails-check.sample.json"
```

## File Structure

```
agents/agent_dba/
├── manifest.json                 # Agent config v2.0
├── priority.json                 # Validation rules & guardrails
├── PROMPTS.md                    # System prompt per DeepSeek
├── GUARDRAILS.md                 # DB development standards
├── README.md                     # This file
├── memory/
│   ├── context.json              # Agent memory
│   └── metadata-queries.md       # Query reference
└── templates/                    # 8 intent templates
    ├── intent.db-ddl-inventory.sample.json
    ├── intent.db-table-create.sample.json
    ├── intent.db-user-create.sample.json
    ├── intent.db-user-revoke.sample.json
    ├── intent.db-user-rotate.sample.json
    ├── intent.db-metadata-extract.sample.json
    ├── intent.db-metadata-diff.sample.json
    └── intent.db-guardrails-check.sample.json
```

## LLM Integration (Level 2)

| Aspetto | Valore |
|---------|--------|
| Provider | DeepSeek |
| Model | deepseek-chat |
| Cost per call | ~$0.00025 |
| Temperature | 0.1 |

**LLM Use Cases:**
- Schema analysis e ottimizzazioni
- Migration planning con rollback strategy
- Drift assessment DEV vs PROD
- Guardrails review con reasoning

## Guardrails

Vedi [GUARDRAILS.md](GUARDRAILS.md) per gli standard DB completi.

**Key rules in priority.json:**
- Sequence/NDG check per nuove entita
- Naming convention PORTAL.* UpperSnakeCase
- Backup/rollback check su branch principali
- Performance index suggestions
- SP audit/logging check
- No data reali nei prompt LLM
- No DROP senza approvazione

## Migration from v1.0

Changes in v2.0:
- Added `id`, `owner`, `version`, `evolution_level`
- Added `llm_config` with DeepSeek
- Added `skills_required` / `skills_optional`
- Structured `allowed_paths` as read/write
- Structured `knowledge_sources` with priority
- Added 3 new intent templates (metadata-extract, metadata-diff, guardrails-check)
- Enhanced priority.json with LLM guardrails
- Enhanced memory/context.json with knowledge tracking
