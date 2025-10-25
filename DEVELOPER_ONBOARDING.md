# Developer Onboarding (Agent‑Ready)

Questo progetto è pensato per essere mantenuto al 100% in modo agentico. Di seguito i passi minimi, completamente scriptabili e riusabili su altri progetti.

- Prerequisiti
  - Node.js 20+
  - Azure SQL local/managed e `sqlcmd` (oppure PowerShell `SqlServer` module)
  - PowerShell 7+
- Configurazione
  - Compila `EasyWay-DataPortal/easyway-portal-api/.env.local` partendo da `.env.example`
  - Auth (Entra ID): `AUTH_ISSUER`, `AUTH_JWKS_URI`, (opz.) `AUTH_AUDIENCE`, `TENANT_CLAIM=ew_tenant_id`
  - Storage: `AZURE_STORAGE_CONNECTION_STRING` o Managed Identity con `AZURE_STORAGE_ACCOUNT`; `BRANDING_CONTAINER`, `BRANDING_PREFIX`
  - DB: `DB_CONN_STRING` (oppure `DB_AAD=true` + `DB_HOST`/`DB_NAME`)
- Provisioning DB (locale o Azure SQL)
  - Esempio Azure SQL (tuo host/db):
    `pwsh ./scripts/bootstrap.ps1 -Server repos-easyway-dev.database.windows.net,1433 -Database easyway-admin -User <user> -Password "<pwd>"`
  - Esempio locale:
    `pwsh ./scripts/bootstrap.ps1 -Server localhost,1433 -Database EasyWayDataPortal -User sa -Password "..." -TrustServerCertificate`
- Avvio backend API (dual‑mode)
  - `cd EasyWay-DataPortal/easyway-portal-api`
  - Sviluppo low‑cost: imposta `DB_MODE=mock` in `.env.local` e genera JWKS/token con `npm run dev:jwt` (valorizza `AUTH_TEST_JWKS`)
  - Avvio: `npm ci && npm run dev`
 - Smoke test
  - Apri `tests/api/rest-client/health.http`, `tests/api/rest-client/users.http`, `tests/api/rest-client/onboarding.http`
  - Imposta `@token` (Bearer JWT) con claim tenant; senza token gli endpoint rispondono 401
- Documentazione contrattuale API
  - `GET http://localhost:3000/api/docs` (yaml/json)

Documentazione "replicabile"
- Blueprint completo: `Wiki/EasyWayData.wiki/blueprints/replicate-easyway-dataportal.md`
- Security & Observability: `Wiki/EasyWayData.wiki/EasyWay_WebApp/05_codice_easyway_portale/security-and-observability.md`
- APIM JWT policy (opzionale): `Wiki/EasyWayData.wiki/EasyWay_WebApp/05_codice_easyway_portale/apim-jwt-tenant-claim-policy.md`

Dual‑mode (approfondimento)
- Guida: `Wiki/EasyWayData.wiki/dev-dual-mode.md`

Note agentiche
- Tutte le decisioni sono codificate in file sotto version control (OpenAPI, SQL, pipeline).
- Gli script sono idempotenti e ri‑eseguibili senza frizioni.

