# EasyWay Agentic Platform - Maintenance Plan

**Scope**: Multi-VCS Governance (ADO, GitHub, Forgejo) & Agent Runtime
**Owner**: `team-platform`

## 1. Weekly Audit Routine
**Frequency**: Weekly (Monday AM)
**Owner**: DevOps Lead / `agent_governance`

### 1.1 Governance Audit
Run the audit checks to verify no policy drift:
```powershell
# 1. Verify Branch Protection
# Manually check ADO/GitHub/Forgejo settings or use future automated script

# 2. Verify Guardrails in CI
# Check recent PRs for "BranchPolicyGuard" and "EnforcerCheck" execution status.
```

### 1.2 Agent Identity Audit
- Verify `svc.agent.*` accounts have no interactive login usage.
- Check `docs/ops/logs/llm-router-events.jsonl` for anomalous approvals or bypassed RAG evidence.

## 2. Credential Rotation Policy
**Frequency**: 90 Days (or on compromise)

| Secret | Provider | Scope | Procedure |
|os|---|---|---|
| `ADO_PAT` | Azure DevOps | Code Read/Write, PR | Generate new PAT -> Update Variable Group `EasyWay-Secrets` |
| `GH_TOKEN` | GitHub | Repo scope | Generate new Token -> Update Variable Group |
| `FORGEJO_TOKEN` | Forgejo | Repo scope | Generate new Token -> Update Variable Group |
| `OPENAI/ANTHROPIC` | LLM | API | Rotate Key -> Update `llm-router.config.ps1` (local) |

## 3. Incident Response
**Trigger**:
- "Split-brain" git history detected.
- Policy bypass detected.
- Unauthorized agent action.

**Procedure**:
1. **Lock**: Enable "ReadOnly" mode on router (disable all providers in config).
2. **Analyze**: Review `activity-log.jsonl` and `llm-router-events.jsonl`.
3. **Remediate**: Force-sync from "Source of Truth" (usually development workstation or `develop` branch on ADO).
4. **Restore**: Re-enable providers after root cause fix.

## 4. Backup Ownership
- Primary: `Current Shift Lead`
- Secondary: `Platform Engineering Manager`
- Automated Backup: `backup/` directory sync to Datalake (daily).
