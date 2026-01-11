---
id: mvp-orch-wiki-dq
title: Wiki DQ Audit - WHAT
summary: Scorecard DQ (gap/link/graph) + backlog Kanban per wiki file-based; update board opzionale (HITL).
status: draft
owner: team-platform
updated: '2026-01-09'
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, dq, kanban]
---

# Wiki DQ Audit - WHAT

```powershell
pwsh scripts/docs-dq-scorecard.ps1 -WikiPath "wiki"
pwsh scripts/docs-dq-scorecard.ps1 -WikiPath "wiki" -UpdateBoard -WhatIf:$false
```
