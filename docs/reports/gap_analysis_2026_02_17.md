# Gap Analysis: Current Status vs PRD Vision

**Date**: 2026-02-17
**Reference**: `Blueprint Agente LLM – Riassunto Completo.md`

## Executive Summary
We have successfully established the foundational "Kernel" (`ewctl`), the "Hybrid Core" (PowerShell + LLM bridge), and the "Governance" layer (Audit & Smart Commit).
We are currently transitioning from **Level 3 (Tool Agent/Hybrid)** to **Level 4 (Workflow Agent)**.

## Status by PRD Components

| Component | PRD Vision | Current Status | Gap / Next Steps |
| :--- | :--- | :--- | :--- |
| **Gateway/CLI** | Unified entry point (`ewctl`) | **MATURE**. `ewctl` is the kernel. Added `ewctl commit`. | None. Maintain stability. |
| **Router** | Decision engine (Chat vs Tool vs RAG) | **PARTIAL**. Hybrid Core decides between `Describe` and `Review`. | Need a global Router for generic intents (not just code tasks). |
| **Memory** | Short/Long term + Event Log | **BASIC**. Git commits act as long-term memory. No dedicated Vector DB/SQLite yet. | **HIGH**. Implement SQLite for session memory (PRD §Memory). |
| **Tools** | Registry + Safety Policy | **MATURE**. `Invoke-AgentTool` + `agent-audit` + Pipeline Pattern. | Standardize Python/Node tool adapters. |
| **RAG** | Ingestion + Retrieval | **MISSING**. We rely on context window. | **HIGH**. Implement RAG for `docs/` querying (Levi is a scanner, not a retriever). |
| **Governance** | "Untouchables" (Guardians) | **ADVANCED**. Smart Commit, Audit, and Rules are active and enforcing. | Automate "Certificate of Reliability" generation. |

## Highlights
- ✅ **Hybrid Core**: The "Pipeline Pattern" (`git diff | custom tool`) is a solid architectural pattern for large inputs.
- ✅ **Anti-Fragility**: The move to `ewctl commit` prevents regression errors before they happen.
- ⚠️ **Missing Link**: We lack a persistent "Brain" (Memory/Context) outside of the current session and Git history.

## Recommendations
1.  **Implement Memory Layer**: Start with the PRD-recommended SQLite store (`agent/memory/store.sqlite`) to track decisions across sessions.
2.  **Activate RAG**: The "Levi" agent should evolve from a scanner to a retriever, allowing us to "Ask the Docs".
