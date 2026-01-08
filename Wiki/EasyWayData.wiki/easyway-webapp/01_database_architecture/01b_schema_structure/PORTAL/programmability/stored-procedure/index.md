---
id: ew-portal-stored-procedure-index
title: portal-stored-procedure-index
summary: Indice operativo delle stored procedure PORTAL documentate (firma, esempi, logging, idempotenza).
status: active
owner: team-data
created: '2025-01-01'
updated: '2026-01-05'
tags: [artifact-stored-procedure, domain/db, layer/index, audience/dba, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
next: Aggiornare quando cambia l’elenco SP o la documentazione associata.
---

# Indice

Breadcrumb: Home / EasyWay WebApp / Database Architecture / PORTAL / Stored Procedure

- [configuration.md](./configuration.md) - `sp_insert_configuration`
- [profile-domains.md](./profile-domains.md) - `sp_insert_profile_domain`
- [section-access.md](./section-access.md) - `sp_insert_section_access`
- [stats-execution-log.md](./stats-execution-log.md) - `sp_log_stats_execution` (logging esecuzioni)
- [subscription.md](./subscription.md) - `sp_insert_subscription`
- [tenant.md](./tenant.md) - `sp_insert_tenant`
- [user-notification-settings.md](./user-notification-settings.md) - `sp_insert_user_notification_settings`
- [users.md](./users.md) - `sp_insert_user`, `sp_update_user`, `sp_delete_user`, `sp_list_users_by_tenant`

## Domande a cui risponde
- Quali stored procedure sono documentate per lo schema PORTAL e dove sono?
- Dove trovare firma, input/output ed esempi di invocazione per ogni SP?
- Quali SP gestiscono logging/audit e come validare il loro output?
- Qual è il link canonico da usare quando referenzio una SP in altre pagine?
