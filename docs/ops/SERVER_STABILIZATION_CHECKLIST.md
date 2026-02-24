# Server Stabilization Checklist (ADO-first)

Versione: 1.0 (2026-02-24)  
Scope: allineamento server dopo merge su `develop`

## Comando Unico Consigliato

```powershell
Set-Location C:\path\to\EasyWayDataPortal
pwsh .\scripts\pwsh\server-sync-and-test.ps1 -RepoPath . -Branch develop
```

## Variante: Validazione PR prima del merge

```powershell
Set-Location C:\path\to\EasyWayDataPortal
pwsh .\scripts\pwsh\server-sync-and-test.ps1 -RepoPath . -PrId 122
```

## Checklist Go/No-Go

- [ ] `git fetch/pull` completato senza conflitti.
- [ ] `Initialize-AzSession.ps1 -VerifyFromFile` completato.
- [ ] Test Pester conformance passati (tier + formalization).
- [ ] Nessun errore auth bloccante su ADO/GitHub session init.
- [ ] Evidenza log disponibile per audit sessione.

## Criterio GO

Procedere con bootstrap GitHub solo se tutti i punti sopra sono verdi.

## Criterio NO-GO

Bloccare rollout GitHub e aprire remediation ticket se:

1. test conformance falliscono;
2. auth sessione fallisce ripetutamente;
3. branch non allineato con `origin/develop`.
