# PAT Rotation Register

Versione: 1.0 (2026-02-24)  
Regola: rotazione massima ogni 90 giorni

## Campi Obbligatori

| Data rotazione | Identity | Provider | Scope minimo atteso | Scadenza token | Owner | Evidenza update env/RBAC | Stato |
|---|---|---|---|---|---|---|---|

## Registro

| Data rotazione | Identity | Provider | Scope minimo atteso | Scadenza token | Owner | Evidenza update env/RBAC | Stato |
|---|---|---|---|---|---|---|---|
| 2026-02-24 | `svc-agent-pr-creator` | Azure DevOps | `Code (Read/Write)` + `Pull Request Contribute` | 2026-03-26 | Security | `.env.developer` aggiornato + test PR `#122` | Active |

## Checklist Post-Rotazione

- [ ] Token precedente revocato.
- [ ] Nuovo token propagato nei profili autorizzati (`C:\old\.env.*`).
- [ ] RBAC registry verificato (`C:\old\rbac-master.json`).
- [ ] Test operativo eseguito (PR/create/list).
- [ ] Evidenza archiviata in docs/ticket.

## Alerting Manuale

- 15 giorni prima scadenza: aprire task di rotazione.
- 7 giorni prima scadenza: escalation a `Security` + `Platform`.
- Token scaduto: blocco operazioni automation fino a rotazione completata.
