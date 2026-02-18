---
title: "Agent Evolution Roadmap — L1 → L2 → L3"
created: 2026-02-17
updated: 2026-02-17
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

**Current L2 agents (9)**: agent_backend, agent_dba, agent_docs_sync, agent_governance, agent_infra, agent_pr_manager, agent_review, agent_security, agent_vulnerability_scanner.

**Known limitation**: Single-pass generation means output quality depends entirely on the first attempt. No retry mechanism for quality improvement.

---

### Level 3 — Self-Improving Agent (TARGET)

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

## Current Gap Analysis (as of 2026-02-17)

### Gap 1 — Evaluator-Optimizer (CRITICAL)

**What**: After generating output, a second LLM call evaluates the output against explicit AC predicates and provides structured feedback if criteria are not met. Generator retries with feedback.

**Why missing**: `Invoke-LLMWithRAG` supports single-pass only. No evaluator role implemented.

**Implementation plan**:
```
Invoke-LLMWithRAG -EvaluatorMode
  Step 1: Generator call (existing)
  Step 2: Evaluator call with:
    - Original query
    - Generator output
    - AC predicates from agent's PRD
    - Role: "Evaluate this output. For each failing criterion, provide specific feedback."
  Step 3: If any blocking AC fails AND iteration < MaxIterations:
    - Retry generator with evaluator feedback appended
  Step 4: Return best output (last iteration or first if all pass)
```

**Files to modify**: `agents/skills/retrieval/Invoke-LLMWithRAG.ps1`
**Estimated effort**: Medium (2-3 hours)
**Priority**: HIGH — impacts all 9 L2 agents immediately upon implementation

---

### Gap 2 — Working Memory (MEDIUM)

**What**: A `session.json` file created at task start and deleted at task end. Stores intermediate results, completed steps, and context for multi-step workflows within a single agent run.

**Why missing**: Currently each LLM call is stateless. Multi-step tasks must pass all context in every call (token-inefficient) or lose intermediate state.

**Schema proposal**:
```json
{
  "session_id": "uuid",
  "agent_id": "agent_review",
  "started_at": "2026-02-17T10:00:00Z",
  "intent": "review:docs-impact",
  "steps_completed": ["fetch_changed_files", "analyze_docs"],
  "intermediate_results": {
    "changed_files": ["portal-api/routes/health.js"],
    "missing_wiki_pages": ["guides/health-endpoint.md"]
  },
  "current_step": "generate_verdict",
  "expires_at": "2026-02-17T10:30:00Z"
}
```

**Files to create**: `agents/core/schemas/session.schema.json`
**Files to modify**: `agents/skills/retrieval/Invoke-LLMWithRAG.ps1`
**Priority**: MEDIUM — enables multi-step tasks without token bloat

---

### Gap 3 — Parallelization (MEDIUM)

**What**: Run independent subtasks concurrently using PowerShell background jobs or `Start-ThreadJob`.

**Why missing**: All agent calls are sequential. Example: `agent_review` analyzing docs and `agent_security` scanning code could run in parallel for the same PR.

**Use cases**:
- Multi-scanner: run docker-scout + trivy simultaneously, merge findings
- Multi-agent: `agent_review` + `agent_security` in parallel for PR gates
- Voting: run `analysis.classify-intent` multiple times, take majority vote

**Implementation path**: Add `$Parallel` switch to orchestrator or n8n workflow. Use `Start-ThreadJob` in PowerShell 7+.
**Priority**: MEDIUM — mainly benefits pipeline throughput, not individual agent quality

---

### Gap 4 — Confidence Scoring (LOW-MEDIUM)

**What**: Every L2 agent output includes `confidence: 0.0–1.0`. Below threshold (default 0.7) → flag for human review in `events.jsonl`.

**Why missing**: Confidence is not currently part of the `action-result.schema.json` standard output shape.

**Implementation plan**:
1. Add `confidence` field to `action-result.schema.json`
2. Add confidence scoring instruction to `secure-system-prompt.txt`
3. Add `min_confidence_for_auto_approve` to each agent's Agentic PRD
4. Orchestrator checks confidence before routing to next step

**Priority**: LOW-MEDIUM — improves observability and human-in-the-loop quality

---

### Gap 5 — Fixture Tests per Agent (LOW)

**What**: At least 3 test fixtures per L2 agent: happy path, injection attempt, edge case. Validated against AC predicates.

**Why missing**: No test infrastructure for LLM-based agents currently exists.

**Proposed location**: `agents/{agent_id}/tests/fixtures/`
```
agent_review/tests/fixtures/
  ex-01-happy-path.json       (input + expected_output)
  ex-02-injection.json
  ex-03-empty-input.json
```

**Validation script**: `agents/core/tools/Invoke-AgentFixtureTest.ps1`
**Priority**: LOW — important for reliability but not blocking current operations

---

### Gap 6 — `returns` Field in registry.json (LOW)

**What**: Every skill in registry.json should declare what it returns (`Success`, `Error`, key output fields).

**Why missing**: Registry v2.5.0 has `security` block but no `returns` field.

**Impact**: Agents cannot validate tool output programmatically. Orchestrator cannot route based on output shape.

**Target**: registry v2.6.0
**Priority**: LOW — useful for L3 AC validation

---

## Implementation Roadmap

### Phase 1 — Q1 2026 (Now → March)

| Item | Gap | Effort | Owner |
|------|-----|--------|-------|
| Evaluator-Optimizer in `Invoke-LLMWithRAG` | Gap 1 | Medium | team-platform |
| Confidence scoring in output schema | Gap 4 | Low | team-platform |
| `returns` field in registry | Gap 6 | Low | team-platform |

### Phase 2 — Q2 2026

| Item | Gap | Effort | Owner |
|------|-----|--------|-------|
| Working memory (`session.json`) | Gap 2 | Medium | team-platform |
| Fixture tests for top 4 L2 agents | Gap 5 | Medium | team-platform |

### Phase 3 — Q3 2026

| Item | Gap | Effort | Owner |
|------|-----|--------|-------|
| Parallelization (multi-scanner) | Gap 3 | High | team-platform |
| First L3 agent promotion (`agent_review`) | — | High | team-platform |
| Agentic PRD for all 9 L2 agents | — | Medium | team-platform |

---

## L3 Target Agent: agent_review

`agent_review` is the best candidate for the first L3 promotion because:
1. It already uses LLM + RAG (L2 baseline)
2. Review quality is measurable against explicit AC predicates
3. "Approve vs. Request Changes" is a high-stakes decision worth iterative refinement
4. The Evaluator-Optimizer pattern maps naturally to "review the review"

**L3 target behavior**:
```
Input: PR diff + changed files
→ Generator: "Analyze this PR" → draft review
→ Evaluator: "Does this review meet AC-01 through AC-05?"
  → AC-02 fail: verdict is null → feedback: "verdict must be one of APPROVE|REQUEST_CHANGES|NEEDS_DISCUSSION"
  → Retry: generator adds verdict
→ Evaluator: all ACs pass → return final review
```

---

## References

- [[agents/agent-design-standards]] — Workflow patterns (especially Evaluator-Optimizer)
- [[agents/agentic-prd-template]] — PRD format required for L3 promotion
- [[agents-governance]] — Gate requirements for promotion approval
- `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` — Bridge skill to extend for L3
- `agents/core/schemas/action-result.schema.json` — Output schema (add `confidence`)
- `agents/skills/registry.json` — Skill catalog (add `returns` field)
