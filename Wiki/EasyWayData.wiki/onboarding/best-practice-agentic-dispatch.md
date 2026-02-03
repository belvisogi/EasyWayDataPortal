---
title: Best practice - intent agentici via n8n.dispatch (RAG-ready)
tags: [best-practice, governance, orchestration, n8n, agents, rag, privacy/internal, language/it]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-best-practice-agentic-dispatch
chunk_hint: 200-300
entities: []
include: true
summary: Assessment sintetico e linea guida canonica per intent agentici governati via n8n.dispatch.
llm: 
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
pii: none
owner: team-platform
---

[Home](./start-here.md)

# Best practice - intent agentici via n8n.dispatch (RAG-ready)

## Contesto (repo)
- Entrypoint unico: `Wiki/EasyWayData.wiki/orchestrations/orchestrator-n8n.md`
- Contratto intent: `Wiki/EasyWayData.wiki/intent-contract.md`
- KB: `agents/kb/recipes.jsonl`
- Log eventi: `agents/logs/events.jsonl`
- Goals: `agents/goals.json`

## Assessment (stato attuale)
- Orchestrator n8n definito con policy di dispatch unico.
- Contratti WHAT-first in `docs/agentic/templates/intents/`.
- Manifest orchestrazioni in `docs/agentic/templates/orchestrations/`.
- Log strutturati e audit disponibili via `agents/logs/events.jsonl`.
- Template per access registry e data dictionary disponibili in `docs/agentic/templates/sheets/`.
- Pagina canonica segreti/accessi e runbook governance creati in `Wiki/EasyWayData.wiki/security/`.

## Best practice canonica
1) Definisci l'intent (WHAT) in `docs/agentic/templates/intents/`.
2) Aggiungi manifest orchestrazione (WHAT-first) se e' un nuovo workflow.
3) **Dispatch unico**: instrada sempre via `orchestrator.n8n.dispatch`.
4) Aggiorna Wiki + KB (nessun cambio senza doc e ricetta).
5) Logga eventi in `agents/logs/events.jsonl`.
6) Usa Key Vault per segreti (solo reference nel repo).
7) Mantieni l'indice agent allineato: `agents/README.md` deve riflettere `agents/*/manifest.json` (check-only nei gate; fix locale con `pwsh scripts/agents-readme-sync.ps1 -Mode fix`).
   - Human-in-the-loop: `pwsh scripts/agent-docs-review.ps1 -SyncAgentsReadme` propone il fix e lo applica solo con conferma.

## RAG readiness
- Evitare duplicati: una sola pagina canonica per ogni tema.
- Linkare sempre la pagina canonica dalle pagine secondarie.
- Tag coerenti e front-matter completo per retrieval.

## Definition of Done (agent-aware)
- Intent definito + manifest (se necessario).
- Entry via n8n.dispatch.
- Wiki + KB aggiornate.
- Gate verdi (Checklist/DB Drift/KB Consistency).
- Log eventi presenti.

## Riferimenti
- `Wiki/EasyWayData.wiki/orchestrations/orchestrator-n8n.md`
- `Wiki/EasyWayData.wiki/intent-contract.md`
- `Wiki/EasyWayData.wiki/security/segreti-e-accessi.md`
- `Wiki/EasyWayData.wiki/security/operativita-governance-provisioning-accessi.md`
- `Wiki/EasyWayData.wiki/Runbooks/index.md`
- `Wiki/EasyWayData.wiki/Runbooks/dual-server-bootstrap.md`


## Vedi anche

- [Agents Registry (owner, domini, intent)](../control-plane/agents-registry.md)
- [Orchestratore n8n (WHAT)](../orchestrations/orchestrator-n8n.md)
- [Orchestrazione - Agent Scaffold (WHAT)](../orchestrations/agent-scaffold.md)
- [Control Plane - Panoramica](../control-plane/index.md)
- [Segregation Model (Dev vs Knowledge vs Runtime)](../control-plane/segregation-model-dev-knowledge-runtime.md)





