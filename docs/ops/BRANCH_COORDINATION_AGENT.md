# Branch Coordination Agent

Date: 2026-02-14

## Purpose

Coordinate multiple workers (machines, LLMs, Antigravity, ClaudeCode) across different branches without collisions.

Script:
- canonical: `agents/core/tools/agent-branch-coordinator.ps1`
- wrapper: `scripts/pwsh/agent-branch-coordinator.ps1`

Lease file:
- `docs/ops/branch-leases.json`
- bootstrap template: `docs/ops/branch-leases.example.json`
- runtime note: `branch-leases.json` is local runtime state and is git-ignored.

## Actions

Recommend branch decision:

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action recommend -TaskId pbi-123 -Tool antigravity
```

Recommend with LLM advisory (optional):

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action recommend -TaskId pbi-123 -Tool antigravity -UseLlmRouter -LlmRouterConfigPath .\scripts\pwsh\llm-router.config.ps1 -RagEvidenceId rag-20260214-branch-01
```

Claim branch for a worker:

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action claim -Branch feature/pbi-123-api -WorkerId vm-a-codex -Tool codex
```

Alias supported:
- `-AgentId` (equivalent to `-WorkerId`)

Keep lease alive:

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action heartbeat -Branch feature/pbi-123-api -WorkerId vm-a-codex
```

Release lease:

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action release -Branch feature/pbi-123-api -WorkerId vm-a-codex
```

Show active leases:

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action status
```

Machine-readable status:

```powershell
pwsh -File .\scripts\pwsh\agent-branch-coordinator.ps1 -Action status -JsonOutput
```

## Decision Rules (`recommend`)

1. If current branch is `main|develop|baseline`, suggest `create-and-switch`.
2. If current branch is leased by another worker, suggest `switch-branch`.
3. If worker already has active lease on another branch, suggest switching there.
4. Otherwise suggest `stay`.
5. If `-UseLlmRouter` is enabled, the deterministic decision is kept and an optional `llmAdvice` is appended.

## Integration Pattern

Before any coding session:
1. run `recommend`
2. if decision is `create-and-switch` or `switch-branch`, switch/checkout
3. run `claim`

During session:
1. run `heartbeat` periodically (or after each commit)

At handoff/finish:
1. run `release`
