# Agent Second Brain 🧠
**Role**: Navigator

## Overview
Questo agente è responsabile della **navigabilità semantica** e della **Context Injection** nella documentazione.
Il suo compito principale è generare e mantenere i **Breadcrumbs Obsidian-style** (`[[Home]] > [[Domain]] > [[Page]]`) che permettono agli LLM (e agli umani) di orientarsi nel grafo della conoscenza.

## Capabilities
- **Generazione Breadcrumbs**: Calcola il percorso semantico basato sul Knowledge Graph (generato da `agent-docs-scanner`).
- **Hierarchy Game Awareness**: Utilizza la struttura definita da `wiki-tags-lint` (Path) e `agent-docs-scanner` (Content) per determinare la posizione di una pagina.
- **Smart Linking**: Risolve i tag astratti (`domain/db`) verso le pagine Wiki reali (`[[domains/db|db]]`).

## Architecture
- **Script**: `scripts/agent-second-brain.ps1`
- **Memory**: Legge `agents/memory/knowledge-graph.json`.
- **Injection Point**: Subito dopo il frontmatter YAML.

## Usage
```powershell
# Interattivo (default Generate)
pwsh scripts/agent-second-brain.ps1

# DryRun (Safety First)
pwsh scripts/agent-second-brain.ps1 -DryRun

# Clean (Rimuove breadcrumbs)
pwsh scripts/agent-second-brain.ps1 -Action Clean
```

## Principles
- **Idempotenza**: Non duplica i breadcrumbs se esistono e sono corretti.
- **Context Injection**: Fornisce contesto immediato ("Dove sono?") per RAG e Vector Search.
- **Synergy**: Lavora in tandem con l'Agente "Game Gerarchico" (Arbitro).

## Maintainers
- **Team**: Platform / Docs
- **Integrations**: GEDI Pattern (Philosophical Review)
