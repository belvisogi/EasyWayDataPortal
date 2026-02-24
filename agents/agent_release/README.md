# agent_release
**Role**: Agent_Release | **Level**: L2

## Overview
Manages controlled branch promotion and optional server synchronization.

## Runner
- `agents/agent_release/release-run.ps1`

## Actions
- `release:promote` → promote source branch to target branch
- `release:server-sync` → sync target branch to remote runtime server

## Usage
```powershell
pwsh ./agents/agent_release/release-run.ps1 -Action promote -SourceBranch develop -TargetBranch main -Strategy merge
pwsh ./agents/agent_release/release-run.ps1 -Action server-sync -ServerHost 80.225.86.168 -TargetBranch main
```
