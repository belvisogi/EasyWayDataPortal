# EasyWay Hybrid Core - Technical Manual

**Version**: 1.0 (MVP)
**Status**: Stable
**Location**: `C:\old\EasyWayDataPortal\agent\core`

## 1. Overview
The **EasyWay Hybrid Core** is the standard "brain" for all agentic operations within the EasyWay platform. It bridges the gap between raw scripts (PowerShell) and advanced AI logic (LLMs), ensuring consistency, safety, and "antifragility".

## 2. Architecture

### The "Polyglot" Pattern
Instead of forcing a single language, the Core uses the best tool for the job:
-   **PowerShell**: Used for local execution, diff parsing, and Git ops (Zero-dependency, fast).
-   **Python** (Optional): Used for heavy AI lifting (when available).
-   **LLM Prompts**: Centralized system prompts to ensure consistent "EasyWay" personality and rules.

### Key Components
| Component | Path | Description |
| :--- | :--- | :--- |
| **Orchestrator** | `Invoke-AgentTool.ps1` | Main entry point. Chooses the right tool for the task. |
| **Smart Diff** | `Get-SmartDiff.ps1` | Formats Git diffs with line numbers and hunk separation (`__new hunk__`). |
| **Prompts** | `prompts/*.md` | System prompts for Review, Description, and Classification. |

## 3. Usage

### For Human Developers
You generally don't run this directly. It is designed to be called by Agents (Cursor, Windsurf) or CI/CD pipelines.

### For Agents (Rules)
Agents MUST use the Core for specific tasks to ensure compliance.
**Example (in `.cursorrules`)**:
```powershell
# WRONG: "Read the git diff and tell me what changed"
# RIGHT:
Invoke-AgentTool.ps1 -Task Describe -Target (git diff)
```

## 4. Features

### A. Smart Diff
Raw Git diffs are often confusing for LLMs. The Smart Diff adds:
-   **Hunk Markers**: `__new hunk__` / `__old hunk__` to clearly separate context.
-   **Line Numbers**: Added *only* to the new lines, enabling the Agent to say "Fix line 12" accurately.

### B. Work Item Classification
The prompt logic automatically classifies changes based on branch names:
-   `feature/*` -> **PBI** (Product Backlog Item)
-   `fix/*` -> **Bug**

## 5. Maintenance
-   **Adding Prompts**: Add new markdown files to `agent/core/prompts`.
-   **Updating Logic**: Edit `Get-SmartDiff.ps1` for parsing changes.
