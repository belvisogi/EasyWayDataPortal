---
id: ew-entities-index
title: Entities Index
summary: Indice delle entità dichiarate in entities.yaml, raggruppate per categoria.
status: draft
owner: team-docs
tags: [domain/docs, layer/index, audience/dev, privacy/internal, language/it, catalog]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
---
# Entities Index

## Endpoints

| id | name | kind | link |
|---|---|---|---|
| api-config | GET /api-config | endpoint | [./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-001-get-api-config.md](./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-001-get-api-config.md) |
| api-branding | GET /api-branding | endpoint | [./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-002-get-api-branding.md](./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-002-get-api-branding.md) |
| api-users | CRUD /api/users | endpoint | [./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-003-get-crud-api-users.md](./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-003-get-crud-api-users.md) |

## DB Stored Procedures

| id | name | kind | link |
|---|---|---|---|
| sp-portal-configuration | PORTAL.stored-procedure.configuration | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/configuration.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/configuration.md) |
| sp-portal-profile-domains | PORTAL.stored-procedure.profile-domains | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/profile-domains.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/profile-domains.md) |
| sp-portal-section-access | PORTAL.stored-procedure.section-access | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/section-access.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/section-access.md) |
| sp-portal-stats-execution-log | PORTAL.stored-procedure.stats-execution-log | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md) |
| sp-portal-subscription | PORTAL.stored-procedure.subscription | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/subscription.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/subscription.md) |
| sp-portal-tenant | PORTAL.stored-procedure.tenant | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/tenant.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/tenant.md) |
| sp-portal-user-notification-settings | PORTAL.stored-procedure.user-notification-settings | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/user-notification-settings.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/user-notification-settings.md) |
| sp-portal-users | PORTAL.stored-procedure.users | stored-procedure | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/users.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/users.md) |

## DB Sequences

| id | name | kind | link |
|---|---|---|---|
| seq-portal | SEQUENCE (PORTAL) | sequence | [./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/sequence.md](./easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/sequence.md) |

## Policies

| id | name | kind | link |
|---|---|---|---|
| policy-api-store-procedure | Policy API ↔ Store Procedure | policy | [./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/policy-api-store-procedure-easyway-data-portal.md](./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/policy-api-store-procedure-easyway-data-portal.md) |
| policy-logging-sensitive | Gestione Log & Dati Sensibili | policy | [./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/gestione-log-and-policy-dati-sensibili.md](./easyway-webapp/05_codice_easyway_portale/easyway_portal_api/gestione-log-and-policy-dati-sensibili.md) |
| policy-microservices-gateway | Policy di Configurazione & Sicurezza — Microservizi e API Gateway | policy | [./easyway-webapp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md](./easyway-webapp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md) |

## Flows

| id | name | kind | link |
|---|---|---|---|
| flow-login-onboarding | Login & Onboarding | flow | [./easyway-webapp/02_logiche_easyway/login-flussi-onboarding.md](./easyway-webapp/02_logiche_easyway/login-flussi-onboarding.md) |
| flow-notifiche | Notifiche – Gestione | flow | [./easyway-webapp/02_logiche_easyway/notifiche-gestione.md](./easyway-webapp/02_logiche_easyway/notifiche-gestione.md) |
| flow-external-apis | API Esterne – Integrazione | flow | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione.md) |

## Data

| id | name | kind | link |
|---|---|---|---|
| datalake-naming-standard | Standard Accesso Storage e Datalake (IAM & Naming) | standard | [./easyway-webapp/03_datalake_dev/easyway-dataportal-standard-accesso-storage-e-datalake-iam-and-naming.md](./easyway-webapp/03_datalake_dev/easyway-dataportal-standard-accesso-storage-e-datalake-iam-and-naming.md) |

## Standards

| id | name | kind | link |
|---|---|---|---|
| std-rest-naming | Convenzioni REST e naming | standard | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/convenzioni-rest-e-naming.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/convenzioni-rest-e-naming.md) |
| std-best-practice-naming | Best Practice Naming & Scalabilità | standard | [./easyway-webapp/02_logiche_easyway/best-practice-naming-and-scalability.md](./easyway-webapp/02_logiche_easyway/best-practice-naming-and-scalability.md) |

## Guides

| id | name | kind | link |
|---|---|---|---|
| guide-logging-audit | Logging & Audit | guide | [./easyway-webapp/02_logiche_easyway/logging-and-audit.md](./easyway-webapp/02_logiche_easyway/logging-and-audit.md) |
| guide-api-onboarding | API – Onboarding | guide | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/api-onboarding.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/api-onboarding.md) |
| guide-api-notifiche | API – Notifiche | guide | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/api-notifiche.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/api-notifiche.md) |
| guide-api-invio-notifica | API – Invio Notifica | guide | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/api-invio-notifica.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/api-invio-notifica.md) |
| guide-api-checklist-test | Checklist di test API | guide | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md) |
| guide-integrazione-shopify | Esempio – Integrazione Shopify | guide | [./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/esempio-integrazione-shopify.md](./easyway-webapp/02_logiche_easyway/api-esterne-integrazione/esempio-integrazione-shopify.md) |

## Domande a cui risponde
- Dove trovo l'elenco delle entità e i link rapidi?
- Quali categorie di entità sono coperte?
- Come navigo verso documenti specifici partendo dall'indice?








