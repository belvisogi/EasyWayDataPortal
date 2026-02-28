---
description: How to create a Pull Request (PR) using the Agent-Assisted Link Pattern
---

# PR Creation Workflow (Agent-Assisted)

Use this workflow when you need to submit changes via Pull Request.
**Do NOT try `az repos pr create` via CLI unless specifically instructed.**
**ALWAYS prefer generating a creation link for the user.**

## 1. Prerequisites
- Validate current branch with `git branch --show-current`.
- Ensure all changes are committed.
- Ensure branch is pushed to origin: `git push -u origin <branch>`.
- Verify remote branch exists: `git ls-remote --heads origin <branch>`.

## 2. Prepare PR Content
- Generate a Title following Conventional Commits (e.g., `feat(scope): description`).
- Generate a Description using the standard template:
  - **Scopo**: What & Why
  - **Deliverables**: List of key changes
  - **File cambiati**: Summary or list
  - **Test**: How it was verified
  - **Rollback**: How to revert

## 3. Generate Link (Azure DevOps)
Construct the URL dynamically:

```
https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal/pullrequestcreate?sourceRef=<SourceBranch>&targetRef=<TargetBranch>
```

- `<SourceBranch>`: The current feature branch (e.g., `feature/my-feature`)
- `<TargetBranch>`: Usually `develop` or `main`

## 4. Final Action (Notify User)
Use `notify_user` to present the result.

**Example Message:**
```markdown
## ✅ Branch pushed!

I have pushed the changes to `origin/<branch>`.
Please create the PR using the link below:

👉 **[Create Pull Request](<URL>)**

**Title:** `<Title>`
**Description:** (Copy & Paste)
`<Description>`
```

## 5. Verification
- After the user confirms creation, verify the PR exists via `az repos pr list --source-branch <branch>` (optional, read-only).
