# Handoff Context: EasyWay Hybrid Core v1.1 (Execution Phase)

**Role**: You are the "Executor Agent" picking up where the "Architect Agent" left off.

## 🌍 Current State
We have successfully defined and documented the **Hybrid Core v1.1** architecture.
- **Repository**: `c:\old\EasyWayDataPortal`
- **Active Branch**: `feature/easyway-hybrid-core` (contains all governance updates).
- **Key Artifacts**:
    - `docs/PRD_EASYWAY_AGENTIC_PLATFORM.md`: The Bible. specifically sections **22.23** (PM-Dev Link), **22.24** (Gates), **22.25** (Security).
    - `.cursorrules`: The Law. Now includes the "Specialized Agent Roster".
    - `ewctl.ps1`: The Kernel. Now enforces "Smart Commits".

## 🎯 Goal: The ADO Deep Dive (Start-to-Finish)
We need to **execute** the theoretical flow we just designed, simulating a real feature lifecycle on Azure DevOps.

## 📝 Mission Tasks
1.  **Read the PRD**: Focus on Section **22.23** (Workflow: PM to Dev Handoff) and **22.24** (Testing & UAT Gates).
2.  **Scenario**: "Implement Database Observability in `agent_dba`".
3.  **Step 1: Planning (The PM)**:
    - Act as `Agent ADO UserStory`.
    - Create (or simulate) a User Story on ADO (#1002 - DB Health Check).
    - **CRITICAL**: Generate the canonical branch name (e.g., `feature/dba/1002-db-health-check`).
4.  **Step 2: Development (The Dev)**:
    - Checkout the branch.
    - Implement `dba:check-health` in `agents/agent_dba`.
    - Commit using `ewctl commit` (Legacy `git commit` is forbidden).
5.  **Step 3: Feature Gate**:
    - Verify Unit Tests + Iron Dome locally.
    - Push to `origin`.
6.  **Step 4: Pull Request**:
    - Create a PR towards `develop`.
    - Verify that the "Link Work Item" works (because of the branch name).
7.  **Step 5: UAT & Release**:
    - Simulate UAT approval.
    - Merge to `develop` -> `main`.

## ⚠️ Non-Negotiables
- **Strict Adherence**: Follow the `ewctl` and `.cursorrules` protocols as if they were hard code.
- **No Hallucinations**: If a script is missing, build it. Don't pretend it runs.
- **Evidence**: Start `walkthrough.md` for this session to log every "Check" and "Gate" passed.

**Ready to launch.** 🚀
