# Governance Rigorosa - Enterprise Checklist

Versione: 1.0 (2026-02-24)  
Scope: EasyWay Agentic SDLC (Git + ADO/GitHub + RBAC locale)

## Obiettivo
Definire controlli minimi obbligatori per mantenere separation-of-duties, least privilege, auditabilita e riduzione del rischio operativo.

## Modello Ruoli Minimo (4 identita)

1. `svc-agent-pr-creator`
- Responsabilita: branch/push/create PR.
- Non approva PR.

2. `svc-agent-ado-executor`
- Responsabilita: apply su Work Items/azioni ADO.
- Non fa merge su branch protetti.

3. `svc-agent-scrum-master`
- Responsabilita: planning/boards/reporting.
- No permessi repo write se non strettamente richiesto.

4. `human-approver` (utente umano/team umano)
- Responsabilita: approvazione PR e decisione finale di rilascio.

## Controlli Obbligatori

### A. Separation of Duties
- [ ] L'identita che crea la PR NON e' nel gruppo approver richiesto.
- [ ] L'approver richiesto e' umano (o gruppo umano).
- [ ] Nessun account tecnico in gruppi admin non necessari.

### B. Branch Protection
- [ ] `main` e `develop` protetti.
- [ ] PR obbligatoria su branch protetti.
- [ ] Minimo 1 reviewer richiesto.
- [ ] `Allow requestors to approve their own changes` = OFF.
- [ ] `Prohibit most recent pusher from approving` = ON.
- [ ] Status checks required (CI + guardrail).

### C. Least Privilege sui Token
- [ ] PAT `svc-agent-pr-creator`: `Code (Read & Write)` + `Pull Request Contribute`.
- [ ] PAT `svc-agent-ado-executor`: solo scope Work Items necessari.
- [ ] Nessun PAT con scope superflui.
- [ ] Rotazione token <= 90 giorni.

### D. Secrets & RBAC Locale
- [ ] Segreti solo fuori repo (`C:\old\.env.*`).
- [ ] `C:\old\rbac-master.json` allineato ai ruoli effettivi.
- [ ] `Import-AgentSecrets.ps1` usato come unico broker.
- [ ] Session bootstrap obbligatorio (`Initialize-AzSession`, `Initialize-GitHubSession`).

### E. Processo Operativo
- [ ] Workflow obbligatorio: `feature -> develop -> main`.
- [ ] Commit via `ewctl commit`.
- [ ] Nessun lavoro diretto su `develop`/`main`.
- [ ] Handoff documentato per ogni sessione significativa.

### F. Audit e Tracciabilita
- [ ] Audit log disponibile (RBAC + pipeline + PR).
- [ ] Revisione permessi gruppi settimanale.
- [ ] Verifica membership/project access dei service account.
- [ ] Post-mortem obbligatorio su bypass/fail policy.

## Criterio di Compliant
Un ambiente e' "compliant" quando tutte le sezioni A-F sono complete senza eccezioni aperte.

## Anti-Pattern (Da Evitare)
- Stessa identita in `PR Creator` e `Approver`.
- PAT condivisi tra utenti/ruoli.
- Scope token "full access" senza motivazione.
- Override manuale policy branch senza ticket.
- Token in repository o in script versionati.

## Scorecard
- Stato sintetico e progress tracking: `docs/ops/SECURITY_SCORECARD.md`
- Parita multi-provider: `docs/ops/MULTI_PROVIDER_SECURITY_PARITY_MATRIX.md`
