# EasyWay Data Portal API - Starter Kit

Node.js + TypeScript + Express, configurazione YAML su Datalake e tabella CONFIGURATION su SQL Server.

## Comandi principali

- `npm install` — installa tutte le dipendenze
- `npm run dev` — avvia il backend in modalità sviluppo (hot reload)
- `npm run build` — compila TypeScript in `/dist`
- `npm start` — avvia il backend dalla build

## Mini Portal (demo)
- Percorsi pubblici (senza auth) per integrare file forniti:
  - `GET /portal` — indice del mini‑portale
  - `GET /portal/home` — serve `home_easyway.html` dalla root del repo
  - `GET /portal/palette` — serve `palette_EasyWay.html`
  - `GET /portal/logo.png` — serve `logo.png`
  - `GET /portal/tenant/{tenantId}` — pagina dinamica che applica il branding YAML del tenant (`DEFAULT_TENANT_ID` usato se non specificato)
- `GET /portal/app` - demo Login+Registrazione via MSAL (Entra ID); richiede configurazione `AUTH_CLIENT_ID`/`AUTH_TENANT_ID`

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
- `TENANT_CLAIM` - default `ew_tenant_id`

Sviluppo locale (Auth mock):
- `AUTH_TEST_JWKS` - JWKS locale per validare token firmati in locale (usa `npm run dev:jwt` per generarlo)

DB dual-mode:
- `DB_MODE=mock|sql` - `mock` salva i dati in `data/dev-users.json`; `sql` usa Azure SQL

Obbligatorie per branding su Blob:
- `AZURE_STORAGE_CONNECTION_STRING` – connection string dell'account di Storage
- `BRANDING_CONTAINER` – es. `portal-assets`
- `BRANDING_PREFIX` – default `config` (il file viene cercato come `config/branding.{tenantId}.yaml`)
- `RLS_CONTEXT_ENABLED` – default `true`; se `false` non imposta `SESSION_CONTEXT('tenant_id')` (utile per debug)
- `PORTAL_BASE_PATH` – default `/portal`; base path per il mini‑portale
- `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX` – rate limiting (default 60000ms/600 req)
- `BODY_LIMIT` – limite dimensione JSON body (default `1mb`)
- `LOG_DIR` – directory log (default `logs`)

Opzionali/consigliate:
- `LOG_LEVEL` – default `info`
- `QUERIES_CONTAINER` e `QUERIES_PREFIX` – per override SQL su Blob (fallback locale in `src/queries`)
- `DB_CONN_STRING` – connection string SQL Server (oppure usa `DB_HOST/DB_NAME/DB_USER/DB_PASS` con `dbConfigLoader`)

### Esempio DEV (`.env.local`)
```
LOG_LEVEL=debug
DB_MODE=mock
DEFAULT_TENANT_ID=tenant01
# Auth mock locale
AUTH_ISSUER=https://test-issuer/
AUTH_AUDIENCE=api://test
TENANT_CLAIM=ew_tenant_id
# Valorizza dopo aver eseguito `npm run dev:jwt`
# AUTH_TEST_JWKS={"keys":[{...}]}

# (opzionale) Branding locale / Azurite
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

## Modalità DB (Dual-Mode)

- `DB_MODE=mock`: persistenza locale a costo zero in `data/dev-users.json` (stesse API)
- `DB_MODE=sql`: Azure SQL usando `DB_CONN_STRING` oppure `DB_HOST/DB_NAME/DB_USER/DB_PASS` o `DB_AAD=true`

## Autenticazione locale (token dev)

- Esegui `npm run dev:jwt` per generare JWKS+token.
- Esporta `AUTH_TEST_JWKS` e usa il token come Bearer nelle chiamate o negli strumenti (VS Code REST, Postman).

### Checklist Bot (Agent-Ready)
- Da root repo: `pwsh ./scripts/checklist.ps1`
- Da cartella API: `npm run check:predeploy`
- Cosa verifica: env richieste (Auth/Branding), connessione SQL, accesso Storage (branding + queries), presenza e validità OpenAPI.
- Output: JSON + riepilogo umano; exit code != 0 se falliscono check critici.

## Variabili Pipeline (Azure DevOps) – Esempio
- Imposta in una Variable Group (es. `EasyWay-Secrets`) o direttamente nella pipeline:
  - `RESOURCE_GROUP_NAME=rg-easyway-dev`
  - `STORAGE_ACCOUNT_NAME=ewdlkdev123` (univoco a livello globale)
  - `TENANTS=["tenant01","tenant02"]` (lista JSON; anche una sola voce va tra [ ])
- Queste variabili sono usate nello stage `Infra` per eseguire `terraform plan/apply`.
- Ricorda di configurare anche le env dell’app (Auth/Storage/DB) nel Variable Group.

### Creazione/aggiornamento Variable Group via script
- File d’esempio variabili: `scripts/variables/easyway-secrets.sample.json`
- Script PowerShell: `scripts/ado-set-variable-group.ps1`
- Esempio:
```
pwsh ./scripts/ado-set-variable-group.ps1 \
  -OrgUrl https://dev.azure.com/contoso \
  -Project easyway \
  -Pat <ADO_PAT> \
  -GroupName EasyWay-Secrets \
  -VariablesJsonPath scripts/variables/easyway-secrets.sample.json \
  -SecretsKeys "AZURE_STORAGE_CONNECTION_STRING,DB_CONN_STRING"
```
Note:
- `SecretsKeys` marca come segrete le chiavi elencate (valori non saranno mostrati in ADO UI).
- Lo script crea o aggiorna il Variable Group se esiste già.
