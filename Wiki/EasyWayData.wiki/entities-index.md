---
id: ew-entities-index
title: Entities Index
summary: Indice delle entità dichiarate in entities.yaml, raggruppate per categoria.
status: draft
owner: team-docs
tags:
  - catalog
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
entities: []
---
# Entities Index

## Endpoints

| id | name | kind | link |
|---|---|---|---|
| api-config | GET /api-config | endpoint | [./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-001-get-api-config.md](./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-001-get-api-config.md) |
| api-branding | GET /api-branding | endpoint | [./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-002-get-api-branding.md](./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-002-get-api-branding.md) |
| api-users | CRUD /api/users | endpoint | [./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-003-get-crud-api-users.md](./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/endp-003-get-crud-api-users.md) |

## DB Stored Procedures

| id | name | kind | link |
|---|---|---|---|
| sp-portal-configuration | PORTAL.stored-procedure.configuration | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/configuration.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/configuration.md) |
| sp-portal-profile-domains | PORTAL.stored-procedure.profile-domains | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/profile-domains.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/profile-domains.md) |
| sp-portal-section-access | PORTAL.stored-procedure.section-access | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/section-access.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/section-access.md) |
| sp-portal-stats-execution-log | PORTAL.stored-procedure.stats-execution-log | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/stats-execution-log.md) |
| sp-portal-subscription | PORTAL.stored-procedure.subscription | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/subscription.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/subscription.md) |
| sp-portal-tenant | PORTAL.stored-procedure.tenant | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/tenant.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/tenant.md) |
| sp-portal-user-notification-settings | PORTAL.stored-procedure.user-notification-settings | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/user-notification-settings.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/user-notification-settings.md) |
| sp-portal-users | PORTAL.stored-procedure.users | stored-procedure | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/users.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure/users.md) |

## DB Sequences

| id | name | kind | link |
|---|---|---|---|
| seq-portal | SEQUENCE (PORTAL) | sequence | [./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/sequence.md](./EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL/programmability/sequence.md) |

## Policies

| id | name | kind | link |
|---|---|---|---|
| policy-api-store-procedure | Policy API ↔ Store Procedure | policy | [./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/policy-api-store-procedure-easyway-data-portal.md](./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/policy-api-store-procedure-easyway-data-portal.md) |
| policy-logging-sensitive | Gestione Log & Dati Sensibili | policy | [./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/gestione-log-and-policy-dati-sensibili.md](./EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/gestione-log-and-policy-dati-sensibili.md) |
| policy-microservices-gateway | Policy di Configurazione & Sicurezza — Microservizi e API Gateway | policy | [./EasyWay_WebApp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md](./EasyWay_WebApp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md) |

## Flows

| id | name | kind | link |
|---|---|---|---|
| flow-login-onboarding | Login & Onboarding | flow | [./EasyWay_WebApp/02_logiche_easyway/login-flussi-onboarding.md](./EasyWay_WebApp/02_logiche_easyway/login-flussi-onboarding.md) |
| flow-notifiche | Notifiche – Gestione | flow | [./EasyWay_WebApp/02_logiche_easyway/notifiche-gestione.md](./EasyWay_WebApp/02_logiche_easyway/notifiche-gestione.md) |
| flow-external-apis | API Esterne – Integrazione | flow | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione.md) |

## Data

| id | name | kind | link |
|---|---|---|---|
| datalake-naming-standard | Standard Accesso Storage e Datalake (IAM & Naming) | standard | [./EasyWay_WebApp/03_datalake_dev/easyway-dataportal-standard-accesso-storage-e-datalake-iam-and-naming.md](./EasyWay_WebApp/03_datalake_dev/easyway-dataportal-standard-accesso-storage-e-datalake-iam-and-naming.md) |

## Standards

| id | name | kind | link |
|---|---|---|---|
| std-rest-naming | Convenzioni REST e naming | standard | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/convenzioni-rest-e-naming.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/convenzioni-rest-e-naming.md) |
| std-best-practice-naming | Best Practice Naming & Scalabilità | standard | [./EasyWay_WebApp/02_logiche_easyway/best-practice-naming-and-scalability.md](./EasyWay_WebApp/02_logiche_easyway/best-practice-naming-and-scalability.md) |

## Guides

| id | name | kind | link |
|---|---|---|---|
| guide-logging-audit | Logging & Audit | guide | [./EasyWay_WebApp/02_logiche_easyway/logging-and-audit.md](./EasyWay_WebApp/02_logiche_easyway/logging-and-audit.md) |
| guide-api-onboarding | API – Onboarding | guide | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/api-onboarding.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/api-onboarding.md) |
| guide-api-notifiche | API – Notifiche | guide | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/api-notifiche.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/api-notifiche.md) |
| guide-api-invio-notifica | API – Invio Notifica | guide | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/api-invio-notifica.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/api-invio-notifica.md) |
| guide-api-checklist-test | Checklist di test API | guide | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md) |
| guide-integrazione-shopify | Esempio – Integrazione Shopify | guide | [./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/esempio-integrazione-shopify.md](./EasyWay_WebApp/02_logiche_easyway/api-esterne-integrazione/esempio-integrazione-shopify.md) |

## Domande a cui risponde
- Dove trovo l'elenco delle entità e i link rapidi?
- Quali categorie di entità sono coperte?
- Come navigo verso documenti specifici partendo dall'indice?


