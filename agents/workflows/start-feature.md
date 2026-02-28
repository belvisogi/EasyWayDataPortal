---
description: Mandatory pre-flight before ANY code change on EasyWayDataPortal — see PRD §22.19
---

# Pre-Flight: Start Feature Branch

**IMPORTANT**: This workflow MUST be executed BEFORE writing any code, creating any file, or modifying any existing file in this repository. No exceptions. This is a binding rule from PRD §22.19.

## Steps

1. **Check current branch**
// turbo
```
git branch --show-current
```

2. **If on `main`, `develop`, or `baseline` — create a feature branch.** NEVER commit directly to protected branches.
   - Branch naming: `feature/<scope>-<short-description>` (e.g., `feature/p3-workflow-intelligence`)
   - Ask the user for the branch name if not obvious from context.
```
git checkout -b feature/<name>
```

3. **If already on a feature branch**, confirm with the user that it's the correct one before proceeding.

4. **Only after the branch is confirmed**, proceed with code changes.

## Verification (run at any point during work)

At the start of each new task, and before any commit, verify the branch:
// turbo
```
git branch --show-current
```

If the output is `main`, `develop`, or `baseline` — STOP immediately and create a feature branch.

## Rules
- **NEVER skip this workflow.** Even if the user says "just do it quickly".
- If the user's kickoff message says "Current Branch: develop", that means you should branch OFF develop, not work ON develop.
- After all work is done, remind the user to merge via PR.
- Violation of this rule requires a post-mortem within 24 hours (PRD §22.19).
