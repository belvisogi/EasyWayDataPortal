# agent_developer
**Role**: Agent_Developer | **Level**: L2

## Overview
Executes branch-per-PBI workflow, semantic commits, and PR opening tasks.

## Runner
- `agents/agent_developer/developer-run.ps1`

## Actions
- `dev:start-task` → create/switch feature branch from develop
- `dev:commit-work` → semantic commit + push
- `dev:open-pr` → open PR from current branch to develop

## Usage
```powershell
pwsh ./agents/agent_developer/developer-run.ps1 -Action start-task -Pbi PBI-123 -Desc improve-logging
pwsh ./agents/agent_developer/developer-run.ps1 -Action commit-work -Type feat -Message "add logging"
pwsh ./agents/agent_developer/developer-run.ps1 -Action open-pr
```
