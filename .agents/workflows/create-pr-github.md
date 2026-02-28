---
description: How to create a Pull Request (PR) on GitHub using the Agent-Assisted Link Pattern
---

# PR Creation Workflow (GitHub Agent-Assisted)

Use this workflow when you need to submit changes via Pull Request on GitHub.
**Do NOT try `gh pr create` via CLI unless specifically instructed.**
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
  - **Spiegazione Dettagliata**: Detailed breakdown of the developments and architectural choices made in this PR.
  - **Security Checklist**:
    - [ ] No hardcoded secrets (`.env` checks)
    - [ ] No PII/Credentials in Git History
    - [ ] Input Validation applied
  - **Deliverables**: List of key changes
  - **File cambiati**: Summary or list
  - **Test**: How it was verified
  - **Rollback**: How to revert

## 3. Generate Link (GitHub)
Construct the URL dynamically for GitHub. You **MUST** URL-encode the `title` and `body` parameters to pre-fill the PR.

```
https://github.com/belvisogi/EasyWayDataPortal/compare/<TargetBranch>...<SourceBranch>?expand=1&title=<UrlEncodedTitle>&body=<UrlEncodedBody>
```

- `<SourceBranch>`: The current feature branch (e.g., `feature/my-feature`)
- `<TargetBranch>`: Usually `develop` or `main`
- `<UrlEncodedTitle>`: The PR Title, URL encoded (e.g., `feat(api):%20add%20login`)
- `<UrlEncodedBody>`: The PR Description (including the Security Checklist and Spiegazione Dettagliata), URL encoded.

## 4. Final Action (Notify User)
Use `notify_user` to present the result. Do not just print the template, you must execute the URL encoding yourself and give the user the final, clickable, fully populated link.

**Example Message:**
```markdown
## ✅ Branch pushed!

I have pushed the changes to `origin/<branch>`.
I have prepared the fully populated PR link for you. Clicking it will automatically fill the Title, Description, and Security Checklist!

👉 **[Create Pull Request (Auto-filled)](<URL>)**
```

## 5. Verification
- After the user confirms creation, you can verify the PR status if the GitHub CLI is available via `gh pr view <branch>` (optional).
