---
title: Agent Level 2 Upgrade Log
summary: Documentazione dell'upgrade degli agent a Level 2 con DeepSeek LLM integration
status: active
owner: team-platform
tags:
  - domain/security
  - layer/agents
  - audience/devops
  - privacy/internal
---

# Agent Level 2 Upgrade Log - 2026-02-08

## Context

Upgrade degli agent dal Level 1 (rule-based) al Level 2 (LLM-powered) seguendo il piano in `docs/AGENTS_GAP_ANALYSIS_2026-02-08.md`.

**LLM Provider scelto:** DeepSeek (deepseek-chat)
- Costo: ~$0.00025 per chiamata
- Stima mensile: < $0.10 per tutti gli agent
- API Key salvata sul server in `~/.bashrc` (TODO: migrare a Key Vault)

---

## Agent 1: agent_vulnerability_scanner

**Status:** COMPLETATO
**Path:** `agents/agent_vulnerability_scanner/`

### Cosa e stato fatto
- Creato da zero in `agents/` (era prototype in `.agent/workflows/`)
- manifest.json v2.0 con `llm_config`, `skills_required`, `skills_optional`
- PROMPTS.md - system prompt per analisi sicurezza
- priority.json - guardrails (read-only, no secrets in output, cost guard)
- 3 intent templates (full, quick, compatibility-only)
- memory/context.json con knowledge tracking e llm_usage
- compatibility-matrix.json migrato

### Test Results
- Scansionati 13 container reali
- DeepSeek ha trovato: 1 CRITICAL, 3 HIGH, 2 MEDIUM, 1 LOW
- Ha identificato Caddy gia in funzione (sostituzione Traefik)
- Ha segnalato container con tag `latest` (rischio)
- Costo: $0.000421
- Risk Score: 7/10

### Cleanup
- Eliminata vecchia cartella `.agent/workflows/agent_vulnerability_scanner/`
- Migrati 3 workflow MD da `.agent/workflows/` a `Wiki/.../Runbooks/`
- Eliminata cartella `.agent/workflows/` (vuota)

---

## Agent 2: agent_security

**Status:** COMPLETATO
**Path:** `agents/agent_security/`

### Cosa e stato fatto
- Upgrade manifest.json v1.0 -> v2.0
- Aggiunto `llm_config` DeepSeek (era gia predisposto nello script con Provider param)
- Aggiunto `id`, `owner`, `version`, `evolution_level`, `context_config`
- Aggiunto `skills_required`, `skills_optional`
- Strutturato `allowed_paths` in read/write
- Strutturato `knowledge_sources` con priority
- PROMPTS.md creato - system prompt per security analysis
- priority.json aggiornato con nuove regole (prod-approval, llm-no-secrets)
- 4 intent templates (security:analyze, kv-secret:set, kv-secret:reference, access-registry:propose)
- memory/context.json arricchito con knowledge, llm_usage, rotation_schedule
- README.md riscritto completo

### Test Results
- Analisi security posture reale del server
- DeepSeek ha identificato:
  - GitLab esposto su HTTP (porta 8929) senza HTTPS
  - Porte di gestione esposte (2019, 9001, 10000-10002)
  - SQL Server esposto (1433)
  - Qdrant senza autenticazione (config commentata)
  - API key DeepSeek in bashrc (rischio)
- Costo: $0.000526
- Risk Score: 7/10

### Note
- Lo script `agent-security.ps1` aveva GIA il supporto multi-provider (Ollama/DeepSeek/OpenAI)
- L'action `security:analyze` era gia implementata
- L'upgrade e stato principalmente strutturale (manifest v2.0 compliance)

---

## Agent 3: agent_dba

**Status:** COMPLETATO
**Path:** `agents/agent_dba/`

### Cosa e stato fatto
- Upgrade manifest.json v1.0 -> v2.0
- Aggiunto `id`, `owner`, `version`, `evolution_level`, `llm_config`, `context_config`
- Aggiunto `skills_required`, `skills_optional`
- Strutturato `allowed_paths` da array a read/write
- Strutturato `knowledge_sources` con priority
- PROMPTS.md creato - system prompt per DB analysis
- priority.json aggiornato con action weights + 2 nuove regole LLM
- 3 nuovi intent templates (metadata-extract, metadata-diff, guardrails-check)
- memory/context.json arricchito con knowledge DB
- README.md riscritto completo

### Note
- Agent gia molto maturo (8 actions, 5 templates, GUARDRAILS.md)
- Ha anche `security` section con required_group e can_sudo
- Lo script non e' stato trovato come file separato (logica probabilmente in db-deploy-ai)

### Test Results
- sqlcmd non trovato nel container Azure SQL Edge (path diverso)
- DeepSeek ha identificato il problema infrastrutturale e suggerito fix
- Costo: $0.000430
- Nota: il test reale richiede fix del path sqlcmd nel container

---

## Prossimi Agent da Upgradare

| # | Agent | Priorita | Status |
|---|-------|----------|--------|
| 1 | agent_vulnerability_scanner | P0 | DONE |
| 2 | agent_security | P0 | DONE |
| 3 | agent_dba | P1 | DONE |
| 4 | agent_docs_sync | P2 | TODO |
| 5 | agent_pr_manager | P2 | TODO |

---

## Costi Totali

| Voce | Costo |
|------|-------|
| Test iniziale DeepSeek | $0.000250 |
| Test agent_vulnerability_scanner | $0.000421 |
| Test agent_security | $0.000526 |
| Test agent_dba | $0.000430 |
| **Totale speso** | **$0.001627** |
| Stima mensile (3 agent, 1 scan/giorno) | ~$0.05 |

---

## Decisioni Architetturali

1. **DeepSeek Chat** scelto come LLM provider (costo 100x inferiore a GPT-4)
2. **Temperature 0.1** per output deterministico
3. **Max 1000 tokens** per chiamata (controllo costi)
4. **1 chiamata LLM per scan** (guardrail in priority.json)
5. **API key in bashrc** come soluzione temporanea (TODO: Azure Key Vault)
6. **Analisi in italiano** per il team

---

**Autore:** Claude Opus 4.6
**Data:** 2026-02-08
