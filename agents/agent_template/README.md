# Agent: {{AGENT_ROLE}} ({{AGENT_NAME}})

## Goal
{{# Agent Template (Standard)

## Update (2026-02-15)
This template has been aligned with the **Product Factory Kit** (P2.4).
It is now identical to `agents/templates/basic-agent/`.

## Purpose
This folder serves as the canonical source for:
1.  **Automated Factory**: When `agent_creator` is running (n8n), it should use this folder as source.
2.  **Manual Reference**: Developers can look here to see the latest standard structure.

## Structure
-   `manifest.json`: Standard configuration.
-   `PROMPTS.md`: Standard system prompt pattern.
-   `README.md`: Standard documentation layout.
-   `memory/`: Standard persistent storage.

## Legacy Note
The old `scripts/agent-template.ps1` has been deprecated in favor of `scripts/pwsh/agent-bootstrap.ps1`. stored in `agents/{{AGENT_NAME}}/memory/`.
