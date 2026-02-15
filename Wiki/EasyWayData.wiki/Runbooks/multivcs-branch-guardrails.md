---
id: ew-runbook-multivcs-branch-guardrails
title: Multi-VCS Branch Guardrails (ADO, GitHub, Forgejo)
summary: Runbook operativo per impostare e verificare guardrail robusti su branch e PR in Azure DevOps, GitHub e Forgejo.
status: active
owner: team-platform
updated: 2026-02-15
tags: [runbook, guardrail, git, ado, github, forgejo, governance, language/it, audience/dev, audience/ops]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
type: guide
---

# Multi-VCS Branch Guardrails (ADO, GitHub, Forgejo)

## Obiettivo
Definire una baseline unica di protezioni Git per evitare cancellazioni non volute, force-push non autorizzati, merge senza quality gates e drift tra provider.

## Scope
- Azure DevOps Repos
- GitHub
- Forgejo
- Branch critici: `main`, `develop`
- Branch operativi: `feature/*`, `chore/*`, `hotfix/*`

## Convenzione branch per PBI (standard)
Pattern raccomandato per lavoro DevOps/PBI:
- `feature/devops/PBI-<id>-<slug>`

Esempi:
- `feature/devops/PBI-342-sync-guardrails`
- `feature/devops/PBI-410-antigravity-handoff`

Pattern alternativi per dominio:
- `feature/frontend/PBI-<id>-<slug>`
- `feature/backend/PBI-<id>-<slug>`
- `hotfix/devops/INC-<id>-<slug>`
- `hotfix/devops/BUG-<id>-<slug>`
- `chore/devops/PBI-<id>-<slug>`

Regole:
1. ogni branch operativo deve includere `PBI-<id>` quando derivato da backlog ADO;
2. sotto `hotfix` non usare `PBI`: usare solo `INC-<id>` o `BUG-<id>`;
3. vietato lavorare su `develop`/`main` come branch di implementazione;
4. il titolo PR deve iniziare con lo stesso id (`PBI-<id>` o `INC/BUG-<id>`).

## Allineamento PRD
Questo runbook implementa operativamente le linee guida del PRD platform:
- `docs/PRD_EASYWAY_AGENTIC_PLATFORM.md` (integrazione Sprint 1 su `GitHub`/`Azure DevOps`/`Forgejo`)
- `docs/PRD_EASYWAY_AGENTIC_PLATFORM.md` (Policy Git Multi-Remote e guardrail minimi)

## Baseline obbligatoria (tutti i provider)
1. PR obbligatoria su `main` e `develop`.
2. Disabilitare force-push su `main` e `develop`.
3. Disabilitare delete branch su `main` e `develop`.
4. Almeno 1 approvazione reviewer.
5. Status checks obbligatori (CI verde) prima del merge.
6. Niente bypass policy per gruppi non admin.
7. `Delete source branch` disattivato di default (se non esplicitamente richiesto).

## Matrice permessi consigliata
- `Contributors`: push consentito su branch operativi, delete/force-push negato.
- `Maintainers/Release Managers`: eccezioni controllate e tracciate.
- `Administrators`: pieno controllo, uso limitato a emergenze.

## Identita' agenti (gruppi + utenti servizio)
Principio:
- gli agenti non devono operare con account personali; usare service identities dedicate.

Gruppi minimi consigliati:
1. `grp.repo.agents.read`
2. `grp.repo.agents.write`
3. `grp.repo.agents.pr`
4. `grp.repo.agents.release`
5. `grp.repo.agents.admin` (break-glass, ristretto)

Utenti servizio consigliati:
1. `svc.agent.antigravity.devops`
2. `svc.agent.antigravity.release`
3. `svc.agent.antigravity.guard`

Regole operative:
1. 1 identita' per capability critica (non account condivisi umani);
2. secret/token separati per provider (`ADO`, `GitHub`, `Forgejo`);
3. rotazione credenziali periodica e revoca immediata su compromise;
4. ogni azione deve produrre audit con identity tecnica esplicita.

## Azure DevOps (passi)
1. `Repos -> Branches -> ... -> Branch security`.
2. Su `refs/heads` (globale), gruppo `Contributors`:
- `Force push (rewrite history, delete branches and tags)` = `Deny`
- `Contribute` = `Allow`
- `Manage permissions` = `Not set` (o `Deny` se richiesto)
3. Su `develop` e `main`:
- `Branch policies` -> build validation required.
- marcare come required i job guardrail:
  - `BranchPolicyGuard` (naming branch + target flow PR)
  - `EnforcerCheck` (allowed_paths agent)
- `Minimum number of reviewers` >= 1.
- Disabilitare completamento PR senza policy.
4. Lock opzionale su branch critici durante finestre sensibili.

## GitHub (passi)
1. `Settings -> Branches` (o `Rulesets`).
2. Regole su `main` e `develop`:
- `Require a pull request before merging`
- `Require approvals` (>=1)
- `Require status checks to pass`
- `Do not allow bypassing` (eccetto admin autorizzati)
- `Allow force pushes` = OFF
- `Allow deletions` = OFF
3. Regola su `feature/*`, `chore/*`, `hotfix/*`:
- force-push OFF
- delete limitato a maintainer/admin

## Forgejo (passi)
1. `Repository Settings -> Branches -> Protected Branches`.
2. Proteggi `main` e `develop`:
- merge solo via PR
- approvals minime >= 1
- status checks required
- force-push disabilitato
- delete branch disabilitato
3. Definisci policy separate per prefissi branch operativi.

## Procedura standard per agenti
1. Sincronizza branch con comando standard:
`pwsh -NoProfile -File .\scripts\pwsh\git-safe-sync.ps1 -Branch develop -Remote origin -Mode align -SetGuardrails`
2. Crea branch di lavoro.
3. Commit mirati (solo file in scope).
4. Push branch.
5. Apri PR verso `develop`.
6. Attendi CI + approvazione.
7. Merge senza bypass policy.

## Verifica allineamento (comandi esempio)
Verifica rapida su `develop`:

```powershell
git checkout develop
git fetch --prune origin
git status -sb
git rev-list --left-right --count origin/develop...develop
```

Interpretazione:
- `git status -sb` deve mostrare working tree pulito.
- `git rev-list --left-right --count origin/develop...develop`:
  - `0 0` = allineato;
  - primo numero > 0 = locale indietro;
  - secondo numero > 0 = locale avanti.

Verifica presenza branch remoto (es. branch PR):

```powershell
git ls-remote --heads origin chore-git-safe-sync develop main
```

Verifica safe-sync in preview (nessuna modifica):

```powershell
pwsh -NoProfile -File .\scripts\pwsh\git-safe-sync.ps1 -Branch develop -Remote origin -Mode align -SetGuardrails -DryRun
```

## Audit periodico (settimanale)
1. Verifica presenza branch protection su `main`/`develop`.
2. Verifica che delete/force-push siano negati ai contributor.
3. Verifica che i check CI richiesti siano ancora attivi.
4. Verifica che non esistano eccezioni permanenti non approvate.
5. Registra esito audit in log governance.

## Incident response (branch cancellato)
1. Recupera commit da clone locale: `git reflog` / `git branch -a`.
2. Ripubblica branch: `git push origin <sha>:refs/heads/<branch>`.
3. Applica lock temporaneo al branch.
4. Correggi permessi globali (`refs/heads`) e branch-specific.
5. Apri ticket post-mortem con causa e contromisura.

## Checklist rapida
- [ ] PR required su `main` e `develop`
- [ ] Force-push bloccato su branch critici
- [ ] Delete branch bloccato su branch critici
- [ ] CI required in PR
- [ ] `BranchPolicyGuard` required in PR
- [ ] `EnforcerCheck` required in PR
- [ ] Reviewer minimo impostato
- [ ] Nessun bypass policy non autorizzato
- [ ] Audit settimanale pianificato

## Riferimenti
- `docs/ops/GIT_SAFE_SYNC.md`
- `wiki/EasyWayData.wiki/checklist-ado-required-job.md`
- `wiki/EasyWayData.wiki/enforcer-guardrail.md`
- `docs/PRD_EASYWAY_AGENTIC_PLATFORM.md`
