# Agent: Factory Tester (agent_factory_test)

## Goal
Agent created to verify the Product Factory Kit

## Context
This agent is part of the EasyWay Agentic Platform.
It operates under standard governance and uses the shared memory context.

## Usage
Calling this agent via Router:
```powershell
pwsh scripts/pwsh/agent-llm-router.ps1 -Agent agent_factory_test -Prompt "Your request here"
```

## Capabilities
- **Read Access**: Can read its own directory and shared KB.
- **Write Access**: Can write to its local `memory/` folder.
- **Tools**: Access to `pwsh` and `node` for execution.

## Memory
Persisted context is stored in `agents/agent_factory_test/memory/`.

