---
id: ew-db-storeprocess
title: Store Procedure – Standard e catalogo (overview)
summary: Struttura TRY/CATCH + TRAN, logging e output uniformato
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
---

Standard SP
- Parametri chiari (in/out), `@created_by` obbligatorio
- Transazione + TRY/CATCH
- Logging: `PORTAL.sp_log_stats_execution` (+ `sp_log_stats_table` ove utile)
- Output JSON‑friendly: `status`, `id/code`, `error_message`, `rows_*`
- Versione `sp_debug_*` per ambienti test

Categorie principali
- Setup/Utility, Tenant, Users, ACL/Profile Domains, Section Access, Config/Subscription, Notifications, Audit/Masking/RLS, Stats/Monitoring, Debug/Diagnostics

Prossimi passi
- Migrazioni dedicate per SP core e versioni debug

