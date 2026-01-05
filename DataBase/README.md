# DataBase/ (DB source-of-truth)

Questa cartella contiene gli artefatti SQL del database EasyWayDataPortal.

## Regola (razionalizzazione)
- **DDL canonico (singolo file)**: `DataBase/DDL_EASYWAY_DATAPORTAL.sql`
  - Usalo come riferimento principale per “cosa è il DB” (schema + tabelle + vincoli + metadati).
- **Provisioning (bootstrap Azure SQL)**: `DataBase/provisioning/`
  - Script numerati, idempotenti, pensati per setup dev/local (es. `00_schema.sql`, `10_tables.sql`, …).
  - Deve rimanere coerente col DDL canonico.
- **Deploy/migrazioni**: `db/flyway/`
  - È il posto giusto per cambiamenti incrementali e apply controllato in ambienti condivisi.

## File legacy / export (da migrare o deprecare)
Alcuni file `DDL_PORTAL_*` possono essere export/storici e non sempre sono allineati al DDL canonico.
Finché esistono, vanno trattati come **inventory/legacy** (non come fonte primaria).

## Programmability/
`DataBase/programmability/` contiene placeholder `.gitkeep` per organizzare future SP/FN/VW/Tables se si decide di separare gli artefatti per tipo.

