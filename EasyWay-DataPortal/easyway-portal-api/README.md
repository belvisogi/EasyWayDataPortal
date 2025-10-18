# EasyWay Data Portal API - Starter Kit

Node.js + TypeScript + Express, configurazione YAML su Datalake e tabella CONFIGURATION su SQL Server.

## Comandi principali

- `npm install` — installa tutte le dipendenze
- `npm run dev` — avvia il backend in modalità sviluppo (hot reload)
- `npm run build` — compila TypeScript in `/dist`
- `npm start` — avvia il backend dalla build

## Struttura file configurazione

- `/datalake-sample/branding.tenant01.yaml` - esempio YAML branding
- Tabella `PORTAL.CONFIGURATION` (solo DB) - per parametri runtime (script SQL in chat DB)

## Variabili d'Ambiente (DEV/PROD)

L'app carica le variabili da `.env` e da `.env.local` (root del progetto API). Vedi `src/app.ts`.

File di esempio: `.env.example` in questa cartella. Copialo in `.env.local` e personalizza.

Obbligatorie per Auth (JWT Entra ID):
- `AUTH_ISSUER` – es. `https://login.microsoftonline.com/<TENANT_ID>/v2.0`
- `AUTH_JWKS_URI` – es. `https://login.microsoftonline.com/<TENANT_ID>/discovery/v2.0/keys`
- `AUTH_AUDIENCE` – opzionale (valida `aud` se impostato)
- `TENANT_CLAIM` – default `ew_tenant_id`

Obbligatorie per branding su Blob:
- `AZURE_STORAGE_CONNECTION_STRING` – connection string dell'account di Storage
- `BRANDING_CONTAINER` – es. `portal-assets`
- `BRANDING_PREFIX` – default `config` (il file viene cercato come `config/branding.{tenantId}.yaml`)

Opzionali/consigliate:
- `LOG_LEVEL` – default `info`
- `QUERIES_CONTAINER` e `QUERIES_PREFIX` – per override SQL su Blob (fallback locale in `src/queries`)
- `DB_CONN_STRING` – connection string SQL Server (oppure usa `DB_HOST/DB_NAME/DB_USER/DB_PASS` con `dbConfigLoader`)

### Esempio DEV (`.env.local`)
```
LOG_LEVEL=debug
DB_CONN_STRING=Server=tcp:localhost,1433;Database=EASYWAY_DEV;User Id=sa;Password=YourStrong!Passw0rd;Encrypt=false
# Auth (uso di un tenant di test)
AUTH_ISSUER=https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0
AUTH_JWKS_URI=https://login.microsoftonline.com/YOUR_TENANT_ID/discovery/v2.0/keys
TENANT_CLAIM=ew_tenant_id
AZURE_STORAGE_CONNECTION_STRING=UseDevelopmentStorage=true
BRANDING_CONTAINER=portal-assets
BRANDING_PREFIX=config
```

Con `UseDevelopmentStorage=true` puoi usare Azurite.

### Esempio PROD (variabili pipeline/KeyVault)
- Imposta le var in Azure DevOps Variable Group (es. `EasyWay-Secrets`) o in Key Vault
- Mappa i nomi 1:1 con quelli richiesti dall'app:
  - `AZURE_STORAGE_CONNECTION_STRING`
  - `BRANDING_CONTAINER=portal-assets`
  - `BRANDING_PREFIX=config`
  - `DB_CONN_STRING=...` (o i parametri DB separati)

La pipeline (`azure-pipelines.yml`) importa il Variable Group; le variabili sono disponibili agli step.

## Sicurezza & Tenant Claim
- Tutti gli endpoint richiedono Bearer JWT valido; il tenant viene derivato da un claim applicativo (default `ew_tenant_id`).
- Non inviare `X-Tenant-Id` dal client. Se transiti da APIM, puoi far iniettare l’header solo internamente per audit.

## Test
- Jest è configurato. Gli endpoint sono protetti: senza `Authorization: Bearer <token>` i test/requests otterranno 401.
- Puoi eseguire uno smoke test: `npm test` (il test health verifica 401 senza token).

### Checklist Bot (Agent-Ready)
- Da root repo: `pwsh ./scripts/checklist.ps1`
- Da cartella API: `npm run check:predeploy`
- Cosa verifica: env richieste (Auth/Branding), connessione SQL, accesso Storage (branding + queries), presenza e validità OpenAPI.
- Output: JSON + riepilogo umano; exit code != 0 se falliscono check critici.
