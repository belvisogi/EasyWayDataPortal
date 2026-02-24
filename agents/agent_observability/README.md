# agent_observability
**Role**: Agent_Observability | **Level**: L2

## Overview
Runs health and log checks with telemetry-first observability workflow.

## Runner
- `agents/agent_observability/observability-run.ps1`

## Actions
- `obs:healthcheck` → local health checks
- `obs:check-logs` → log analysis over recent window

## Usage
```powershell
pwsh ./agents/agent_observability/observability-run.ps1 -Action healthcheck
pwsh ./agents/agent_observability/observability-run.ps1 -Action check-logs -InputPath .\out\obs-intent.json
```
