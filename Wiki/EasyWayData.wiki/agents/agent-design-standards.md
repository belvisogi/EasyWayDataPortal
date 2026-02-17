---
title: "Agent Design Standards — EasyWay Platform"
created: 2026-02-17
updated: 2026-02-17
status: active
category: standards
domain: agents
tags: [agents, design-patterns, architecture, best-practices, agentic, anthropic, workflow]
priority: critical
audience:
  - agent-developers
  - system-architects
  - team-platform
id: ew-agents-agent-design-standards
summary: >
  EasyWay agent design standards based on Anthropic's Building Effective Agents guide.
  Covers the 5 workflow patterns, tool design principles (ACI), anti-patterns to avoid,
  and the decision framework for when to add complexity.
owner: team-platform
related:
  - [[agents/agent-system-architecture-overview]]
  - [[agents/agent-evolution-roadmap]]
  - [[agents/agentic-prd-template]]
  - [[agents-governance]]
  - [[standards/agent-architecture-standard]]
llm:
  include: true
  pii: none
  chunk_hint: 300-450
  redaction: []
type: standard
---

# Agent Design Standards — EasyWay Platform

> **Core principle**: Start with the simplest solution that works. Add complexity only when it demonstrably improves outcomes. Measure before you add.

Source: Anthropic "Building Effective Agents" (2025), adapted for EasyWay architecture.

---

## 1. The Complexity Ladder — When to Escalate

Before choosing a pattern, ask: **can the task be done with a simpler approach?**

| Level | Solution | Use When |
|-------|----------|----------|
| 0 | Single prompt | One-shot task, deterministic output |
| 1 | Prompt chain | Task decomposes into fixed sequential steps |
| 2 | Routing | Input varies significantly, specialized handlers needed |
| 3 | Parallelization | Subtasks are independent and can run concurrently |
| 4 | Orchestrator-Workers | Subtasks are unpredictable, must be decided at runtime |
| 5 | Evaluator-Optimizer | Output quality requires iterative refinement |

**EasyWay mapping**: L1 agents = Level 0-2. L2 agents = Level 3-5.

---

## 2. The 5 Workflow Patterns

### 2.1 Prompt Chaining

Decompose a task into sequential steps where each LLM call processes the previous output.

**Use when**: The task has a fixed, predictable sequence of steps with clear handoffs.

**EasyWay example**: `agent_docs_sync`
1. Check metadata completeness → 2. Check cross-references → 3. Detect orphans → 4. Generate report

**Implementation note**: Each step should have a clear output schema. Pass only the relevant subset of the previous output to the next step — not the full context.

---

### 2.2 Routing

Classify the input and direct it to a specialized handler. Enables optimization per category without performance trade-offs.

**Use when**: Inputs fall into distinct categories that require different handling logic.

**EasyWay example**: `orchestrator.js` + `agent_synapse`
- Intent classified as `db:*` → route to `agent_dba`
- Intent classified as `vuln:*` → route to `agent_vulnerability_scanner`
- Intent classified as `pr:*` → route to `agent_pr_manager`

**Implementation note**: The router should output a structured classification with confidence score, not free text. Use `analysis.classify-intent` skill.

---

### 2.3 Parallelization

Run independent subtasks concurrently (sectioning) or run the same task multiple times and aggregate (voting).

**Use when**: Subtasks are independent, or when you need confidence through consensus.

**EasyWay examples**:
- **Sectioning**: `agent_review` analyzing docs + `agent_security` scanning code simultaneously for the same PR
- **Voting**: Running `agent_vulnerability_scanner` with 3 different scanners (docker-scout, snyk, trivy) and merging findings

**Implementation note**: Currently NOT implemented in EasyWay. Agents are called sequentially. This is a priority gap for L3 evolution.

---

### 2.4 Orchestrator-Workers

A central LLM (orchestrator) dynamically breaks a complex task into subtasks and delegates to specialized worker agents.

**Use when**: The full set of subtasks cannot be predicted upfront. The orchestrator decides at runtime based on intermediate results.

**EasyWay example**: `agent_synapse` (Brain) orchestrating multiple Arm agents:
1. Orchestrator receives: "Prepare release 2.1.0"
2. Decides to call: `agent_review` → `agent_dba` → `agent_pr_manager` → `agent_release`
3. Each result informs the next decision

**Implementation note**: The orchestrator must pass full context to each worker. Workers must return structured JSON — no free text. See `agent-manifest.schema.json` for the `action-result` format.

---

### 2.5 Evaluator-Optimizer ⚡ (Priority Gap)

One LLM generates a response. A second LLM evaluates it against explicit criteria. If criteria are not met, the generator gets specific feedback and retries. Loop until quality threshold is reached or max iterations hit.

**Use when**: Quality matters more than speed. Output must meet verifiable standards (JSON schema, no credentials, scope compliance, factual accuracy).

**EasyWay example** (not yet implemented):
```
Generator (agent_review) → [output] →
Evaluator (same agent, evaluator role) → [pass/fail + feedback] →
  if fail: retry with feedback (max 2 iterations)
  if pass: return final output
```

**Evaluation criteria examples**:
- Output is valid JSON matching `action-result.schema.json`
- No server IPs or credentials in output
- All checklist items addressed
- Verdict is one of: `APPROVE | REQUEST_CHANGES | NEEDS_DISCUSSION`

**Implementation path**: Add `$EvaluatorMode` flag to `Invoke-LLMWithRAG`. See [[agents/agent-evolution-roadmap]].

---

## 3. Tool Design — Agent-Computer Interface (ACI)

Anthropic treats tool definitions with the same rigor as UI/UX design. Poor tool design is a leading cause of agent failure.

### 3.1 Principles

**Clarity over brevity**: Tool descriptions must be precise enough that the agent can select the right tool without ambiguity. If two tools could be confused, add a "when NOT to use this" note.

**Poka-yoke design**: Make the wrong action hard to trigger. Examples:
- `git.push`: `ProtectedBranches` defaults to `["main","master"]` — cannot be overridden silently
- `database.migration`: `DryRun` defaults to `false` but `requires_approval: true` in registry
- `Invoke-LLMWithRAG`: `SkipRAG` is blocked when `-SecureMode` is active

**Minimize required pre-computation**: Do not ask the agent to count lines, calculate offsets, or pre-process data before calling a tool. The tool should accept high-level inputs.

**Consistent return shapes**: Every skill must return a predictable structure. See `action-result.schema.json`.

### 3.2 Required Fields per Skill (registry.json)

Every skill in `agents/skills/registry.json` MUST have:

```json
{
  "id": "domain.action",
  "name": "Invoke-VerbNoun",
  "description": "One sentence. What it does, NOT how.",
  "parameters": [...],
  "security": {
    "requires_approval": false,
    "blast_radius": "LOW|MEDIUM|HIGH|CRITICAL",
    "audit_log": true,
    "allowed_callers": ["agent_id_1", "agent_id_2"]
  },
  "returns": {
    "Success": "boolean",
    "description": "What Success=true means"
  },
  "tags": [...]
}
```

The `returns` field (currently missing) is required starting from registry v2.6.0.

### 3.3 Blast Radius Classification

| Level | Definition | Examples |
|-------|-----------|---------|
| LOW | Read-only, no external effect | RAG search, health check, classify intent |
| MEDIUM | Local state change, reversible | git checkout, sql-query (read-only exec) |
| HIGH | Remote state change, hard to reverse | git push, git merge, database migration |
| CRITICAL | Production impact, may require downtime | git server-sync with AllowHardReset, DROP operations |

---

## 4. Anti-Patterns to Avoid

### 4.1 Over-Engineering
**Problem**: Adding LLM calls for tasks that a simple script handles reliably.
**EasyWay signal**: If a Level 1 scripted agent already does the job deterministically, do not promote it to L2 just because you can.
**Rule**: Measure first. Add LLM only when deterministic logic fails or produces insufficient quality.

### 4.2 Framework Dependency
**Problem**: n8n templates becoming complex enough that they obscure what the agent actually does.
**EasyWay rule**: n8n templates are orchestration glue, not logic containers. All agent logic lives in PowerShell skills or LLM prompts — not in n8n node configurations.

### 4.3 Treating Tool Design as Secondary
**Problem**: Vague tool descriptions cause the agent to select the wrong skill or call it with wrong parameters.
**EasyWay rule**: Every new skill must pass a "would a new agent developer understand this from the description alone?" check before merging.

### 4.4 No Sandboxed Testing
**Problem**: Deploying agents to production without validating prompt behavior on known inputs.
**EasyWay rule**: Every L2 agent must have at least 3 fixture tests in `agents/{agent_id}/tests/`. See [[agents/agent-evolution-roadmap]] for the test format.

### 4.5 Ignoring Human Oversight
**Problem**: Automating decisions that should require a human sign-off.
**EasyWay rule**: Any skill with `requires_approval: true` in the registry MUST surface a confirmation request before execution. The orchestrator is responsible for enforcing this.

---

## 5. Decision Framework — Choosing a Pattern

```
Is the task fully deterministic?
  YES → Use Level 1 scripted agent (no LLM)
  NO →
    Does it have a fixed, predictable sequence?
      YES → Prompt Chaining
      NO →
        Does input vary significantly (different categories)?
          YES → Routing
          NO →
            Are subtasks independent?
              YES → Parallelization
              NO →
                Can subtasks be predicted upfront?
                  YES → Orchestrator-Workers (fixed plan)
                  NO → Orchestrator-Workers (dynamic plan)
                    Does output need quality assurance?
                      YES → add Evaluator-Optimizer on top
```

---

## 6. EasyWay-Specific Standards

### 6.1 Output Format
All L2 agent outputs MUST be structured JSON matching `action-result.schema.json`. Free-form text is only allowed inside designated fields (`summary`, `details`, `recommendations`).

### 6.2 Language
- System prompts: **English** (better LLM alignment, consistent with training data)
- Output to human users: **Italian** (as configured per agent)
- Wiki documentation: **Italian** for narrative, **English** for technical terms and code

### 6.3 Memory Usage
- **Semantic memory** (Qdrant `easyway_wiki`): always query before generating domain-specific answers
- **Episodic memory** (`logs/events.jsonl`): write after every significant action
- **Procedural memory** (`kb/recipes.jsonl`): consult for multi-step workflows
- **Working memory** (`memory/session.json`): create at task start, delete at task end (see roadmap)

### 6.4 Confidence Scoring
L2 agents SHOULD include a `confidence` field (0.0–1.0) in their output for decisions that are non-deterministic. If `confidence < 0.7`, flag for human review automatically.

---

## References

- Anthropic: Building Effective Agents (2025)
- [[agents/agent-evolution-roadmap]] — L1 → L2 → L3 promotion criteria
- [[agents/agentic-prd-template]] — How to write machine-readable agent specs
- [[standards/agent-architecture-standard]] — EasyWay manifest standard
- `agents/core/schemas/agent-manifest.schema.json` — JSON schema
- `agents/skills/registry.json` — Skill catalog v2.5.0
