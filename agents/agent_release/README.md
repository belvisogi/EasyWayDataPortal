# agent_release
**Role**: Release Manager

## Overview
Gestisce il workflow di release tra branch con controlli di sicurezza, analisi contesto e bozza automatica release notes.

## Capabilities
- Preflight check (`clean working tree`, sync con `origin`).
- Safety warning per flussi rischiosi (es. `develop -> main`).
- Merge orchestrato con skill `git.checkout`, `git.merge`, `git.push`.
- Generazione draft release notes in `agents/logs/`.
- Ritorno automatico al branch iniziale a fine esecuzione.

## Architecture
- **Script**: `scripts/pwsh/agent-release.ps1`
- **Manifest**: `agents/agent_release/manifest.json`
- **Prompt**: `agents/agent_release/PROMPTS.md`
- **Workflow Standard**: `Wiki/EasyWayData.wiki/standards/gitlab-workflow.md`
- **Release Alignment Doc**: `Wiki/EasyWayData.wiki/control-plane/release-flow-alignment-2026-02-12.md`

## Usage
```powershell
pwsh ./scripts/pwsh/agent-release.ps1
```

Esecuzione non interattiva:
```powershell
pwsh ./scripts/pwsh/agent-release.ps1 -SourceBranch develop -TargetBranch main -Yes
```
