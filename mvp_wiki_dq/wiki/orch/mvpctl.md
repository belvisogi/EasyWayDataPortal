---
id: mvp-orch-mvpctl
title: MVP Runner (ADO/Confluence) - WHAT
summary: Entry point agentico del MVP: chiede target (Azure DevOps o Confluence) e guida i passi.
status: draft
owner: team-platform
updated: '2026-01-09'
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, dq, kanban, confluence, azuredevops]
---

# MVP Runner (ADO/Confluence) - WHAT

## Plan (guidato)
Da `mvp_wiki_dq/`:
```powershell
pwsh scripts/mvpctl.ps1 -Mode plan
```

## Apply (HITL)
```powershell
pwsh scripts/mvpctl.ps1 -Mode apply
```

Note:
- `Target=azuredevops` richiede una wiki **locale** (clone/export) perche' il MVP lavora su filesystem Markdown.
- `Target=confluence` usa `intents/confluence.params.json` + env `CONFLUENCE_EMAIL/CONFLUENCE_API_TOKEN`.

