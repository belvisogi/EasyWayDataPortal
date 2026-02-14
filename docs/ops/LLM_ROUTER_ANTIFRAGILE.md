# LLM Router Antifragile (Fase 1)

Date: 2026-02-14

## Goal

Provide a single control point for LLM calls with:
- provider fallback with circuit breaker,
- mandatory human approval for critical actions,
- append-only event log for audit,
- mandatory RAG evidence before operational outputs.

## Artifacts

- Canonical router script: `agents/core/tools/agent-llm-router.ps1`
- Backward-compatible wrapper: `scripts/pwsh/agent-llm-router.ps1`
- Config template: `scripts/pwsh/llm-router.config.example.ps1`
- Runtime state: `docs/ops/llm-router-state.json` (git-ignored)
- Event log: `docs/ops/logs/llm-router-events.jsonl` (git-ignored)
- Approval files: `docs/ops/approvals/*.json` (git-ignored)

## Bootstrap

1. Copy config:
```powershell
Copy-Item .\scripts\pwsh\llm-router.config.example.ps1 .\scripts\pwsh\llm-router.config.ps1
```
2. Enable providers and set API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`) if needed.
3. Keep at least one provider enabled (`levi-local` is safe default mock).

## Usage

Invoke non-critical operation (requires RAG evidence by default):
```powershell
pwsh -File .\scripts\pwsh\agent-llm-router.ps1 -Action invoke -Prompt "Summarize branch risk" -TaskType risk-review -RagEvidenceId rag-20260214-01 -JsonOutput
```

Invoke critical operation (approval required):
```powershell
pwsh -File .\scripts\pwsh\agent-llm-router.ps1 -Action invoke -Prompt "Prepare push decision" -TaskType git-op -CriticalAction push -RagEvidenceId rag-20260214-02 -JsonOutput
```

Approve request:
```powershell
pwsh -File .\scripts\pwsh\agent-llm-router.ps1 -Action approve -ApprovalId apr-YYYYMMDD... -Approver "owner@easyway"
```

Re-run with approval:
```powershell
pwsh -File .\scripts\pwsh\agent-llm-router.ps1 -Action invoke -Prompt "Prepare push decision" -TaskType git-op -CriticalAction push -ApprovalId apr-YYYYMMDD... -RagEvidenceId rag-20260214-02 -JsonOutput
```

Get router status:
```powershell
pwsh -File .\scripts\pwsh\agent-llm-router.ps1 -Action status -JsonOutput
```

## Antifragile Rules

1. No RAG evidence -> no operational invoke.
2. No approval -> no critical action path.
3. Provider failures increase `failureCount`; after threshold the circuit opens.
4. Every attempt (success/fail/block) is written to event log.

## Integration Next

1. Plug router into `scripts/pwsh/agent-multi-vcs.ps1` for `create-pr` decision text.
2. Plug router into `scripts/pwsh/agent-branch-coordinator.ps1` for proactive branch recommendations.
3. Add post-incident auto-tests for each new failure mode.
