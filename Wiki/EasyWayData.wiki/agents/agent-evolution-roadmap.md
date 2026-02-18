---
title: "Agent Evolution Roadmap — L1 → L2 → L3"
created: 2026-02-17
updated: 2026-02-18
status: active
category: standards
domain: agents
tags: [agents, roadmap, evolution, level2, level3, evaluator-optimizer, working-memory, parallelization]
priority: high
audience:
  - agent-developers
  - team-platform
  - system-architects
id: ew-agents-agent-evolution-roadmap
summary: >
  Defines the EasyWay agent evolution levels (L1, L2, L3), promotion criteria,
  current gaps, and implementation roadmap. Includes the Evaluator-Optimizer pattern,
  working memory, parallelization, and confidence scoring as L3 targets.
owner: team-platform
related:
  - [[agents/agent-design-standards]]
  - [[agents/agentic-prd-template]]
  - [[agents/agent-system-architecture-overview]]
  - [[agents-governance]]
llm:
  include: true
  pii: none
  chunk_hint: 300-450
  redaction: []
type: roadmap
---

# Agent Evolution Roadmap — L1 → L2 → L3

> **Evolution is earned, not assumed.** An agent is promoted to a higher level only when the simpler approach demonstrably fails to meet quality targets.

---

## Level Definitions

### Level 1 — Scripted Agent

**Definition**: Deterministic, rule-based execution. No LLM calls at runtime. Output is predictable from input alone.

**Characteristics**:
- PowerShell scripts with fixed logic
- Uses skills from registry (Invoke-* functions)
- No ambiguity tolerance — input must match expected format exactly
- Fast, cheap, fully auditable

**When to use**: Tasks with fully deterministic outcomes (file checks, git operations, schema validation, health checks).

**Current L1 agents (23)**: agent_ado_userstory, agent_ams, agent_api, agent_audit, agent_cartographer, agent_chronicler, agent_creator, agent_datalake, agent_developer, agent_docs_review, agent_dq_blueprint, agent_frontend, agent_gedi, agent_observability, agent_release, agent_retrieval, agent_scrummaster, agent_second_brain, agent_synapse, agent_template, and others.

---

### Level 2 — LLM-Augmented Agent (CURRENT)

**Definition**: Uses DeepSeek LLM + Qdrant RAG to handle ambiguous inputs, produce analytical judgments, and generate structured plans.

**Characteristics**:
- Calls `Invoke-LLMWithRAG` with `-SecureMode`
- System prompt in `PROMPTS.md` with Security Guardrails block
- RAG context from `easyway_wiki` collection
- Structured JSON output (validated against `action-result.schema.json`)
- Episodic memory (`events.jsonl`)
- Single-pass: generates output once, no self-evaluation

**When to use**: Tasks requiring judgment, natural language understanding, impact analysis, or knowledge synthesis.

**Current L2 agents (8)**: agent_backend, agent_dba, agent_docs_sync, agent_governance, agent_infra, agent_pr_manager, agent_security, agent_vulnerability_scanner.
> **Note**: `agent_review` promosso a L3 in Session 9 (febbraio 2026). Vedere sezione L3.

**Known limitation**: Single-pass generation means output quality depends entirely on the first attempt. No retry mechanism for quality improvement.

---

### Level 3 — Self-Improving Agent (IMPLEMENTED — Session 9)

**Definition**: Combines L2 capabilities with self-evaluation, working memory, and optionally parallelization. Can iteratively improve output quality before returning.

**Characteristics**:
- **Evaluator-Optimizer loop**: generates output → evaluates against AC predicates → retries with feedback (max 2 iterations)
- **Working memory** (`memory/session.json`): maintains task state across multi-step workflows within a single session
- **Confidence scoring**: every decision includes `confidence` (0.0–1.0); below threshold → flag for human review
- **Parallelization** (optional): independent subtasks run concurrently
- **Full AC validation**: acceptance criteria from the Agentic PRD validated programmatically before returning output

**When to use**: High-stakes decisions (production deployments, security audits, database migrations) where first-pass quality is insufficient.

---

## Promotion Criteria

### L1 → L2 Promotion

An agent should be promoted from L1 to L2 when:

| Criterion | Check |
|-----------|-------|
| Deterministic logic fails | Agent produces wrong outputs for valid edge-case inputs |
| Ambiguity tolerance needed | Inputs vary enough that rule-based logic requires constant maintenance |
| Knowledge synthesis needed | Output requires combining multiple sources beyond what static scripts handle |
| Quality target not met | L1 output consistently below quality threshold despite script improvements |

**Promotion requires**:
- [ ] Agentic PRD written and approved by `agent_governance`
- [ ] PROMPTS.md created with Security Guardrails block
- [ ] At least 3 acceptance criteria defined (including AC-01 schema, AC-02 status, AC-03 no-credentials)
- [ ] At least 2 input/output examples in PRD
- [ ] `manifest.json` updated with `evolution_level: 2` and `llm_config`
- [ ] Added to `retrieval.llm-with-rag` allowed_callers in registry.json

### L2 → L3 Promotion

An agent should be promoted from L2 to L3 when:

| Criterion | Check |
|-----------|-------|
| Quality issues | Single-pass output fails AC predicates more than 20% of the time |
| Multi-step tasks | Agent needs to track state across multiple subtasks in a single session |
| Parallel efficiency | Agent spends >40% of time waiting for sequential calls that could be parallel |
| Confidence too low | Agent outputs `confidence < 0.7` more than 30% of the time without self-correction |

**Promotion requires**:
- [ ] Evaluator-Optimizer implemented in `Invoke-LLMWithRAG` (see gap below)
- [ ] Working memory schema defined in `memory/session.schema.json`
- [ ] PRD updated to version 2.x with L3 ACs
- [ ] Baseline metrics collected (current quality rate, average confidence)
- [ ] `agent_governance` approval

---

## Current Gap Analysis (as of 2026-02-18)

### Gap 1 — Evaluator-Optimizer ✅ DONE (Session 5)

**What**: After generating output, a second LLM call evaluates the output against explicit AC predicates and provides structured feedback if criteria are not met. Generator retries with feedback.

**Implementation**:
- `-EnableEvaluator -AcceptanceCriteria @(...)` parametri in `Invoke-LLMWithRAG`
- Loop: generator → evaluator scoring → retry con feedback (max `-MaxIterations`, default 2)
- Graceful degradation: se evaluator fallisce, ritorna output generator senza bloccare

**Files modified**: `agents/skills/retrieval/Invoke-LLMWithRAG.ps1`
**Status**: **DONE (Session 5)**

---

### Gap 2 — Working Memory ✅ DONE (Session 7)

**What**: Un file `session.json` creato all'avvio del task e rimosso alla fine. Conserva risultati intermedi, step completati e contesto per workflow multi-step.

**Implementation**:
- Schema: `agents/core/schemas/session.schema.json`
- CRUD skill: `agents/skills/session/Manage-AgentSession.ps1` (New/Get/Update/SetStep/Close/Cleanup)
- Integrazione: `-SessionFile` in `Invoke-LLMWithRAG` inietta `[SESSION_CONTEXT_START]...[SESSION_CONTEXT_END]` nel system prompt

**Status**: **DONE (Session 7)**

---

### Gap 3 — Parallelization ✅ DONE (Session 10)

**What**: Eseguire subtask indipendenti in parallelo con `Start-ThreadJob` (PS7) / `Start-Job` (PS5.1 fallback).

**Implementation**:
- Nuova skill: `agents/skills/orchestration/Invoke-ParallelAgents.ps1`
- Registry: `orchestration.parallel-agents` v1.0.0 in `agents/skills/registry.json` v2.8.0
- Parametri: `-AgentJobs`, `-GlobalTimeout`, `-FailFast`, `-SecureMode`
- Use case principale: `agent_review` + `agent_security` in parallelo su stessa PR

**Use cases**:
- Multi-scanner: docker-scout + trivy in simultanea, merge findings
- Multi-agent: `agent_review` + `agent_security` in parallelo per PR gates
- Voting: `analysis.classify-intent` multipli, majority vote

**Status**: **DONE (Session 10)**

---

### Gap 4 — Confidence Scoring ✅ DONE (Session 6)

**What**: Ogni output L2 include `confidence: 0.0-1.0`. Sotto soglia (default 0.7) → flagging per human review.

**Implementation**:
- Campo `confidence` aggiunto a `agents/core/schemas/action-result.schema.json`
- Tracking confidence in sessioni working memory (`session.schema.json`)

**Status**: **DONE (Session 6)**

---

### Gap 5 — Fixture Tests per Agent ✅ DONE (Session 6)

**What**: Almeno 3 test fixture per agente L2: happy path, injection attempt, edge case.

**Implementation**:
- 3 fixture in `agents/agent_review/tests/fixtures/`:
  - `ex-01-happy-path.json` — PR completa con codice + wiki → APPROVE
  - `ex-02-injection.json` — tentativo injection → SECURITY_VIOLATION
  - `ex-03-missing-docs.json` — codice senza wiki → REQUEST_CHANGES

**Status**: **DONE (Session 6)** — implementato per agent_review (primo candidato L3)

---

### Gap 6 — `returns` Field in registry.json ✅ DONE (Session 6)

**What**: Ogni skill in registry.json dichiara cosa ritorna (`Success`, campi output chiave).

**Implementation**:
- Campo `returns` aggiunto a tutte le 23 skill in `agents/skills/registry.json` v2.7.0
- Permette validazione programmatica dell'output e routing basato su shape

**Status**: **DONE (Session 6)**

---

## Implementation Roadmap

### Phase 1 — Q1 2026 ✅ COMPLETATA

| Item | Gap | Effort | Stato |
|------|-----|--------|-------|
| Evaluator-Optimizer in `Invoke-LLMWithRAG` | Gap 1 | Medium | ✅ DONE (Session 5) |
| Confidence scoring in output schema | Gap 4 | Low | ✅ DONE (Session 6) |
| `returns` field in registry | Gap 6 | Low | ✅ DONE (Session 6) |

### Phase 2 — Q2 2026 ✅ COMPLETATA (anticipata)

| Item | Gap | Effort | Stato |
|------|-----|--------|-------|
| Working memory (`session.json`) | Gap 2 | Medium | ✅ DONE (Session 7) |
| Fixture tests per agent_review L3 | Gap 5 | Medium | ✅ DONE (Session 6) |

### Phase 3 — Q3 2026 ✅ COMPLETATA (anticipata)

| Item | Gap | Effort | Stato |
|------|-----|--------|-------|
| Parallelization (multi-scanner) | Gap 3 | High | ✅ DONE (Session 10) — `Invoke-ParallelAgents.ps1` |
| First L3 agent promotion (`agent_review`) | — | High | ✅ DONE (Session 9) — v3.0.0, E2E tested |
| Agentic PRD per agenti L2 | — | Medium | In progress (agent_review PRD completa) |

---

## L3 Implementation: agent_review ✅ DONE (Session 9)

`agent_review` e' stato il primo agente promosso a L3. Motivi della scelta:
1. Baseline L2 solida (LLM + RAG)
2. Qualita' review misurabile contro AC predicati espliciti
3. "Approve vs. Request Changes" e' una decisione ad alto rischio che giustifica la raffinazione iterativa
4. Il pattern Evaluator-Optimizer si mappa naturalmente su "review the review"

**Risultati reali (E2E test Session 9 + Session 10)**:
```
EvaluatorEnabled:    True
EvaluatorIterations: 2          (loop eseguito 2 volte)
RAGChunks:           5          (5 chunk Qdrant recuperati)
CostUSD:             $0.001153  (deepseek-chat)
DurationSec:         40.43s
SUCCESS:             True
```

**Componenti implementati**:
- `agents/agent_review/Invoke-AgentReview.ps1` — runner L3 (rinominato da `run-with-rag.ps1` in Session 10)
- `agents/agent_review/manifest.json` v3.0.0 — `evolution_level: 3`, `evaluator: true`, `working_memory: true`
- `agents/agent_review/tests/fixtures/` — 3 fixture (happy path, injection, missing docs)
- **Acceptance Criteria**:
  - `review:docs-impact`: 4 predicati (verdict, docs analysis, file coverage, recommendations)
  - `review:static`: 4 predicati (naming, structure, specific findings, standard reference)

---

## References

- [[agents/agent-design-standards]] — Workflow patterns (especially Evaluator-Optimizer)
- [[agents/agentic-prd-template]] — PRD format required for L3 promotion
- [[agents-governance]] — Gate requirements for promotion approval
- `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` — Bridge LLM+RAG (Gap 1 Evaluator, Gap 2 Working Memory)
- `agents/core/schemas/action-result.schema.json` — Output schema con `confidence` (Gap 4)
- `agents/core/schemas/session.schema.json` — Working memory schema (Gap 2)
- `agents/skills/session/Manage-AgentSession.ps1` — CRUD skill working memory (Gap 2)
- `agents/skills/registry.json` v2.8.0 — 24 skill con `returns` field (Gap 6) + `orchestration.parallel-agents` (Gap 3)
- `agents/skills/orchestration/Invoke-ParallelAgents.ps1` — Multi-agent parallel runner (Gap 3, Session 10)
- `agents/agent_review/Invoke-AgentReview.ps1` — Runner L3 agent_review (rinominato Session 10)
- `agents/agent_review/tests/fixtures/` — 3 fixture JSON (Gap 5)
