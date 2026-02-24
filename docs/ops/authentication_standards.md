# Authentication Standards for Agents

**Version**: 1.1 (2026-02-24)
**Scope**: All Agentic Integrations (EasyWay, PR-Agent, Custom Scripts)

## 1. Golden Rule
**Agents NEVER use human interactive login.**
*   ❌ `az login` (Interactive/Device Code) -> **FORBIDDEN** (expires, blocks automation).
*   ❌ Username/Password -> **FORBIDDEN** (security risk, MFA blocks it).
*   ✅ **Personal Access Tokens (PAT)** or **Service Principals** -> **MANDATORY**.

## 2. Authentication Matrix (Cross-Platform)

This table defines the standard authentication method for Agents across all supported platforms.

| Platform | Human Method (Interactive) | Agent Method (Automation) | Configuration Location (Standard) |
| :--- | :--- | :--- | :--- |
| **Azure DevOps** | `az login` | **PAT (Personal Access Token)** | `.secrets.toml` -> `[azure_devops]` |
| **Forgejo** | Web Login | **PAT (Personal Access Token)** | `.secrets.toml` -> `[gitea]` / `Header: Authorization: token ...` |
| **GitHub** | Web Login | **PAT** or **GitHub App Key** | `.secrets.toml` -> `[github]` |
| **GitLab** | Web Login | **Personal Access Token** | `.secrets.toml` -> `[gitlab]` |
| **Bitbucket** | SSO / User+Pass | **App Password** / **Bearer Token** | `.secrets.toml` -> `[bitbucket]` |

## 3. Implementation Guide

### 3.1 Azure DevOps (ADO)
1.  **Generate**: User Settings -> Personal Access Tokens -> New Token.
2.  **Scopes**: `Code (Read & Write)`, `Pull Request Threads (Read & Write)`.
3.  **Usage**:
    ```powershell
    # CLI
    echo "$env:ADO_PAT" | az devops login --org https://dev.azure.com/EasyWayData
    ```

### 3.2 GitHub
1.  **Generate**: Settings -> Developer settings -> Personal access tokens.
2.  **Scopes**: repository scope minimo necessario (least privilege).
3.  **Usage**:
    ```powershell
    # Session bootstrap via standardized script
    pwsh scripts/pwsh/Initialize-GitHubSession.ps1
    ```

### 3.3 Forgejo
1.  **Generate**: Settings -> Applications -> Generate New Token.
2.  **Scopes**: `repo`, `admin:org` (if needed for org management).
3.  **Usage**:
    ```bash
    # API Header
    Authorization: token <YOUR_FORGEJO_PAT>
    ```

## 4. Security Policy
*   **Rotation**: Tokens must be rotated every 90 days.
*   **Storage**: Never commit tokens to git. Use `.secrets.toml` (gitignored) or Environment Variables.
*   **Least Privilege**: Grant only the scopes necessary for the agent's function.

## 5. EasyWay Session Initializers (Mandatory)

Standard scripts:
- `scripts/pwsh/Initialize-AzSession.ps1`
- `scripts/pwsh/Initialize-GitHubSession.ps1`

Rules:
1. Always initialize auth in the same process that executes provider CLI/API commands.
2. Initializers reset process token variables by default to avoid stale credentials.
3. Use `-NoTokenReset` only for explicit debugging scenarios.
4. Tokens are loaded via `Import-AgentSecrets.ps1` and enforced by `C:\old\rbac-master.json`.

Expected local profiles (outside repo):
- `C:\old\.env.developer` (`AZURE_DEVOPS_EXT_PAT`)
- `C:\old\.env.github` (`GH_TOKEN` / `GITHUB_TOKEN`)

## 6. Rollout Checklist (Apply to All Initializers)

- [ ] All provider initializers reset process token variables by default.
- [ ] All provider initializers use Gatekeeper (`Import-AgentSecrets.ps1`) instead of direct file parsing.
- [ ] All provider initializers expose a `-Verify` mode for diagnostics.
- [ ] All provider tokens are scoped in RBAC profiles by agent role.
- [ ] Deprecated provider-specific helpers are moved to `C:\old\old\legacy-scripts\`.

## 7. Governance Reference

For full enterprise controls (SoD, branch policy, audit cadence), see:
- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
