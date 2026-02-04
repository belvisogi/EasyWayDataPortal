---
type: standard
status: active
tags:
  - layer/architecture
  - domain/ai
  - domain/agents
version: 1.0.0
created: 2026-02-04
---

# Agent Architecture Standard - Hybrid Agent Pattern

## Overview

This standard defines the **Hybrid Agent Pattern** - a modular architecture for building intelligent agents that can handle multiple interaction modes (RAG, TOOL, CHAT, WORKFLOW).

**Status**: ✅ Validated in DQF Agent V2  
**Adoption**: Recommended for all new agents

## Core Principles

> **"Il modello genera testo. L'agente genera intelligenza."**

Intelligence comes from the **system around the model**, not the model itself:
- **Interpreter**: Understands user intent
- **Memory Manager**: Maintains context and learns
- **Router**: Makes intelligent decisions
- **Observability**: Enables continuous improvement

## Architecture Components

### 1. Interpreter Module

**Purpose**: Parse user input into structured intent.

**Responsibilities**:
- Detect language (IT/EN)
- Correct typos
- Classify intent type
- Extract constraints

**Interface**:
```typescript
interface IntentObject {
    intent_type: 'validate' | 'analyze' | 'fix' | 'link' | 'chat';
    language: 'it' | 'en';
    constraints: Record<string, any>;
    clean_message: string;
    original_message: string;
}
```

**Reference Implementation**: [`packages/dqf-agent/src/core/interpreter.ts`](file:///c:/old/EasyWayDataPortal/packages/dqf-agent/src/core/interpreter.ts)

---

### 2. Memory Manager

**Purpose**: Persist conversation history and user preferences.

**Storage**: SQLite database with three tables:
- `conversations`: Short-term memory (recent turns)
- `preferences`: Long-term memory (user settings)
- `events`: Observability log (for tuning)

**API**:
```typescript
class MemoryManager {
    saveConversationTurn(turn: ConversationTurn): number
    loadShortTermMemory(sessionId: string, limit: number): ConversationTurn[]
    savePreference(key: string, value: string): void
    loadPreference(key: string): string | null
    logEvent(event: EventLog): number
}
```

**Reference Implementation**: [`packages/dqf-agent/src/core/memory-manager.ts`](file:///c:/old/EasyWayDataPortal/packages/dqf-agent/src/core/memory-manager.ts)

---

### 3. Router Module

**Purpose**: Decide how to respond based on intent and context.

**Decision Modes**:
- **RAG**: Document-based responses (grounded in knowledge base)
- **TOOL**: Action execution (validate, fix, update)
- **CHAT**: Pure conversation (no specific action)
- **WORKFLOW**: Multi-step processes

**Decision Logic**:
```typescript
interface RouteDecision {
    mode: 'RAG' | 'TOOL' | 'CHAT' | 'WORKFLOW';
    confidence: number; // 0-1
    reasoning: string;
    metadata?: Record<string, any>;
}
```

**Routing Rules**:
1. Explicit intent types → Direct mapping (`validate` → TOOL)
2. Document keywords → RAG (`"secondo i documenti..."`)
3. Action keywords → TOOL (`"correggi..."`, `"aggiorna..."`)
4. Workflow keywords → WORKFLOW (`"prima..., poi..., infine..."`)
5. Default → CHAT

**Reference Implementation**: [`packages/dqf-agent/src/core/router.ts`](file:///c:/old/EasyWayDataPortal/packages/dqf-agent/src/core/router.ts)

---

### 4. Prompt Engineering (Recommended)

**Structure**: Separate System, Policy, and User prompts.

```typescript
const SYSTEM_PROMPT = `
You are a [ROLE] for the EasyWay system.
Language: [IT/EN based on user preference]
Output: [JSON/Text based on task]
`;

const POLICY_PROMPT = `
GUARDRAILS:
1. Never invent information
2. Ask for clarification if uncertain
3. Follow taxonomy strictly
`;

const USER_PROMPT = buildUserPrompt(intent, context);
```

---

### 5. Observability (Recommended)

**Purpose**: Enable continuous improvement without retraining.

**Metrics to Track**:
- Input/output pairs
- Routing decisions and confidence
- Latency per component
- User feedback (👍/👎)

**Improvement Cycle**:
1. Log all interactions
2. Collect feedback
3. Analyze errors
4. Tune prompts/router/memory
5. Repeat

---

## Implementation Checklist

When creating a new agent following this standard:

### Phase 1: Core Components
- [ ] Implement Interpreter with domain-specific intents
- [ ] Set up Memory Manager with SQLite
- [ ] Create Router with domain-specific routing rules
- [ ] Write unit tests for each component (>80% coverage)

### Phase 2: Integration
- [ ] Create CLI that orchestrates all components
- [ ] Add PowerShell wrapper for easy invocation
- [ ] Test end-to-end with real data

### Phase 3: Observability
- [ ] Add event logging
- [ ] Implement feedback collection
- [ ] Create improvement dashboard

### Phase 4: Documentation
- [ ] Document intent types and examples
- [ ] Document routing rules
- [ ] Create usage guide
- [ ] Add to agent roster

---

## Reference Implementation: DQF Agent V2

**Location**: [`packages/dqf-agent/`](file:///c:/old/EasyWayDataPortal/packages/dqf-agent/)

**Components**:
- ✅ Interpreter (6/6 tests passed)
- ✅ Memory Manager (5/5 tests passed)
- ✅ Router (7/7 tests passed)
- ✅ CLI Integration
- ⏳ Observability (planned)

**Usage**:
```powershell
scripts/pwsh/dqf-agent-v2.ps1 "Valida i file nella cartella agents"
scripts/pwsh/dqf-agent-v2.ps1 "Cosa dice la documentazione sui tag?"
```

**Validation Status**: 🧪 In testing (Week 1 of validation phase)

---

## Migration Path for Existing Agents

### Step 1: Assessment
Evaluate if agent would benefit from Hybrid pattern:
- ✅ Handles multiple types of requests
- ✅ Needs conversation context
- ✅ Requires intelligent routing
- ❌ Simple single-purpose tool (keep simple)

### Step 2: Extraction
Once DQF Agent V2 validation completes:
1. Extract core components to `@easyway/agent-core` package
2. Publish to internal npm registry
3. Update agent template

### Step 3: Pilot Migration
Migrate 1-2 agents as pilots:
- **Easy**: Agent Docs Review
- **Medium**: Agent Governance

### Step 4: Gradual Rollout
Migrate remaining agents based on priority and complexity.

---

## Standards Compliance

All agents using this pattern MUST:
- ✅ Use `@easyway/agent-core` (once extracted)
- ✅ Implement all 3 core components (Interpreter, Memory, Router)
- ✅ Follow naming conventions (`intent_type`, `RouteDecision`)
- ✅ Write unit tests for each component
- ✅ Document intent types and routing rules

---

## Related Standards

- [[agent-portability-standard]] - LLM model selection
- [[agent-workflow-standard]] - Multi-step processes
- [[tag-taxonomy]] - Metadata standards

---

## Changelog

### v1.0.0 (2026-02-04)
- Initial standard based on DQF Agent V2 implementation
- Defined Interpreter, Memory Manager, Router interfaces
- Established validation and migration path
