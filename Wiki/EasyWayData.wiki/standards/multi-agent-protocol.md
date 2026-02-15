---
type: standard
status: active
tags:
  - layer/protocol
  - domain/agentic
created: 2026-02-04
---

# 🗣️ Multi-Agent Communication Protocol

Affinché il "Consiglio degli Agenti" (Guard, Review, Release) possa collaborare, è necessario un protocollo di scambio messaggi strutturato.
Questo documento definisce lo **Schema JSON** del Context Object condiviso.

---

## 1. 📦 The Context Object

Ogni operazione CI/CD genera un `Context Object` che passa di mano in mano.

```json
{
  "context_id": "PR-123",
  "timestamp": "2026-02-04T20:00:00Z",
  "trigger": "webhook:merge_request",
  "subject": {
    "type": "merge_request",
    "id": 123,
    "source_branch": "feature/devops/PBI-001-login",
    "target_branch": "develop",
    "author": "user@example.com"
  },
  "state": {
    "guard_status": "PENDING",    // PENDING, PASS, FAIL
    "review_status": "PENDING",   // PENDING, APPROVED, CHANGES_REQUESTED
    "release_status": "PENDING"   // PENDING, MERGED, ROLLED_BACK
  },
  "gates": {
    "naming_convention": null,
    "target_policy": null,
    "doc_coverage": null,
    "pipeline_green": null
  },
  "timeline": [
    {
      "agent": "agent_guard",
      "action": "check:branch-name",
      "result": "PASS",
      "message": "Branch name complies with policy (feature/chore PBI or hotfix INC/BUG)",
      "timestamp": "2026-02-04T20:00:05Z"
    }
  ]
}
```

---

## 2. 🚦 State Transitions

### Stage 1: The Sentry (Guard)
*   **Input**: Webhook Payload -> Context Object.
*   **Check**: Branch Name + Target.
*   **Output**: Update `state.guard_status`.
    *   If `FAIL`: Close PR via API. End Workflow.
    *   If `PASS`: Trigger Review Agent.

### Stage 2: The Critic (Review)
*   **Input**: Context Object (Guard Passed).
*   **Check**: Diff Analysis + Docs.
*   **Output**: Update `state.review_status`.
    *   If `CHANGES_REQUESTED`: Post comment. Wait for update.
    *   If `APPROVED`: Label PR as `bot-approved`. Trigger Release Agent (if auto-merge eligible).

### Stage 3: The Executor (Release)
*   **Input**: Context Object (Review Approved).
*   **Check**: Pipeline Status (External CI).
*   **Output**: Update `state.release_status`.
    *   Action: Merge.

---

## 3. 💾 Persistence

Il Context Object DEVE essere persistito per audit.
*   **Location**: `AGENT_MGMT` DB -> Table `Workflow_Contexts`.
*   **Archivio**: `out/audit/PR-123.json` (come Artifact finale).

---

## 4. 🛡️ Security

*   Gli Agenti firmano digitalmente le loro entry nella `timeline` (HMAC)? (Future Scope).
*   Solo `agent_release` possiede il Token con permessi di Merge.
