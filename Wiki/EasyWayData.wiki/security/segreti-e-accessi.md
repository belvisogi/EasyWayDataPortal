---
title: Segreti e accessi (DB + Datalake)
tags: [domain/security, layer/reference, audience/ops, audience/dba, privacy/internal, language/it, keyvault, db, datalake]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-security-segreti-accessi
chunk_hint: 200-300
entities: []
include: true
summary: Linee guida canoniche per gestione segreti e accessi tecnici in EasyWay DataPortal (dev/ci/prod).
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000---

[[start-here|Home]] > [[Domain - Security|Security]] > [[Layer - Reference|Reference]]

# Segreti e accessi (DB + Datalake)

## Contesto (repo)
- Obiettivo: centralizzare credenziali tecniche e accessi in modo sicuro e auditabile.
- Source of truth: Azure Key Vault (valori dei segreti).
- Registry non-segreto (metadati): tabelle/elenchi in questa pagina (niente valori).
- Entrypoint agentico: `scripts/ewctl.ps1`
- Log eventi: `agents/logs/events.jsonl`
- KB: `agents/kb/recipes.jsonl`
- Goals: `agents/goals.json`

## Principi base (non negoziabili)
- Nessun segreto nel repo.
- Key Vault come **source of truth**.
- Accesso via Managed Identity (prod) o Service Principal (dev/CI).
- Logging e audit sempre attivi.
- Rotazione periodica e revoca rapida.

## Flusso per ambiente

### Dev (locale)
- Segreti in `.env.local` solo temporanei e mai committati.
- Per test, preferire credenziali di servizio a basso privilegio.

### CI/CD
- Variable Group protetto (ADO) con reference a Key Vault.
- Nessun segreto hardcoded in YAML.
- Accesso solo a secret necessari (least privilege).

### Prod
- Managed Identity per App Service/Functions.
- Segreti letti runtime da Key Vault (o App Config con reference).
- Accesso auditato e rotazione obbligatoria.

## Dove salvare i segreti

### Key Vault (valori segreti)
Esempi naming (consigliato):
- `db--portal--connstring`
- `db--portal--admin-connstring`
- `datalake--portal--sp-client-secret`
- `datalake--portal--sas`

### Registry metadati (non segreti)
Manteniamo una tabella con:
- `secret_name`
- `owner`
- `scope` (dev/ci/prod)
- `rotation_days`
- `notes/runbook`

### Registry accessi (censimento per audit)
Tabella minima per audit (non contiene valori segreti). Template consigliati:
- CSV: `docs/agentic/templates/sheets/access-registry.csv`
- Excel: `docs/agentic/templates/sheets/access-registry.template.xlsx`

| access_id | system | resource | identity_type | identity_name | scope | permissions | secret_ref | owner | rotation_days | last_rotation | expiry_date | justification | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| acc-001 | db | portal-sql | managed_identity | mi-portal-api | prod | read/write | db--portal--connstring | team-platform | 90 | 2025-01-01 | 2025-12-31 | runtime access | accesso runtime API |
| acc-002 | datalake | portal-assets | service_principal | spn-portal-ci | ci | write | datalake--portal--sp-client-secret | team-devops | 90 | 2025-01-01 | 2025-12-31 | pipeline upload | upload artifact |

## Recupero rapido da Key Vault

### CLI (az)
```powershell
az keyvault secret show --vault-name <kv-name> --name <secret-name> --query value -o tsv
```sql

### PowerShell (modulo Az)
```powershell
Get-AzKeyVaultSecret -VaultName <kv-name> -Name <secret-name> -AsPlainText
```sql

### App Settings via Key Vault reference
```text
@Microsoft.KeyVault(SecretUri=https://<kv-name>.vault.azure.net/secrets/<secret-name>/<version>)
```sql

## Owner e mantenimento
- Owner censimento accessi: `agent_governance` (audit/compliance).
- Contributi tecnici: `agent_dba` (DB), `agent_datalake` (Datalake).

## Note su password generate (DB)
- `agent_dba` puo' generare/ruotare credenziali (`db-user:create`, `db-user:rotate`).
- **Il valore deve essere salvato in Key Vault**, non in file locali.
- Nel repo si salva solo il riferimento al secret (nome).

## Come rigenerare i template (idempotente)
```powershell
pwsh scripts/access-registry-template-xlsx.ps1
```sql

## Riferimenti
- `docs/ci/azure-devops-secrets.md`
- `Wiki/EasyWayData.wiki/deploy-app-service.md`
- `Wiki/EasyWayData.wiki/easyway-webapp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md`


## Vedi anche

- [Operativita governance-driven - provisioning accessi (DB/Datalake)](./operativita-governance-provisioning-accessi.md)
- [Agent Security (IAM/KeyVault) - overview](./agent-security-iam.md)
- [Segregation Model (Dev vs Knowledge vs Runtime)](../control-plane/segregation-model-dev-knowledge-runtime.md)
- [Policy di Configurazione & Sicurezza – Microservizi e API Gateway](../easyway-webapp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md)
- [IAM Provision Access (WHAT)](../orchestrations/iam-provision-access.md)




