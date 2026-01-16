---
id: ew-db-best-practices
title: Database Best Practices – Checklist (EasyWay)
summary: Tabella di controllo rapida per governance, sicurezza e DevOps
status: active
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

Obiettivo
- Fornire una checklist operativa e agent‑friendly per verificare che il DB sia conforme alle linee guida EasyWay.

Checklist (alto livello)
| Area | Regola | Stato | Note |
| --- | --- | --- | --- |
| Schemi | Esistono gli schemi PORTAL/BRONZE/SILVER/GOLD/REPORTING/WORK | ⬜ | V1 create_schemas |
| Sequence | Sequence NDG create (TEN/USER + DEBUG) | ⬜ | V2 core_sequences |
| Tabelle core | TENANT/USERS/CONFIGURATION con colonne standard | ⬜ | V3 portal_core_tables |
| Logging | LOG_AUDIT, STATS_EXECUTION_LOG, STATS_EXECUTION_TABLE_LOG | ⬜ | V4 logging_tables |
| RLS | Funzione predicate + Security Policy (OFF/ON) | ⬜ | V5 rls_setup |
| SP core | CRUD TENANT, DEBUG register tenant+user, notify stub | ⬜ | V6 stored_procedures_core |
| Seed | Profili/parametri base inseriti | ⬜ | V7 seed_minimum |
| Extended props | Descrizioni/PII via extended properties | ⬜ | V8 extended_properties |
| Flyway | `flyway_schema_history` allineata su tutti gli ambienti | ⬜ | Pipeline CI/CD |
| Drift gate | Gate “DB Drift Check” in pipeline attivo | ⬜ | drift.json artifact |

Checklist (tabelle)
| Tabella | PK (id) | tenant_id | created_by | created_at | updated_at | status | ext_attributes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PORTAL.TENANT | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| PORTAL.USERS | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| PORTAL.CONFIGURATION | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| ... | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

Checklist (SP)
| SP | TRY/CATCH + TRAN | Logging `sp_log_stats_execution` | Output standard (status/rows/err) | Debug version (se prevista) |
| --- | --- | --- | --- | --- |
| PORTAL.sp_insert_tenant | ⬜ | ⬜ | ⬜ | ⬜ |
| PORTAL.sp_update_tenant | ⬜ | ⬜ | ⬜ | ⬜ |
| PORTAL.sp_delete_tenant | ⬜ | ⬜ | ⬜ | ⬜ |
| PORTAL.sp_debug_register_tenant_and_user | ⬜ | ⬜ | ⬜ | ⬜ |
| ... | ⬜ | ⬜ | ⬜ | ⬜ |

Note operative
- RLS: abilita la security policy solo dopo aver verificato che l’app imposti `SESSION_CONTEXT('tenant_id')` (vedi `withTenantContext`).
- Migrazioni: 1 file = 1 scopo; commento/header con scopo e ticket.
- Documentazione: genera/aggiorna ERD & SP Catalog con `npm run db:generate-docs` dopo modifiche strutturali.






