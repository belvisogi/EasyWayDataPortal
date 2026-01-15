# ⚠️ DDL ARCHIVIATI - NON USARE

> **ATTENZIONE**: Questi file DDL sono **OBSOLETI** e mantenuti solo per riferimento storico.

---

## ❌ NON UTILIZZARE MAI QUESTI FILE

**Fonte di verità UNICA**: `db/flyway/sql/`

Tutti i DDL, stored procedures, migrazioni e seed data **devono** usare solo le Flyway migrations canoniche.

---

## 📅 Quando Deprecati

- **Data archiviazione**: 14 Gennaio 2026
- **Motivazione**: Consolidamento su Flyway migrations come single source of truth
- **Versione Flyway**: V1-V11 + V100-V101 (agent chat)

---

## 🗺️ Mapping Legacy → Flyway

| File Legacy | Flyway Equivalente | Note |
|-------------|-------------------|------|
| `DataBase_legacy/provisioning/00_schema.sql` | `V1__create_schemas.sql` | Schema PORTAL, CONTROL, ARGOS |
| `DataBase_legacy/provisioning/10_tables.sql` | `V3__portal_core_tables.sql` + `V3_1__portal_more_tables.sql` | Tabelle principali |
| `DataBase_legacy/provisioning/20_fk_indexes.sql` | Inclusi in V3/V3_1 | Foreign keys e indici |
| `DataBase_legacy/provisioning/30_seed_minimal.sql` | `V7__seed_minimum.sql` | Seed data iniziali |
| `DataBase_legacy/provisioning/40_extended_properties.sql` | `V8__extended_properties.sql` | Documentazione DB |
| `DataBase_legacy/programmability/sp/*.sql` | `V6__stored_procedures_core.sql` + `V9__stored_procedures_users_config_acl.sql` | Tutte le SP |
| `ddl_portal_exports/DDL_PORTAL_TABLE_*.sql` | V3 + V3_1 + V4 | Export monolitico tabelle |
| `ddl_portal_exports/DDL_PORTAL_STOREPROCES_*.sql` | V6 + V9 + V11 + V101 | Export monolitico SP |
| `ddl_portal_exports/DDL_STATLOG_STOREPROCES_*.sql` | `V4__portal_logging_tables.sql` | Logging/audit |

---

## 🚫 Perché NON usare questi file

1. **Schema Drift**: Potrebbero non riflettere lo stato attuale del DB
2. **Nomi Colonne Obsoleti**: Es. `display_name` vs `name/surname`
3. **SP Deprecate**: Alcune procedure non più utilizzate
4. **Manutenibilità**: Modifiche future vanno solo in Flyway
5. **Audit**: Flyway traccia ogni migrazione con versioning

---

## 📖 Se hai bisogno di questi file

**Caso 1: Migrazione da setup legacy**
- Consulta il team per assistenza nella migrazione a Flyway
- Usa `db/flyway/sql/` come riferimento per lo schema attuale

**Caso 2: Riferimento storico**
- OK per consultazione, ma NON copiare/incollare
- Verifica sempre equivalenza in Flyway

**Caso 3: Documentazione**
- Preferisci Wiki: `Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/`
- DDL generato automaticamente da Flyway: `npm run db:generate-docs`

---

## 🔗 Link Utili

- **Flyway Migrations**: `db/flyway/sql/`
- **DB README**: `db/README.md`
- **Wiki DB Architecture**: `Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/`
- **Stored Procedures Guide**: `Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/01b_schema_structure/PORTAL/programmability/stored-procedure.md`

---

**Per domande o supporto**: Apri una issue o consulta la Wiki.

*Archiviato: 2026-01-14*
