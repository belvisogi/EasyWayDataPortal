---
name: multi-agent-orchestration
description: Pattern di orchestrazione multi-agente per sistemi EasyWay. Copre Sequential, Parallel (Fan-Out), Hierarchical e Consensus. Usa quando coordini più agenti specializzati, costruisci workflow complessi, o ottimizzi throughput/qualità di task multi-step. Adattato da multi-agent-orchestration community skill per il contesto EasyWay.
source: promoted from C:\old\.agents\skills\multi-agent-orchestration — adapted for EasyWay
promoted: 2026-03-01
decision: ADAPT
---

# Multi-Agent Orchestration — EasyWay

## Pattern usati in EasyWay

### 1. Sequential Task Chain (BA → PM → PBI → SM)
Ogni agente usa l'output del precedente.
**Esempio**: `Invoke-SDLCOrchestrator.ps1` — BA brief → PM PRD → PBI ADO → Sprint Plan

### 2. Fan-Out / Synthesis (BA Phase)
Un agente analizza 4 dimensioni in parallelo (mercato, utenti, tech, business) poi sintetizza.
**Esempio**: `Get-BAPrompt` in Invoke-SDLCOrchestrator — LLM singolo con prompt strutturato Fan-Out.
**Alternativa parallela reale** (se serve più qualità): usa `Invoke-ParallelAgents.ps1`.

### 3. Hierarchical (Orchestrator → Specialists)
L'orchestratore delega a skill specializzate.
**Esempio**: `Invoke-SDLCOrchestrator.ps1` → `Convert-PrdToPbi.ps1` → `New-PbiBranch.ps1`

### 4. Tool-Mediated (Shared State via File System)
Agenti condividono stato via file: `product-brief.md` → `prd.md` → `sprint-plan.md`.
**Pattern**: ogni fase legge l'output della fase precedente come contesto.

## Quando usare ogni pattern

| Pattern | Quando | Tool EasyWay |
|---------|--------|--------------|
| Sequential | Steps con dipendenze, output → input | SDLCOrchestrator |
| Fan-Out | Analisi multi-dimensionale parallela | ParallelAgents + Synthesis |
| Hierarchical | Delegazione a specialisti | SDLCOrchestrator → skills |
| Consensus | Decisioni complesse, review | Planned (agent_review) |

## Invoke-ParallelAgents.ps1

`agents/skills/orchestration/Invoke-ParallelAgents.ps1` — skill `orchestration.parallel-agents`

Lancia N agenti in parallelo e raccoglie i risultati. Utile per:
- Research Fan-Out: 4 agenti di ricerca paralleli (mercato, competitor, utenti, tech)
- Parallel validation: multiple review agents sulla stessa PR
- Batch processing: N documenti elaborati in parallelo

## Best Practices EasyWay

- **Human-in-the-loop**: ogni fase critica ha `[A]pprova / [R]igenera / [E]dit / [Q]uit`
- **Resumable**: ogni agente scrive su file → orchestratore può riprendere da metà
- **Antifragile LLM**: DeepSeek primary → OpenRouter fallback
- **Saga log**: se un'operazione ADO fallisce parzialmente, logga cosa è stato fatto per cleanup manuale
- **Audit trail**: ogni skill ADO log le sue azioni (file creati, PBI IDs, PR URLs)

## Risorse correlate

- `agents/skills/orchestration/Invoke-ParallelAgents.ps1` — parallelizzazione pratica
- `agents/skills/planning/Invoke-SDLCOrchestrator.ps1` — esempio completo di orchestrazione sequenziale
- `Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md` — guida SDLC agentico
