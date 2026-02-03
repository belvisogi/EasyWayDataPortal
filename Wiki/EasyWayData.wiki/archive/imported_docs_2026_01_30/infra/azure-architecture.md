---
id: ew-archive-imported-docs-2026-01-30-infra-azure-architecture
title: EasyWay Data Portal — Note Architettura Azure (bozza)
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# EasyWay Data Portal — Note Architettura Azure (bozza)

Obiettivo: indicare i componenti Azure consigliati, configurazioni base e prerequisiti per esecuzione e governance dell’API e dei servizi correlati.

## Componenti principali
- Compute: Azure App Service (Linux), slot di staging, autoscaling.
- Database: Azure SQL Database (tier adeguato, backup/DR, AAD auth opzionale).
- Storage: Azure Blob Storage (override query SQL, asset branding, log export).
- Sicurezza segreti: Azure Key Vault (conn string DB, chiavi API, segreti).
- Configurazione: Azure App Configuration (feature flags/override, opzionale) o `PORTAL.CONFIGURATION` su DB.
- Observability: Application Insights (tracing, metriche, log), Log Analytics.
- Identità: Microsoft Entra ID / AD B2C per auth federata e gestione utenti (roadmap).
- DevOps: Azure Pipelines/GitHub Actions (build, test, deploy, var group, approvazioni).

## Configurazione applicativa
- Variabili ambiente minime:
  - `DB_CONN_STRING` oppure (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`)
  - `BLOB_CONN_STRING`/`BLOB_ACCOUNT` e container per override query/branding
  - `APPINSIGHTS_CONNECTION_STRING`
  - Feature flag: `ENABLE_BLOB_QUERY_OVERRIDE` (true/false)
- Gestione segreti: Key Vault + Managed Identity per l’App Service.
- Restrizioni rete: Accesso a SQL/Storage tramite Private Endpoint o IP whitelist; disattivare accesso pubblico quando possibile.

## Deployment e ambienti
- Ambienti: `dev` → `test` → `uat` → `prod` (slot/stage per ridurre downtime).
- Pipeline: build (tsc, lint, test), publish artefatti, deploy App Service, migrazioni DB (script DDL/SP versionati), smoke test post-deploy.

## Database & SP
- Fonte canonica (corrente): migrazioni Flyway in `db/flyway/sql/` (apply controllato in ambienti condivisi).
- Bootstrap dev/local: `db/provisioning/apply-flyway.ps1` (wrapper; applica Flyway con conferma).
- Archivio storico: `old/db/` (non canonico).
- Rilasciare le SP (produzione e `_DEBUG`) con logging su `PORTAL.STATS_EXECUTION_LOG`.
- Abilitare auditing e policy (RLS/masking) secondo i metadati in tabella.

## Logging e Tracing
- Application Insights: correlazione tramite header (`x-conversation-id`, `x-agent-id`), sampling, retention.
- Esportare log tecnici applicativi su Blob/Datalake secondo compliance.

## Sicurezza
- Autenticazione/Autorizzazione: integrazione Entra ID/AD B2C (roadmap).
- Rate limiting per tenant; validazioni input (Zod) già presenti.
- Hardening headers (helmet) e CORS policy per i domini noti.

## Roadmap infrastrutturale
1. Provisioning risorse (App Service, SQL, Storage, Key Vault, App Insights).
2. Managed Identity + Key Vault refs.
3. Pipeline CI/CD con ambienti.
4. Abilitazione override query via Blob (feature flag) e branding per tenant.
5. Integrazione Entra ID/AD B2C.


