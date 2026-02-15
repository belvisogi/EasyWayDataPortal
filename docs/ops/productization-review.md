# Productization Review Checklist

**Agent Name:** ____________________
**Reviewer:** ____________________
**Date:** ____________________

## 1. Governance & Compliance
- [ ] **Manifest Valid**: `manifest.json` passes `agent-maintenance.ps1 -Action Lint`.
- [ ] **Role Defined**: Agent has a clear, scoped Role and Mission.
- [ ] **Approvals**: Critical actions (push, delete) require approval in `manifest.json`.
- [ ] **Access Control**: `allowed_paths` is restricted to minimum necessary.

## 2. Reliability & Quality
- [ ] **System Prompt**: `PROMPTS.md` follows the standard template.
- [ ] **Idempotency**: Agent actions are safe to retry.
- [ ] **Error Handling**: Agent handles API failures gracefully (retry/fallback).
- [ ] **Integration Test**: At least one end-to-end test case runs successfully.

## 3. Cost & Performance
- [ ] **Model Selection**: Uses appropriate model (e.g., `speed_first` for simple tasks).
- [ ] **Token Limits**: `max_tokens` is set appropriately in `llm_config`.
- [ ] **Budget**: Estimated monthly run cost is within project budget.

## 4. Maintenance
- [ ] **Documentation**: `README.md` explains Usage, Capabilities, and Memory.
- [ ] **Owner**: `owner` field in manifest points to a valid team/person.
- [ ] **Build Pipeline**: Agent is included in CI/CD (Azure Pipeline).

## 5. Security
- [ ] **Secrets**: No hardcoded API keys/passwords in prompts or code.
- [ ] **Input Validation**: Agent sanitizes inputs (if acting on sensitive systems).

---
**Decision:**
- [ ] **APPROVED** for Production
- [ ] **REJECTED** (Fix items above)
