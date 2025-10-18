# Developer Onboarding (Agent‑Ready)

Questo progetto è pensato per essere mantenuto al 100% in modo agentico. Di seguito i passi minimi, completamente scriptabili.

- Prerequisiti
  - Node.js 20+
  - Azure SQL local/managed e `sqlcmd` (oppure PowerShell `SqlServer` module)
  - PowerShell 7+
- Configurazione
  - Opzione A (consigliata): compila `EasyWay-DataPortal/easyway-portal-api/.env.local` (il backend lo carica automaticamente come fallback, senza sovrascrivere variabili già presenti)
  - Opzione B: copia `.env.example` in `.env` e compila i valori (attenzione a non committare `.env`)
- Provisioning DB (locale o Azure SQL)
  - Esempio Azure SQL (tuo host/db):
    `pwsh ./scripts/bootstrap.ps1 -Server repos-easyway-dev.database.windows.net,1433 -Database easyway-admin -User <user> -Password "<pwd>"`
  - Esempio locale:
    `pwsh ./scripts/bootstrap.ps1 -Server localhost,1433 -Database EasyWayDataPortal -User sa -Password "..." -TrustServerCertificate`
- Avvio backend API
  - `cd EasyWay-DataPortal/easyway-portal-api`
  - `npm ci && npm run dev`
- Smoke test
  - Apri `tests/api/rest-client/health.http`, `tests/api/rest-client/users.http`, `tests/api/rest-client/onboarding.http`
  - Oppure chiamate dirette: `GET http://localhost:3000/api/health`
- Documentazione contrattuale API
  - `GET http://localhost:3000/api/docs` (yaml/json)

Note agentiche
- Tutte le decisioni sono codificate in file sotto version control (OpenAPI, SQL, pipeline).
- Gli script sono idempotenti e ri‑eseguibili senza frizioni.
