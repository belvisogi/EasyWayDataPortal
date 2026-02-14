# Multi-VCS Agent MVP (ADO + GitHub + Forgejo)

Date: 2026-02-14  
Scope: agente operativo unico per auth check, sync multi-remote, monitor branch stability, PR creation cross-provider.

## 1. Files

- `scripts/pwsh/agent-multi-vcs.ps1`
- `scripts/pwsh/multi-vcs.config.example.ps1`
- Reuse:
  - `scripts/pwsh/push-all-remotes.ps1`
  - `scripts/pwsh/watch-branch-presence.ps1`
  - `scripts/pwsh/set-git-remotes-ssh.ps1`

## 2. Setup rapido

1. Copiare config:

```powershell
Copy-Item .\scripts\pwsh\multi-vcs.config.example.ps1 .\scripts\pwsh\multi-vcs.config.ps1
```

2. Aggiornare `multi-vcs.config.ps1` con:
- remoti presenti (`ado`, `github`, `forgejo`);
- target branch PR per provider;
- repo identifiers (`owner/repo`, organization/project/repository, forgejo url/repo).

3. Migrare remoti a SSH:

```powershell
pwsh -File .\scripts\pwsh\set-git-remotes-ssh.ps1 -Apply
```

## 3. Comandi principali

Auth check:

```powershell
pwsh -File .\scripts\pwsh\agent-multi-vcs.ps1 -Action validate-auth -Branch <branch>
```

Sync multi-remote hardenizzato:

```powershell
pwsh -File .\scripts\pwsh\agent-multi-vcs.ps1 -Action sync -Branch <branch> -RepairMissingBranch
```

Monitor anti-sparizione:

```powershell
pwsh -File .\scripts\pwsh\agent-multi-vcs.ps1 -Action monitor -Branch <branch> -MonitorSamples 30 -MonitorIntervalSeconds 60
```

Create PR cross-provider:

```powershell
pwsh -File .\scripts\pwsh\agent-multi-vcs.ps1 -Action create-pr -Branch <branch> -Title "my pr" -Description "details" -DryRun
```

Create PR with LLM drafting (optional, antifragile-safe fallback):

```powershell
pwsh -File .\scripts\pwsh\agent-multi-vcs.ps1 -Action create-pr -Branch <branch> -UseLlmRouter -LlmRouterConfigPath .\scripts\pwsh\llm-router.config.ps1 -RagEvidenceId rag-20260214-pr-01 -DryRun
```

## 4. Tool integration

Provider CLI usati:
- ADO: `az`
- GitHub: `gh`
- Forgejo: `tea`

Note:
- in `-DryRun`, l'agente stampa i comandi PR senza eseguirli;
- senza CLI installata, la capability specifica provider non e' eseguibile.
- se `-UseLlmRouter` fallisce o manca `RagEvidenceId`, l'agente continua con drafting standard locale.

## 5. Security baseline

Obbligatorio:
1. `SSH for Git`, `PAT/token solo per CLI/API`.
2. `Deny Force push` su branch protetti (`main`, `develop`) per contributor/build/service accounts.
3. evidenza monitor branch prima di merge/release.

## 6. Definition of Done (MVP agent)

1. `validate-auth` ok su tutti i remoti configurati.
2. `sync` ok con verifica multi-pass.
3. `monitor` senza eventi `missing` per la finestra target.
4. `create-pr` eseguito (o command plan validato) per provider target.
