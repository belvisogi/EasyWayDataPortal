# Security Scorecard - Agentic SDLC

Versione: 1.1 (2026-02-24)  
Scope: EasyWayDataPortal (Git + ADO + local RBAC)

## Executive Score

- Stato complessivo: **8.6/10** (ADO PR flow sbloccato, hardening in chiusura)
- Target: **>= 8.5 / 10** raggiunto per fase ADO

## Control Matrix (RAG)

| Area | Stato | Evidenza | Gap | Owner |
|---|---|---|---|---|
| Separation of Duties (creator != approver) | 🟢 | PR #122 creata da `svc-agent-pr-creator` con reviewer required umano | Formalizzare gruppo umano approver come required standard | Governance |
| Branch Protection (`develop/main`) | 🟢 | Policy verificate su `develop/main` (24 Feb 2026) | Mantenere review periodica anti-drift | Repo Admin |
| Least Privilege PAT | 🟡 | Profili `.env.*` separati | Scope/token da ripulire e consolidare | Security |
| Token Hygiene (stale token reset) | 🟢 | `Initialize-AzSession` + `Initialize-GitHubSession` reset automatico | Nessuno critico | Platform |
| RBAC locale (Gatekeeper) | 🟢 | `Import-AgentSecrets` + `C:\old\rbac-master.json` | Review periodica ruoli | Platform |
| Audit Trail | 🟡 | Log presenti (RBAC/audit/PR) | Cadence review non formalizzata | Ops |
| Human Gate su operazioni critiche | 🟡 | Policy documentata | Enforcement operativo da rendere sistematico | Governance |
| Service Account Access in ADO Project | 🟢 | PR ADO create con service account (`#120`, `#121`, `#122`) | Monitoraggio auth transiente CLI | ADO Admin |

## Priority Actions (Top 5)

1. Consolidare reviewer required umano su `develop/main` (no account tecnici required).
2. Formalizzare rotazione PAT (scadenza, owner, data ultima rotazione, evidenza).
3. Istituire review settimanale permessi + audit log check (30 minuti, checklist fissa).
4. Avviare Fase B GitHub con parity controls equivalenti ad ADO.
5. Aggiungere controllo anti-drift mensile sulle policy branch.

## Definition of Done (Security >= 8.5)

- [x] PR automation funzionante con service account dedicato e scope minimi.
- [ ] 0 sovrapposizioni tra ruoli creator/approver/admin operativo.
- [x] Tutte le branch policy critiche ON e verificate.
- [ ] Registro rotazione token attivo e aggiornato.
- [ ] Review periodica sicurezza tracciata (almeno 2 cicli consecutivi).

## Evidenze Operative (2026-02-24)

- PR `#120`: creazione automatica riuscita via `agent-pr.ps1`.
- PR `#121`: rigenerazione PR su `feature/session19-l2-batch-upgrade -> develop`.
- PR `#122`: PR attiva con creator service account e reviewer required umano.

## Riferimenti

- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
- `docs/ops/MULTI_PROVIDER_SECURITY_PARITY_MATRIX.md`
- `docs/ops/authentication_standards.md`
- `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md`
