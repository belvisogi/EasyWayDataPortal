---
title: Agents Registry (owner, domini, intent)
tags: [domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, agents, governance, n8n, ewctl, rag]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-control-plane-agents-registry
chunk_hint: 250-350
entities: []
include: true
summary: Registro canonico degli agenti di EasyWay DataPortal con ownership per dominio, intent principali ed entrypoint (n8n.dispatch/ewctl).
llm: 
pii: none
owner: team-platform
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

# Agents Registry (owner, domini, intent)

## Contesto (repo)
- Entry point canonico esecuzione: `scripts/ewctl.ps1`
- Entry point canonico dispatch: `orchestrations/orchestrator-n8n.md` (policy: nuovi intent via `orchestrator.n8n.dispatch`)
- Contratti: `intent-contract.md`, `output-contract.md`
- Mapping tecnico: `orchestrations/mapping-matrix.md`
- KB: `agents/kb/recipes.jsonl`
- Log eventi: `agents/logs/events.jsonl`
- Goals: `agents/goals.json`

## Agenti (attivi)
Registro sintetico (source of truth operativa: `agents/<agent>/manifest.json`).  
Nota: gli intent elencati sotto sono quelli “più usati”/raccomandati; l’entrypoint canonico resta `orchestrator.n8n.dispatch`.

| Agent | Dominio owner | Scopo | Intent principali | Entrypoint tipico |
|---|---|---|---|---|
| agent_governance | control-plane | gates/policy/approvals | `checklist`, `dbdrift`, `kbconsistency`, `doc-alignment` | `ewctl` + pipeline |
| agent_docs_review | docs-governance | Wiki/KB quality + drift checks | `wiki-normalize-review`, `docs-review`, `docs.agents.readme.sync` | `ewctl --wiki` |
| **agent_docs_sync** ✨ | docs-governance | sincronizzazione automatica doc (Wiki↔KB↔Manifest↔Code) | `docs:sync`, `docs:check-drift` | `scripts/agent-docs-sync.ps1` |
| agent_pr_manager | control-plane | PR proposal (no merge) | `pr-proposed` | `scripts/agent-pr.ps1` |
| agent_scrummaster | delivery | backlog/ADO facilitation | `boards/*` (operatività ADO) | `scripts/ado/*` |
| agent_ado_userstory | delivery | gestione User Story su ADO | `ado:userstory.export`, `ado:userstory.create` | `scripts/agent-ado-userstory.ps1` |
| agent_ams | ops | checklist/setup/ADO variable group | `predeploy-checklist`, `setup-local-env`, `ado-variable-group` | `scripts/checklist.ps1`, `scripts/setup-env.ps1` |
| agent_dba | db | Flyway/DDL/doc DB + utenti DB | `db-user:create`, `db-user:rotate`, `db-user:revoke`, `db-doc:ddl-inventory`, `db-table:create` | `scripts/agent-dba.ps1` |
| agent_datalake | datalake | structure/ACL/retention/export | `dlk-ensure-structure`, `dlk-apply-acl`, `dlk-set-retention`, `dlk-export-log` | `scripts/agent-datalake.ps1` |
| agent_security | security | lifecycle segreti/identity/permessi (KV+RBAC+audit) | `kv-secret:reference`, `kv-secret:set`, `iam:provision.access` | `scripts/agent-security.ps1` |
| agent_api | support/api | triage errori REST per n8n | `api-error:triage` | `scripts/agent-api.ps1` |
| agent_frontend | frontend | wiring UI/portal/MSAL | `portal/*` (UI tools) | portal routes + frontend |
| agent_dq_blueprint | data-quality | blueprint DQ da file | `blueprint-from-file` | `agents/agent_dq_blueprint/*` |
| agent_creator | meta | scaffolding nuovi agenti (manifest/KB/Wiki) | `agent.scaffold` | `scripts/agent-creator.ps1` |
| agent_template | meta | skeleton per nuovi agent | `sample:echo` | `scripts/agent-template.ps1` |
| agent_retrieval | control-plane | indicizzazione RAG e retrieval bundles | `rag:export-wiki-chunks` | `scripts/agent-retrieval.ps1` |
| agent_observability | control-plane | healthcheck + standard logging | `obs:healthcheck` | `scripts/agent-observability.ps1` |
| agent_infra | control-plane | terraform plan governato | `infra:terraform-plan` | `scripts/agent-infra.ps1` |
| agent_backend | portal | implementazione API + OpenAPI | `api:openapi-validate` | `scripts/agent-backend.ps1` |
| agent_release | control-plane | runtime bundle (copia parziale) | `runtime:bundle` | `scripts/agent-release.ps1` |
| **agent_synapse** 🧪 | analytics | [EXPERIMENTAL] workspace Synapse/DataFactory + PySpark | `synapse:scaffold`, `synapse:check-sql` | `scripts/agent-synapse.ps1` |

## Pattern canonico (RAG-ready)
Per ridurre ambiguita' e rendere la knowledge “consumabile” da n8n/LLM:
- Un solo entrypoint: `orchestrator.n8n.dispatch`
- Un solo contratto: `intent-contract.md`
- Un solo log: `agents/logs/events.jsonl`
- Doc canonica + KB sempre aggiornate quando cambia un intent/azione

## Agenti “mancanti” (consigliati)
Quelli che tipicamente servono in un mondo enterprise per chiudere i loop (security/RAG/observability/IaC):

## Agenti completati (erano nella roadmap, ora attivi)
Gli agenti qui sotto erano nella lista "mancanti" e sono stati implementati con successo:
- ✅ `agent_security`: lifecycle segreti/identity/permessi (Key Vault + RBAC/ACL + rotazione + audit).
- ✅ `agent_retrieval`: indicizzazione Wiki/KB, retrieval bundles, sync verso vector store, anti-duplicati/canonical.
- ✅ `agent_observability`: OTel/AppInsights, alerting, dashboard health e troubleshooting standard.
- ✅ `agent_infra`: Terraform/IaC plan/apply governati (con WhatIf + approvazioni).
- ✅ `agent_backend`: owner implementazione API (OpenAPI + middleware auth/tenant + patterns) distinto dal triage (`agent_api`).
- ✅ `agent_docs_sync` (2026-01): sincronizzazione automatica documentazione (Wiki↔KB↔Manifest↔Code).
- ✅ `agent_synapse` (2026-01, experimental): integrazione Azure Synapse per analytics/DW avanzati.

## Note
- Questo registro e' “canonico” per RAG e onboarding; la verita' operativa resta nei manifest.


## Vedi anche

- [Segregation Model (Dev vs Knowledge vs Runtime)](./segregation-model-dev-knowledge-runtime.md)
- [Roadmap agent (retrieval, observability, infra, backend, release)](./agents-missing-roadmap.md)
- [Control Plane - Panoramica](./index.md)
- [Multi‑Agent & Governance – EasyWay](../agents-governance.md)
- [Agents Manifest Audit (gap list)](./agents-manifest-audit.md)



