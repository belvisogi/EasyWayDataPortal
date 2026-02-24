---
name: pr-server-validation
description: Golden path per delivery controllata: PR su develop + validazione server con evidenza formale GO/NO-GO.
---

# PR + Server Validation

## When to use
- Devi chiudere una feature branch con evidenza operativa verificabile.
- Devi confermare che il codice mergeato su `develop` sia valido anche su server.
- Devi produrre un gate esplicito (`GO` o `NO-GO`) per governance/release.

## Inputs
- Branch sorgente (`feature/...`).
- Branch target (`develop`, default).
- Provider PR (`ADO` o `GitHub`).
- Percorso server del repo (es. `/home/ubuntu/EasyWayDataPortal`).

## Outputs
- Link PR creata/aggiornata.
- Output comando `server-sync-and-test.ps1`.
- Evidenza gate finale (`GO`/`NO-GO`).

## Workflow
1. **Preflight branch/repo/session**
   - Verifica branch corrente e clean status.
   - Inizializza sessione provider (`Initialize-AzSession` o `Initialize-GitHubSession`).
2. **PR flow**
   - ADO: `pwsh scripts/pwsh/agent-pr.ps1 -TargetBranch develop -WhatIf:$false`
   - GitHub: push branch + apertura compare URL/PR.
3. **Server validation**
   - Esegui: `pwsh scripts/pwsh/server-sync-and-test.ps1 -RepoPath . -Branch develop`
   - Oppure via SSH con stesso script sul server.
4. **Evidence capture**
   - Salva output command log.
   - Registra esito in file gate (`GO`/`NO-GO`).

## Success criteria
- PR aperta e policy minime rispettate.
- `server-sync-and-test` termina con `Status: OK`.
- Evidenze archiviate in percorso condiviso runbook/audit.

## Failure handling
- **Auth/token failure** -> ruota token, riesegui session init, ripeti preflight.
- **Merge conflicts** -> merge `origin/develop` in branch feature, risolvi e push.
- **Server validation fail** -> blocca merge/release, apri remediation ticket e ripeti test.

## References
- `scripts/pwsh/server-sync-and-test.ps1`
- `scripts/pwsh/agent-pr.ps1`
- `docs/ops/SERVER_STABILIZATION_CHECKLIST.md`
- `docs/ops/SECURITY_SCORECARD.md`
- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
