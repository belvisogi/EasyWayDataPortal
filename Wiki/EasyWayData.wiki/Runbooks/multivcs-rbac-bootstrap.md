---
id: ew-runbook-multivcs-rbac-bootstrap
title: Multi-VCS RBAC Bootstrap (ADO, GitHub, Forgejo)
summary: Matrice operativa clic-by-clic per gruppi, service identities e permessi minimi su Azure DevOps, GitHub e Forgejo.
status: active
owner: team-platform
updated: 2026-02-15
tags: [runbook, rbac, iam, ado, github, forgejo, governance, language/it, audience/dev, audience/ops]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
type: guide
---

# Multi-VCS RBAC Bootstrap (ADO, GitHub, Forgejo)

## Obiettivo
Definire uno standard unico EasyWay per identita' tecniche, gruppi e permessi minimi in ambiente multi-provider.

## Principi
1. Least privilege by default.
2. Niente account personali per agenti.
3. Permessi assegnati ai gruppi, non direttamente agli utenti servizio.
4. Break-glass separato e auditato.
5. Segreti separati per provider con rotazione periodica.

## Naming standard
Gruppi:
1. `grp.repo.agents.read`
2. `grp.repo.agents.write`
3. `grp.repo.agents.pr`
4. `grp.repo.agents.release`
5. `grp.repo.agents.admin`

Service identities:
1. `svc.agent.antigravity.devops`
2. `svc.agent.antigravity.release`
3. `svc.agent.antigravity.guard`

Nota:
- i nomi sopra sono baseline consigliata; se cambia il prefisso team, mantenere lo stesso schema semantico.

## Azure DevOps - Clic by clic
1. `Project Settings -> Permissions`:
- crea/valida i gruppi `grp.repo.agents.*`.
2. `Repos -> Branches -> refs/heads -> Branch security`:
- `Contributors` e gruppi agent non-admin:
  - `Force push (rewrite history, delete branches and tags)` = `Deny`
  - `Contribute` = `Allow` (solo dove necessario)
3. `Repos -> Branches -> develop/main -> Branch policies`:
- build validation required.
- required checks: `BranchPolicyGuard`, `EnforcerCheck`.
- minimum reviewers >= 1.
4. `Project Settings -> Service connections / tokens`:
- separa credenziali per provider.
- associa identita' tecnica al gruppo corretto.

## GitHub - Clic by clic
1. `Settings -> Collaborators and teams`:
- crea team equivalenti ai gruppi `grp.repo.agents.*`.
2. `Settings -> Branches` (o `Rulesets`):
- `main`/`develop`:
  - Require pull request
  - Require approvals
  - Require status checks
  - Disallow force push
  - Disallow deletions
3. assegna bot/service account ai team minimi necessari.
4. `Settings -> Secrets and variables`:
- token separati per scope (read/write/pr/release).

## Forgejo - Clic by clic
1. `Repository Settings -> Collaborators / Teams`:
- crea team equivalenti ai gruppi `grp.repo.agents.*`.
2. `Repository Settings -> Branches -> Protected Branches`:
- proteggi `main`/`develop`.
- disabilita force-push e delete.
- richiedi PR + approvals + checks.
3. configura utenti tecnici dedicati per automazioni.
4. separa token/chiavi SSH per capability.

## Matrice minima permessi
`grp.repo.agents.read`
- read repo, no push, no PR merge.

`grp.repo.agents.write`
- push solo branch operativi, no force-push/delete.

`grp.repo.agents.pr`
- create/update PR, no bypass policy, no direct merge su branch protetti.

`grp.repo.agents.release`
- merge controllato + tag/release secondo policy.

`grp.repo.agents.admin`
- break-glass, uso eccezionale, audit obbligatorio.

## Audit operativo
Frequenza: settimanale.

Checklist:
1. esistenza gruppi standard.
2. nessun agente operativo con permessi admin.
3. token separati per provider.
4. rotazione credenziali nei tempi previsti.
5. allineamento tra policy documentate e policy effettive.

## Riferimenti
- `Wiki/EasyWayData.wiki/Runbooks/multivcs-branch-guardrails.md`
- `Wiki/EasyWayData.wiki/checklist-ado-required-job.md`
- `docs/PRD_EASYWAY_AGENTIC_PLATFORM.md`
