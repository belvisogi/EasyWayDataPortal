---
id: ew-orch-agent-scaffold
title: Orchestrazione - Agent Scaffold (WHAT)
summary: Workflow WHAT-first per creare un nuovo agente (es. DBA) usando pattern canonici e contesto RAG (Azure AI Search), con dispatch unico via n8n.
status: draft
owner: team-platform
tags: [orchestration, agents, rag, azure-ai-search, governance, language/it]
updated: 2026-01-07
---

# Orchestrazione - Agent Scaffold (WHAT)

## Scopo
- Creare un nuovo agente in modo **governato**: template canonico + WHAT-first + KB/Wiki aggiornate.
- Abilitare RAG su **Azure AI Search** (retrieval in n8n) per riusare pattern già presenti nel repo.

## Entrypoint (policy)
- Tutti i nuovi intent passano da `orchestrator.n8n.dispatch`.
  - Canonico: `Wiki/EasyWayData.wiki/orchestrations/orchestrator-n8n.md`

## Contratti
- Intent: `docs/agentic/templates/intents/agent.scaffold.intent.json`
- Manifest orchestrazione: `docs/agentic/templates/orchestrations/agent-scaffold.manifest.json`
- Contratto intent globale: `Wiki/EasyWayData.wiki/intent-contract.md`
- Contratto output: `Wiki/EasyWayData.wiki/output-contract.md`

## RAG / Azure AI Search
- Scope di indicizzazione: `ai/vettorializza.yaml` (Wiki/KB/manifest sempre; scripts on-demand).
- Knowledge base vettoriale: `Wiki/EasyWayData.wiki/ai/knowledge-vettoriale-easyway.md`
- Pattern consigliato:
  1) n8n fa retrieval (hybrid) su Azure AI Search filtrando per path/tags.
  2) n8n passa un `rag_context_bundle` all'agente (no segreti, solo riferimenti).
  3) L'agente genera artefatti e propone next step (gates/PR).

## Human-in-the-loop
- WhatIf-by-default: `whatIf=true` di default.
- `whatIf=false` solo con conferma esplicita.

## Osservabilità
- Log eventi: `agents/logs/events.jsonl`
- Campi minimi diario di bordo: `timestamp, stage, outcome, reason, next, decision_trace_id, artifacts[]`.

## Esempio payload
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "agent.scaffold",
    "params": {
      "agentName": "agent_dba_rag",
      "agentRole": "Agent_DBA_RAG",
      "description": "DBA assistant RAG-ready (Azure AI Search) che propone/dispaccia azioni verso agent_dba",
      "baseTemplate": "agents/agent_template",
      "update": { "agentsReadme": true, "kb": true, "wiki": true }
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "agent-scaffold-001"
  }
}
```
