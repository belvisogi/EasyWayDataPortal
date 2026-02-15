# Git Safe Sync

Use this script to avoid accidental `git pull` rebase conflicts on shared branches.

Script:
- `scripts/pwsh/git-safe-sync.ps1`

## Recommended

```powershell
pwsh -NoProfile -File .\scripts\pwsh\git-safe-sync.ps1 -Branch develop -Remote origin -Mode align -SetGuardrails
```

What it does:
1. aborts rebase if one is in progress;
2. checks out target branch;
3. fetches remote;
4. creates backup branch if local has commits not on remote;
5. aligns safely to `origin/<branch>` (`reset --hard` in `align` mode);
6. sets guardrails (`pull.rebase=false`, `pull.ff=only`).

## Safer Preview

```powershell
pwsh -NoProfile -File .\scripts\pwsh\git-safe-sync.ps1 -Branch develop -Remote origin -Mode align -SetGuardrails -DryRun
```

## Modes

- `align`: deterministic align to remote (after backup).
- `ff-only`: only fast-forward; fails if local is ahead/diverged.
