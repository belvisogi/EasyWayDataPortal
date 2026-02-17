# Release Workflow: Develop to Main

**Tag**: `#release` `#governance` `#agent_release`

## 1. Overview
In the EasyWay Platform, the transition from development to production is a governed process managed by the **Agent Release**.

**Flow**: `feature/*` -> `develop` -> [Release Gate] -> `main` -> `production`.

## 2. The Release Gate (PRD §18.e)
Promoting code to `main` is a **Critical Step**. It requires:
1.  **Stable Build**: `develop` must pass all CI checks.
2.  **Human Confirmation**: Explicit approval from:
    -   *Product Owner* (Value)
    -   *Tech Owner* (Code Quality/Security)

## 3. How to Release (The "Agent Way")
Do not merge manually. Use `agent_release` to ensure audit trails and safety checks.

### Step 1: Request Release
Ask the agent:
> "Agent Release, promote develop to main."

### Step 2: Agent Execution
The agent will:
1.  **Preflight**: Verify `develop` is clean and synced.
2.  **Diff Analysis**: Generate a summary of changes since last release.
3.  **Draft Release**: Create a detailed Release Note draft.
4.  **Confirm**: Pause for human confirmation (`-Yes` override available for CI).

### Step 3: Deployment
Once merged to `main`, the CI/CD pipeline deploys to the Production Environment.

## 4. Emergency Fixes (Hotfix)
**Flow**: `main` -> `hotfix/xxx` -> `main` + `develop`.
-   Hotfixes bypass the standard cycle but still require `agent_release` for safe merging back to both branches.

## 5. References
-   **Tool**: [`agents/agent_release/README.md`](../../agents/agent_release/README.md)
-   **Governance**: `PRD_EASYWAY_AGENTIC_PLATFORM.md`
