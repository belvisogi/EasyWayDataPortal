# agent_pr_manager
**Role**: Agent_PR_Manager | **Level**: L2

## Overview
Manages PR lifecycle with description generation and governance gate checks.

## Runner
- `agents/agent_pr_manager/pr-manager-run.ps1`

## Actions
- `pr:create` → prepare PR description and creation command
- `pr:validate-gates` → validate branch-level merge gates

## Usage
```powershell
pwsh ./agents/agent_pr_manager/pr-manager-run.ps1 -Action create -Title "feat: update" -TargetBranch develop -WhatIf
pwsh ./agents/agent_pr_manager/pr-manager-run.ps1 -Action validate-gates
```
