# Multi-Provider Security Parity Matrix

Versione: 1.0 (2026-02-24)  
Scope: Azure DevOps, GitHub, Forgejo

## Obiettivo
Garantire lo stesso livello di sicurezza su tutti gli execution planes VCS, senza eccezioni di provider.

## Baseline Controls (Provider-Agnostic)

| Control | Azure DevOps | GitHub | Forgejo | Stato target |
|---|---|---|---|---|
| Separation of Duties (creator != approver) | Required reviewers + no self-approval | Required approvals + no self-approval | Protected branch approvals + no self-approval | Mandatory |
| Branch Protection (`develop`, `main`) | Branch policies | Branch rules/rulesets | Protected branches | Mandatory |
| Required checks | Build validation + guardrail jobs | Required status checks | Required status checks | Mandatory |
| Least privilege token scopes | PAT scopes minimi | PAT/App scopes minimi | PAT scopes minimi | Mandatory |
| Token rotation <= 90 giorni | PAT rotation process | PAT/App token rotation | PAT rotation | Mandatory |
| Session initializer standard | `Initialize-AzSession.ps1` | `Initialize-GitHubSession.ps1` | (to add) `Initialize-ForgejoSession.ps1` | Mandatory |
| RBAC broker integration | `Import-AgentSecrets.ps1` | `Import-AgentSecrets.ps1` | `Import-AgentSecrets.ps1` | Mandatory |
| Human gate su apply critici | Enforced by workflow/policy | Enforced by workflow/policy | Enforced by workflow/policy | Mandatory |
| Audit trail | PR + pipeline + RBAC logs | PR + actions + RBAC logs | PR + CI + RBAC logs | Mandatory |

## Provider Mapping (Operational)

### Azure DevOps
- PR Creator: `svc-agent-pr-creator`
- Approver: gruppo umano dedicato
- Core checks: BranchPolicyGuard, EnforcerCheck, CI

### GitHub
- PR Creator: service account/bot dedicato
- Approver: team umano `approvers`
- Core checks: required reviews, required status checks, no force-push

### Forgejo
- PR Creator: utente tecnico dedicato
- Approver: team umano separato
- Core checks: protected branch + approval + CI required

## Gaps Tracker (Current)

| Provider | Gap principale | Priorita |
|---|---|---|
| Azure DevOps | Gap accesso project chiuso (evidenza PR `#122`), mantenere monitoraggio auth CLI | Low |
| GitHub | Definire/validare mapping gruppi + branch rules equivalenti | High |
| Forgejo | Formalizzare initializer sessione + parity check automatico | Medium |

## Rollout Plan

1. Consolidare ADO: required reviewer umano e policy anti-bypass verificate.
2. Implementare stessa policy branch su GitHub e Forgejo.
3. Introdurre `Initialize-ForgejoSession.ps1` con stesso pattern reset+RBAC.
4. Aggiungere test conformance multi-provider (fail se un provider e' sotto baseline).
5. Rieseguire scorecard con rating per provider e rating globale.

## Definition of Parity

Un provider e' "in parity" quando:
- tutti i controlli baseline sono attivi;
- non esistono bypass noti su approvazione/merge;
- audit e rotazione token sono verificabili.

## Riferimenti

- `docs/ops/SECURITY_SCORECARD.md`
- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
- `docs/ops/authentication_standards.md`
