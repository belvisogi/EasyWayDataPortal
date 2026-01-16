---
id: ew-db-portal-tables-index
title: db-portal-tables-index
summary: Blueprint/catalogo delle tabelle nello schema PORTAL (derivato da Flyway). Ogni tabella ha una pagina dedicata con scopo, campi logici/fisici e policy (tenanting/PII/RLS).
status: draft
owner: team-data
tags: [domain/db, layer/index, audience/dev, audience/dba, audience/non-expert, privacy/internal, language/it, blueprint]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Completare descrizioni colonne e policy (PII/RLS) per tutte le tabelle.
---

# PORTAL — Tables (Blueprint)

- Nota per autori: per nuove pagine usare `./_template.md`.


## Contesto
- Source-of-truth DB (fisico): migrazioni Flyway in `db/flyway/sql/`.
- Inventario (rigenerabile): `easyway-webapp/01_database_architecture/ddl-inventory.md`.
- Queste pagine sono la “vista logica” (data dictionary): scopo, descrizioni, PII, tenanting, regole.

## Tabelle (canoniche da Flyway)
- [`PORTAL.CONFIGURATION`](./portal-configuration.md)
- [`PORTAL.LOG_AUDIT`](./portal-log-audit.md)
- [`PORTAL.MASKING_METADATA`](./portal-masking-metadata.md)
- [`PORTAL.PROFILE_DOMAINS`](./portal-profile-domains.md)
- [`PORTAL.RLS_METADATA`](./portal-rls-metadata.md)
- [`PORTAL.SECTION_ACCESS`](./portal-section-access.md)
- [`PORTAL.STATS_EXECUTION_LOG`](./portal-stats-execution-log.md)
- [`PORTAL.STATS_EXECUTION_TABLE_LOG`](./portal-stats-execution-table-log.md)
- [`PORTAL.SUBSCRIPTION`](./portal-subscription.md)
- [`PORTAL.TENANT`](./portal-tenant.md)
- [`PORTAL.USER_NOTIFICATION_SETTINGS`](./portal-user-notification-settings.md)
- [`PORTAL.USERS`](./portal-users.md)


## Domande a cui risponde
- Che cosa raccoglie questo indice?
- Dove sono i documenti principali collegati?
- Come verificare naming e ancore per questa cartella?
- Dove trovare entità e guide correlate?


