---
id: mvp-orch-confluence-dq
title: Confluence Cloud DQ Kanban - WHAT
summary: Export read-only Confluence Cloud + pagina Kanban dedicata (HITL, WhatIf di default).
status: draft
owner: team-platform
updated: '2026-01-09'
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, confluence, dq, kanban]
---

# Confluence Cloud DQ Kanban - WHAT

```powershell
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -PlanOnly
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -Export
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -Export -UpdateBoard -WhatIf
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -Export -UpdateBoard -WhatIf:$false
```
