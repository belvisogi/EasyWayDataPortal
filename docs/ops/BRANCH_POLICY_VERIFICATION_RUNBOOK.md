# Branch Policy Verification Runbook (ADO)

Versione: 1.0 (2026-02-24)  
Scope: `EasyWay-DataPortal` / repo `EasyWayDataPortal`

## Obiettivo

Verificare in modo ripetibile che le policy su `develop` e `main` rispettino i controlli enterprise (SoD + anti-bypass).

## Owner

- Primario: `Repo Admin`
- Verifica indipendente: `Governance`

## Checklist Operativa

### 1) Branch `develop`

- [ ] Branch protetta.
- [ ] PR obbligatoria.
- [ ] Minimo 1 reviewer richiesto.
- [ ] `Allow requestors to approve their own changes` = OFF.
- [ ] `Prohibit the most recent pusher from approving` = ON.
- [ ] Required reviewers = gruppo umano (`grp.repo.humans.approvers`).
- [ ] Nessun account tecnico tra required reviewers.
- [ ] Required checks pipeline/guardrail = ON.
- [ ] `Work items must be linked` = ON (se policy richiesta dal processo).

### 2) Branch `main`

- [ ] Branch protetta.
- [ ] PR obbligatoria.
- [ ] Minimo 1 reviewer richiesto.
- [ ] `Allow requestors to approve their own changes` = OFF.
- [ ] `Prohibit the most recent pusher from approving` = ON.
- [ ] Required reviewers = gruppo umano (`grp.repo.humans.approvers`).
- [ ] Nessun account tecnico tra required reviewers.
- [ ] Required checks pipeline/guardrail = ON.
- [ ] Policy di merge coerente con release flow (`develop -> main`).

## Come Verificare (UI)

1. Aprire Azure DevOps: `Project settings -> Repositories -> EasyWayDataPortal -> Policies`.
2. Selezionare branch `develop`, verificare tutti i punti checklist.
3. Ripetere su branch `main`.
4. Salvare screenshot per ogni policy critica.
5. Allegare evidenze in ticket di governance/security.

## Evidenze Minime Richieste

- Screenshot policy `develop` (reviewers, checks, anti-self-approval).
- Screenshot policy `main` (reviewers, checks, anti-self-approval).
- Screenshot required reviewers (solo umani).
- Link PR recente di evidenza (es. `#122`) con gate passati.

## Definition of Done

- [x] Tutti i check `develop` verdi.
- [x] Tutti i check `main` verdi.
- [x] Nessun reviewer tecnico required.
- [x] Evidenze archiviate (ticket/log governance).
- [x] Security scorecard aggiornata.

## Stato Corrente

- Verifica completata in data `2026-02-24`.

## Escalation

Se un check fallisce:

1. Aprire ticket `High` verso `Repo Admin`.
2. Bloccare merge su branch impattata finche il fix non e applicato.
3. Rieseguire questo runbook e allegare nuove evidenze.
