# EasyWay Hybrid Core: MVP Components

**Version**: 1.0
**Date**: 2026-02-17
**Status**: Live (Level 3 - Hybrid Agent)

## 0. Executive Summary: EasyWay vs Standard
We use `pr-agent` (Standard) as our "Server-Side Brain", but EasyWay adds a "Client-Side Nervous System" (Hybrid Core).

| Feature | Standard `pr-agent` (ADO) | **EasyWay Hybrid Core** (Our Plus) |
| :--- | :---: | :--- |
| **Review & Describe** | ✅ (Server-Side) | ✅ **+ Local Preview** (`ewctl check`) |
| **Governance** | ❌ (None) | ✅ **Smart Commit** (Blocks bad commits) |
| **Security** | ❌ (None) | ✅ **Iron Dome** (Pre-scan for syntax/secrets) |
| **Domain Tools** | ❌ (Generic Code) | ✅ **Levi (DQF)**, SQL Tools, Custom Scripts |
| **Execution** | Cloud Only (CI/CD) | **Hybrid** (Local Pipeline `|` + Cloud) |
| **Parsing** | Text Only | **Structured** (JSON Output for downstream) |

## 0.1 Detailed Capabilities (Inherited vs Native)

Since we built EasyWay on top of `pr-agent` (Azure DevOps Edition), we possess **all** its standard features, plus our upgrades.

| Capability | Feature | Status (ADO) | EasyWay Boost 🚀 |
| :--- | :--- | :---: | :--- |
| **Tools** | Describe (`/describe`) | ✅ | **+ Pipeline Support** (Diff | Describe) |
| | Review (`/review`) | ✅ | **+ Local Filter** (Ignore specific files) |
| | Improve (`/improve`) | ✅ | **+ Interactive Mode** (Apply via CLI) |
| | Ask (`/ask`) | ✅ | **+ Context** (Reads local docs) |
| | Update Changelog | ✅ | **+ Smart Commit** (Guidelines check) |
| **Core** | Dynamic Context | ✅ | **+ Levi Adapter** (RAG-like retrieval) |
| | Custom Labels | ✅ | **+ Auto-Classification** (feat/fix/chore) |
| | **Edit Access** | ✅ | **+ Safety** (Iron Dome prevents breaking) |

*Note: The table above reflects the "Azure DevOps" column of the standard `pr-agent` matrix, fully active in our instance.*

---

## 1. The Kernel: `ewctl`
*   **Role**: The central Command Line Interface (CLI) and entry point for all operations.
*   **Function**: Standardizes inconsistent scripts into unified commands (e.g., `ewctl check`, `ewctl commit`).
*   **Location**: `scripts/pwsh/ewctl.ps1`

## 2. The Bridge: Hybrid Core (`Invoke-AgentTool`)
*   **Role**: The communication layer between the LLM and the Operating System.
*   **Function**: Allows the agent to execute system tools safely.
*   **Key Feature**: **Pipeline Pattern** (`Source | Invoke-AgentTool`). Uses Stdin to bypass shell parsing limits, enabling robust handling of large inputs (diffs, logs).
*   **Location**: `scripts/pwsh/Invoke-AgentTool.ps1`

## 3. The Gatekeeper: Smart Commit (`ewctl commit`)
*   **Role**: The active governance layer for changes.
*   **Function**: Wraps `git commit` to enforce quality checks *before* saving history.
*   **Checks**:
    1.  **Anti-Pattern Scan**: Blocks forbidden commands (e.g., `Invoke-AgentTool -Target ...`).
    2.  **Rapid Audit**: Verifies Agent Manifests (`agent-audit.ps1`).
    3.  **Governance Status**: Checks branch protection rules.
*   **Location**: Inside `ewctl.ps1` (Switch: `commit`)

## 4. The Shield: Iron Dome
*   **Role**: The automated robust defense system.
*   **Function**: A **Git Pre-Commit Hook** that runs automatically on every commit.
*   **Checks**:
    1.  **Syntax**: Blocks invalid PowerShell code (AST parsing).
    2.  **Linting**: Enforces style and safety via `PSScriptAnalyzer`.
*   **Location**: `.git/hooks/pre-commit` (Source: `scripts/pwsh/git-hooks/pre-commit.ps1`)

## 5. The Law: Governance Rules
*   **Role**: The constitution of the project.
*   **Function**: Instructions that bind the Agent's behavior.
*   **Components**:
    *   `.cursorrules`: Global behavioral rules (e.g., "Use Pipeline", "No direct commits").
    *   `docs/ops/authentication_standards.md`: Auth Matrix (PAT vs Interactive).
    *   `PRD`: The source of truth for features.

## 6. The Agents (Tools)
*   **Role**: Specialized workers.
*   **Examples**:
    *   **Levi (DQF)**: Data Quality Framework scanner (`scripts/node/levi-adapter.cjs`).
    *   **Governance Agent**: Audits compliance.
    *   **(Future)**: RAG Agent, SQL Agent.

## 7. The Environment: Platform Configuration (Azure DevOps)

To support the Hybrid Core, the following ADO settings are mandatory across all repositories.

### 7.1 Branch Security
| Branch | Group | Allow | Deny |
| :--- | :--- | :--- | :--- |
| `main` | **Contributors** | Read | **Push**, Force Push, Delete |
| `develop` | **Contributors** | Read, Create Branch | **Push**, Force Push, Delete |
| `feature/*` | **Contributors** | **Push**, Create Branch | Force Push (Recommended) |
| `release/*` | **Release Managers** | Push | Force Push |

### 7.2 Branch Policies (`main` & `develop`)
These policies enforce the "Gatekeeper" role directly on the server.
1.  **Minimum Reviewers**: 1 (Human or Agent).
2.  **Check for Linked Work Items**: Required (Links code to User Story).
3.  **Comment Resolution**: **All comments must be resolved**. (Critical for AI Code Reviews).
4.  **Build Validation**: Pre-merge pipeline must pass (runs `Iron Dome` + Tests).
5.  **Limit Merge Types**: Squash Merge (Recommended for clean history).
6.  **Automatic Reviewers (for Emails)**: Add "EasyWay Team" (or specific groups) as required reviewers.
    *   *Effect*: ADO sends an "Action Required" email to all members immediately upon PR creation.

---

## Architecture Diagram

```mermaid
graph TD
    User[User / Developer] -->|Commands| Kernel[ewctl]
    Kernel -->|Wraps| Git[Git System]
    
    subgraph "Hybrid Core Defense"
        Git -->|Trigger| Shield[Iron Dome (Pre-Commit)]
        Kernel -->|Trigger| Gate[Smart Commit]
    end
    
    subgraph "Agent Runtime"
        LLM[AI Agent] -->|Calls| Bridge[Invoke-AgentTool]
        Bridge -->|Pipeline Pattern| Tools[System Tools]
    end
    
    Shield -- Blocks Errors --> Git
    Gate -- Blocks Violations --> Git
    Tools -- Returns Output --> LLM
```
