# agent_release
**Role**: Release Manager

## Overview
Gestisce il workflow di release in due modalita': promozione branch locale e sync sicuro del server runtime.

## Capabilities
- `release:promote`: preflight (`clean working tree`, sync con `origin`), policy naming/target, merge/push con draft release notes.
- `release:server-sync`: backup branch/tag + stash sul server, sync su branch target (default `main`), clean opzionale residui runtime, via skill riusabile `git.server-sync`.
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
Promozione branch (default mode):
```powershell
pwsh ./scripts/pwsh/agent-release.ps1 -Mode promote
```

Esecuzione non interattiva:
```powershell
pwsh ./scripts/pwsh/agent-release.ps1 -Mode promote -SourceBranch develop -TargetBranch main -Yes
```

Sync server verso `main` (safe mode):
```powershell
pwsh ./scripts/pwsh/agent-release.ps1 `
  -Mode server-sync `
  -ServerHost 80.225.86.168 `
  -ServerUser ubuntu `
  -ServerSshKeyPath \"C:\\old\\Virtual-machine\\ssh-key-2026-01-25.key\" `
  -TargetBranch main `
  -Yes
```

Se hai residui root-owned da pulire dopo sync:
```powershell
pwsh ./scripts/pwsh/agent-release.ps1 `
  -Mode server-sync `
  -ServerHost 80.225.86.168 `
  -ServerSshKeyPath \"C:\\old\\Virtual-machine\\ssh-key-2026-01-25.key\" `
  -ServerSudoCleanPaths infra/observability rag-service packages/packages `
  -Yes
```
