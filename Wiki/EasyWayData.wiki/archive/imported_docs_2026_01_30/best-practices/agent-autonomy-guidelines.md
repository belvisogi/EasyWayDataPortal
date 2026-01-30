# Guidelines: Agent Autonomy Levels (Autopilot vs n8n)

> "Control is not about stopping the Agent. It's about knowing *who* creates the safety net."

This document defines when to let an Agent act autonomously ("Full Auto") and when to route through a deterministic orchestrator (n8n).

## The 3 Levels of Autonomy

### Level 1: Full Autopilot (Direct Action) 🟢
**Definition**: The Agent decides and executes immediately via `ewctl`.
**Use Case**: Low risk, reversible, or read-only operations.

*   **Criteria**:
    *   ✅ Operation is Read-Only (`ewctl check`, `ewctl plan`).
    *   ✅ Operation affects only Documentation/Wiki.
    *   ✅ Operation is local (e.g., standardizing file names).
    *   ✅ No Production DB impact.
*   **Flow**: User -> Agent -> `ewctl fix` -> Done.

### Level 2: Controlled Flight (n8n Assisted) 🟡
**Definition**: The Agent *proposes* an action, but **n8n** executes it after validation/approval.
**Use Case**: Medium risk, requires audit trail, or complex multi-step logic.

*   **Criteria**:
    *   ⚠️ Database Schema Changes (Drift Fix).
    *   ⚠️ User Provisioning (IAM).
    *   ⚠️ Operations requiring specialized credentials (that the Agent doesn't have).
    *   ⚠️ Need for structured Audit Log (who approved what?).
*   **Flow**: 
    1.  User -> Agent -> "I draft a request to n8n".
    2.  n8n -> **Approval Gate** (Teams/Slack).
    3.  Human -> Click "Approve".
    4.  n8n -> `ewctl fix`.

### Level 3: Manual Takeover (Human-in-the-Loop) 🔴
**Definition**: The user grabs the stick. The Agent only advises.
**Use Case**: Critical failures, "Unknown Unknowns", or creative refactoring.

*   **Criteria**:
    *   ⛔ Production Outages.
    *   ⛔ Identifying logical bugs in business rules (that `ewctl` can't see).
    *   ⛔ Security Incidents.
*   **Flow**: Agent -> "I recommend running this plan manually" -> User runs CLI.

## Decision Matrix

| Scenario | Risk | Reversible? | Recommended Mode |
| :--- | :--- | :--- | :--- |
| **Wiki Typos / Formatting** | Low | Yes | 🟢 **Full Autopilot** |
| **DB Drift (Add Column)** | Med | No (easily) | 🟡 **n8n Controlled** |
| **DB User Creation** | High | Yes | 🟡 **n8n Controlled** |
| **Fixing Broken CI Pipeline** | Med | Variable | 🟢 **Full Auto** (if local) |
| **Mass Data Deletion** | Critical | No | 🔴 **Manual** |

## Implementation
- **Full Auto**: Agent calls `ewctl fix --json`.
- **n8n Controlled**: Agent calls `POST webhook/n8n/dispatch` with `{ "intent": "db.fix", "params": ... }`.
