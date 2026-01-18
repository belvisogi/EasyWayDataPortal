# tests/api

Esempi di chiamate REST per gli endpoint principali dell’API `easyway-portal-api`.

Contenuti:
- `rest-client/users.http` — CRUD utenti multi-tenant
- `rest-client/onboarding.http` — onboarding tenant+user via SP

Requisiti:
- Server locale: `npm run dev` dentro `portal-api/easyway-portal-api`
- Header obbligatorio: `X-Tenant-Id: tenant01` (o ID valido)

