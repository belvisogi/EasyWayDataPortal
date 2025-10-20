---
id: ew-blueprint-replicate
title: Blueprint – Replicare EasyWay Data Portal
summary: Guida passo‑passo per applicare lo stack EasyWay su un nuovo progetto
status: draft
owner: team-platform
tags: [blueprint, onboarding, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 400-700
  redaction: [email]
entities: []
---

Obiettivo
- Fornire una checklist ripetibile per clonare l’architettura EasyWay su un nuovo progetto: Infra (Terraform), API, Auth (Entra ID), Storage/Branding, CI/CD e test.

Prerequisiti
- Azure subscription + Resource Group
- Azure DevOps o GitHub Actions (esempi basati su ADO)
- Entra ID tenant (per app registration e JWT)
- Node.js 20+, Terraform >=1.6, PowerShell 7+

1) Provisioning Infra (Terraform)
- Percorso: `infra/terraform`
- Variabili: `resource_group_name`, `storage_account_name`, `tenants`, `project_name`.
- Crea: Storage ADLS Gen2 (HNS), filesystem `datalake` e `portal-assets`, directory `config/`, standard dirs per tenant.
- Output → env API:
  - `storage_connection_string` → `AZURE_STORAGE_CONNECTION_STRING`
  - `branding_container_name` → `BRANDING_CONTAINER` (tipicamente `portal-assets`)
  - `branding_prefix` → `BRANDING_PREFIX` (default `config`)
- Comandi:
```sql
cd infra/terraform
terraform init
terraform plan -var "project_name=<name>" -var "resource_group_name=<rg>" -var "storage_account_name=<sa>" -var "tenants=[\"tenant01\"]"
terraform apply
```sql

2) Auth (Entra ID) e Claim Tenant
- Registra un’app (app registration) “<project>-api”.
- Token configuration: aggiungi un claim applicativo per il tenant (es. `ew_tenant_id`).
- Raccogli:
  - `AUTH_ISSUER` = `https://login.microsoftonline.com/<TENANT_ID>/v2.0`
  - `AUTH_JWKS_URI` = `https://login.microsoftonline.com/<TENANT_ID>/discovery/v2.0/keys`
  - `AUTH_AUDIENCE` (se usi `aud`) = `api://<app-id>`
- Client: NON invia più `X-Tenant-Id`; il tenant è nel token.

3) Storage/Branding
- Carica in `portal-assets/config/` i file `branding.<tenantId>.yaml` (vedi esempio nel repo).
- In produzione preferisci Managed Identity:
  - `AZURE_STORAGE_ACCOUNT=<account>` + assegnazione RBAC “Storage Blob Data Reader”
  - O in alternativa `AZURE_STORAGE_CONNECTION_STRING`.

4) API – Config & Run
- Copia `EasyWay-DataPortal/easyway-portal-api/.env.example` in `.env.local` e compila:
  - Auth: `AUTH_ISSUER`, `AUTH_JWKS_URI`, `AUTH_AUDIENCE` (opz.), `TENANT_CLAIM=ew_tenant_id`
  - Storage: `AZURE_STORAGE_CONNECTION_STRING` o `AZURE_STORAGE_ACCOUNT`, `BRANDING_CONTAINER=portal-assets`, `BRANDING_PREFIX=config`
  - DB: `DB_CONN_STRING` (oppure `DB_AAD=true` + `DB_HOST`/`DB_NAME`)
- Avvio:
```sql
cd EasyWay-DataPortal/easyway-portal-api
npm ci
npm run dev
```sql

5) OpenAPI e Sicurezza
- Specifica aggiornata: `easyway-portal-api/openapi/openapi.yaml` con Bearer JWT e schemi reali.
- Hardening: vedi `security-and-observability.md` (helmet, CORS allowlist, rate-limit, body limit, correlation IDs).

6) CI/CD (Azure DevOps)
- Pipeline multi‑stage (`azure-pipelines.yml`):
  - Stage Infra: `terraform init/validate/plan/apply` (apply solo su main con approvazione).
  - Stage App: build/lint/test, publish artifacts.
  - Gate pre‑deploy: job "Pre-Deploy Checklist" che esegue il Checklist Bot e fallisce in caso di errori (pubblica l’output JSON come artifact).
  - Check variabili: prima del plan, la pipeline verifica la presenza delle variabili richieste (`RESOURCE_GROUP_NAME`, `STORAGE_ACCOUNT_NAME`, `TENANTS`) e fallisce con messaggio chiaro se mancanti (ricorda di collegare il Variable Group).

### Variabili Pipeline (ADO) – Esempio
- Variable Group (es. `EasyWay-Secrets`) o variabili di pipeline:
  - `RESOURCE_GROUP_NAME = rg-easyway-dev`
  - `STORAGE_ACCOUNT_NAME = ewdlkdev123` (nome storage univoco globale)
  - `TENANTS = ["tenant01","tenant02"]` (lista JSON; anche singolo tenant va tra [])
- Queste variabili alimentano i parametri Terraform nello stage `Infra`.

### Creare/aggiornare Variable Group via script (PowerShell)
- File esempio: `scripts/variables/easyway-secrets.sample.json` (modifica i valori e salva una copia per il tuo progetto)
- Script: `scripts/ado-set-variable-group.ps1`
- Esempio esecuzione:
```sql
pwsh ./scripts/ado-set-variable-group.ps1 \
  -OrgUrl https://dev.azure.com/contoso \
  -Project easyway \
  -Pat <ADO_PAT> \
  -GroupName EasyWay-Secrets \
  -VariablesJsonPath scripts/variables/easyway-secrets.sample.json \
  -SecretsKeys "AZURE_STORAGE_CONNECTION_STRING,DB_CONN_STRING"
```sql
- Lo script crea/aggiorna il Variable Group con tutte le chiavi; quelle elencate in `SecretsKeys` sono marcate come segrete.
- Variable Group: imposta `AZURE_STORAGE_CONNECTION_STRING` (o MI), `BRANDING_CONTAINER`, `BRANDING_PREFIX`, `AUTH_*`, DB.

7) Test
- REST Client: usa i file in `tests/api/rest-client/*` impostando `@token` con un JWT valido.
- Jest: esegui `npm test` (test protetti → 401 senza token per health).

8) Checklist Bot (Agent‑Ready)
- Verifica automatica pre‑deploy: `pwsh ./scripts/checklist.ps1` (root) oppure `npm run check:predeploy` (API).
- Controlli: env (Auth/Branding), connessione SQL, accesso Storage (branding/queries), OpenAPI valido.
- Output machine‑readable (JSON) per gli agent e integrazione CI.

Checklist finale
- [ ] Terraform apply completato e output mappati alle env
- [ ] App registration con claim tenant funzionante
- [ ] File branding caricati in `portal-assets/config/`
- [ ] `.env.local` aggiornato e API avviata correttamente
- [ ] OpenAPI allineata, sicurezza Bearer documentata
- [ ] Pipeline con Variable Group impostato
- [ ] Smoke test REST/Jest passano (401 atteso senza token)
