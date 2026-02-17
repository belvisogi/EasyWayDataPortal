# Authentication Standards for Agents

**Version**: 1.0 (2026-02-17)
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

### 3.2 Forgejo
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
