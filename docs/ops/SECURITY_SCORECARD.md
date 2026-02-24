# Security Scorecard - Agentic SDLC

Versione: 1.0 (2026-02-24)  
Scope: EasyWayDataPortal (Git + ADO + local RBAC)

## Executive Score

- Stato complessivo: **7/10** (Foundation solida, non ancora fully mature)
- Target: **8.5+ / 10** entro prossimo ciclo di hardening

## Control Matrix (RAG)

| Area | Stato | Evidenza | Gap | Owner |
|---|---|---|---|---|
| Separation of Duties (creator != approver) | 🟡 | Team separati definiti | Membership reali da finalizzare | Governance |
| Branch Protection (`develop/main`) | 🟡 | Workflow definito + policy note | Required checks da verificare al 100% | Repo Admin |
| Least Privilege PAT | 🟡 | Profili `.env.*` separati | Scope/token da ripulire e consolidare | Security |
| Token Hygiene (stale token reset) | 🟢 | `Initialize-AzSession` + `Initialize-GitHubSession` reset automatico | Nessuno critico | Platform |
| RBAC locale (Gatekeeper) | 🟢 | `Import-AgentSecrets` + `C:\old\rbac-master.json` | Review periodica ruoli | Platform |
| Audit Trail | 🟡 | Log presenti (RBAC/audit/PR) | Cadence review non formalizzata | Ops |
| Human Gate su operazioni critiche | 🟡 | Policy documentata | Enforcement operativo da rendere sistematico | Governance |
| Service Account Access in ADO Project | 🔴 | Token valido letto | Accesso progetto non coerente (`VS800075`) | ADO Admin |

## Priority Actions (Top 5)

1. Correggere membership/permessi ADO del service account PR creator (blocca PR automation).
2. Rimuovere definitivamente account tecnici dal gruppo approver umano.
3. Verificare e bloccare bypass policy su `develop/main` (self-approval OFF, pusher-approval OFF).
4. Formalizzare rotazione PAT (scadenza, owner, data ultima rotazione, evidenza).
5. Istituire review settimanale permessi + audit log check (30 minuti, checklist fissa).

## Definition of Done (Security >= 8.5)

- [ ] PR automation funzionante con service account dedicato e scope minimi.
- [ ] 0 sovrapposizioni tra ruoli creator/approver/admin operativo.
- [ ] Tutte le branch policy critiche ON e verificate.
- [ ] Registro rotazione token attivo e aggiornato.
- [ ] Review periodica sicurezza tracciata (almeno 2 cicli consecutivi).

## Riferimenti

- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
- `docs/ops/MULTI_PROVIDER_SECURITY_PARITY_MATRIX.md`
- `docs/ops/authentication_standards.md`
- `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md`
