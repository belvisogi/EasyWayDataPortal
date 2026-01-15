# Agent Synapse

> [!NOTE]
> This agent follows the **Gold Standard** structure. Setup verified by `validate-agent.ps1` (Score: 100/100).

## Role
Role: `Agent_Synapse`
Description: Manages Azure Synapse / PySpark workspace artifacts. Scaffolds standard folder structures and ensures project compliance.

## Capabilities (Actions)
This agent supports the following actions:

| Action | Description | Script |
|--------|-------------|--------|
| `synapse:scaffold` | Creates standard folders (pipelines, notebooks...) and README | `actions/scripts/scaffold-workspace.ps1` |
| `synapse:check-sql` | Verifies connectivity to SQL Pool (Read-Only) | `../../connectors/sql-check.ps1` |

## Orchestration Context
This agent is part of the **Synapse Project Environment**:
1.  **Storage**: `agent_datalake` (Pre-requisite)
2.  **Workspace**: `agent_synapse` (This Agent)
3.  **Database**: `agent_dba` (Post-requisite)

Use `axctl --intent project:synapse-init` to orchestrate them all.

## Knowledge Layout
- **Memory**: `memory/prompts/`
- **Tests**: `tests/validate.ps1`

## Maintainers
- @team-platform
