# EasyWay Agent Instructions (Canonical)

This file is the canonical agent instruction entrypoint for `C:\old\EasyWayDataPortal`.

## Scope

- Applies only to this repository: `C:\old\EasyWayDataPortal`.
- For operational/governance rules, use these sources in order:
  1. `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md` (source of truth)
  2. `.cursorrules` (auto-synced derivative via `scripts/pwsh/Sync-PlatformMemory.ps1`)
  3. This `AGENTS.md` (scope + routing rules)

## Non-Normative AGENTS Files

- Files under `Wiki/**/archive/**/AGENTS.md` or `Wiki/**/indices/**/Agents.md` are historical/index artifacts.
- They are not normative for current operations and must not override the sources above.

## Mandatory Coupling

- When governance/workflow rules change, update both:
  - `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md`
  - `.cursorrules` (normally via sync script)
- Pre-commit guardrails enforce this coupling.

## Standard Commands

- Commit (Smart Commit only):
  - `pwsh scripts/pwsh/ewctl.ps1 commit -m "type(scope): message"`
- PR creation (atomic, recommended):
  - `pwsh scripts/pwsh/agent-pr.ps1 -Title "fix(scope): ..." -WhatIf:$false`
- Sync wiki -> cursorrules:
  - `pwsh scripts/pwsh/Sync-PlatformMemory.ps1`

