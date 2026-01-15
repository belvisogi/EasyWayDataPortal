# OLD/DB (Quarantena DB)

Artefatti DB deprecati, snapshot, export temporanei.

---

## ⚠️ DDL Archiviati

**Directory**: `_ARCHIVED_DDL/`

Contiene DDL legacy **OBSOLETI**:
- `DataBase_legacy/` - Snapshot storico provisioning
- `ddl_portal_exports/` - Export monolitici DDL

### ❌ NON USARE QUESTI FILE

**Fonte di verità UNICA**: `../../db/flyway/sql/`

Tutti i DDL, stored procedures e migrazioni devono usare **solo** Flyway migrations.

Vedere `_ARCHIVED_DDL/README.md` per:
- Mapping completo legacy → Flyway
- Data archiviazione e motivazione
- Link alla documentazione canonica

---

## Altri Contenuti

Questa directory contiene anche:
- `backups/` - Backup temporanei di file modificati
- `artifacts/` - Artefatti generati temporanei
- `wiki-loose/` - File Wiki spostati
- `duplicates/` - File duplicati

Consultare `INDEX.md` per inventario completo.
