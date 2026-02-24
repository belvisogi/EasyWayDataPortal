# Access Model One-Pager (Atomic, Multi-Provider)

Versione: 1.0 (2026-02-24)  
Scope: Azure DevOps, GitHub, Forgejo, altri provider Git enterprise

## Obiettivo
Definire un modello accessi semplice, atomico e riusabile, con separation-of-duties e least privilege.

## Naming Standard

Pattern:
`grp.<scope>.<actor>.<capability>`

Esempi:
- `grp.repo.agents.pr-creators`
- `grp.repo.humans.approvers`
- `grp.repo.release.managers`

## Gruppi Standard (Baseline)

| Gruppo | Membri tipici | Cosa puo fare | Cosa NON puo fare |
|---|---|---|---|
| `grp.repo.agents.pr-creators` | `svc-agent-pr-creator` | push branch operativi, create/update PR | approvare proprie PR, bypass policy |
| `grp.repo.humans.approvers` | reviewer umani | approvare PR su branch protetti | automazione tecnica massiva |
| `grp.repo.humans.developers` | dev umani | sviluppo su branch operativi | merge diretto su `main/develop` |
| `grp.repo.agents.ado-executors` | `svc-agent-ado-executor` | azioni ADO su work items/apply | approvare PR, admin repo |
| `grp.repo.agents.scrum` | `svc-agent-scrum-master` | planning/sprint/board/reporting | merge release, admin security |
| `grp.repo.release.managers` | release manager umano o svc dedicato | orchestrare release `develop -> main` | bypass policy branch |
| `grp.repo.admin.breakglass` | admin senior (pochi) | interventi emergenza tracciati | uso quotidiano |

## Identita Minime (4 utenti)

1. `svc-agent-pr-creator`  
2. `svc-agent-ado-executor`  
3. `svc-agent-scrum-master`  
4. `human-approver` (utente/team umano)

## Atomic Setup (Runbook in 8 Step)

1. Creare i gruppi standard con naming coerente.
2. Assegnare membri (1 identita = 1 ruolo principale).
3. Configurare branch protection su `develop/main`:
- PR obbligatoria
- min reviewer >= 1
- no self-approval
- no approval del last pusher
- required checks obbligatori
4. Impostare token scope minimi per ruolo (least privilege).
5. Salvare token fuori repo (`C:\old\.env.*`) e mappare RBAC in `C:\old\rbac-master.json`.
6. Inizializzare sessione nello stesso processo operativo:
- `Initialize-AzSession.ps1`
- `Initialize-GitHubSession.ps1`
7. Verificare accesso reale (project/repo visibility + create PR dry run).
8. Eseguire audit finale con checklist governance.

## Provider Mapping (Portable)

| Controllo | ADO | GitHub | Forgejo |
|---|---|---|---|
| Branch protected | Branch Policies | Rulesets/Branch Rules | Protected Branches |
| Required reviews | Min reviewer policy | Required approvals | Required approvals |
| Required checks | Build validation/checks | Required status checks | Required status checks |
| Token auth | PAT | PAT / App | PAT |

## Anti-Pattern da Evitare

- Stessa identita in creator e approver.
- Token “full access” senza motivazione.
- Segreti dentro repo/script versionati.
- Lavoro diretto su `develop/main`.
- Gruppo `breakglass` usato per operativita normale.

## Definition of Done

- [ ] Tutti i gruppi standard creati.
- [ ] Membership allineata ai ruoli.
- [ ] Policy branch attive e verificate.
- [ ] Token segregati e scope minimi.
- [ ] Init session provider funzionante.
- [ ] Audit checklist completata.

## Riferimenti

- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
- `docs/ops/SECURITY_SCORECARD.md`
- `docs/ops/MULTI_PROVIDER_SECURITY_PARITY_MATRIX.md`
- `docs/ops/authentication_standards.md`
