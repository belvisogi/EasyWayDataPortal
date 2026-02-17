# Git Scenarios & "The Agent Way"

**Tag**: `#git` `#workflow` `#cookbook`

This document records real-world Git scenarios encountered during the EasyWay development, serving as a guide for future agents and developers.

## Scenario 1: The "Protected File" Conflict
**Context**: You are working on a feature branch (`feature/x`). Meanwhile, `origin/develop` has been updated by another agent, modifying a shared configuration file (e.g., `.cursorrules` or `.gitignore`).
**Symptom**: `git push` works, but the PR on Azure DevOps shows "Merge Conflict".

### ❌ The Wrong Way
-   Trying to resolve it in the Azure DevOps Web UI (lacks context/tools).
-   Thinking "I must merge my branch into develop manually locally" (violates Branch Safety).

### ✅ The Agent Way (Correct)
Bring the changes from `develop` *into* your feature branch to resolve the conflict safely.

1.  **Fetch Latest State**:
    ```bash
    git fetch origin develop
    ```
2.  **Merge INTO Feature**:
    ```bash
    # Ensure you are on your feature branch
    git checkout feature/amazing-feature
    git merge origin/develop
    ```
3.  **Resolve Locally**:
    -   Git will pause on conflict.
    -   Edit the file: keep both changes or intelligently combine them.
    -   `git add <file>`
4.  **Commit & Push**:
    ```bash
    git commit -m "chore: resolve merge conflict with develop"
    git push origin feature/amazing-feature
    ```
**Result**: The PR on Azure DevOps automatically updates, detects the resolution, and becomes "Green" (Ready to Merge).

---

## Scenario 2: The "Stacked Feature" Workflow
**Context**: You need to build Feature B, which depends on Feature A, but Feature A is waiting for PR approval.
**Goal**: Don't stop working.

### Strategy
1.  **Develop Local** is your sanity.
2.  Merge Feature A into your local `develop` (Simulation).
3.  Branch Feature B from this advanced state.
4.  **Push**: When you push Feature B, it will include A's commits. This is fine. Azure DevOps is smart enough to handle the diffs once A is merged.

---

## Pro Tip: Atomic Merge vs. Context Switching
You might ask: *"Why fetch and merge origin/develop instead of checking out develop and pulling?"*

### The Human Way
```bash
git checkout develop
git pull
git checkout feature/my-feature
git merge develop
```
-   **Risk**: If your local `develop` has uncommitted changes or trash, you pollute the merge.
-   **Slow**: 4 context switches (file system churn).

### The Agent Way (Atomic)
```bash
git fetch origin develop
# (While on feature/my-feature)
git merge origin/develop
```
-   **Safe**: We never touch local `develop` directly. We merge exactly what is on the server.
-   **Fast**: Zero file system churn on `develop`.
-   **Precise**: Ensures we resolve against the Production Truth, not local drift.
