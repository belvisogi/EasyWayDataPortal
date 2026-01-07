# Database (fonte unica)

Fonte corrente (unica): `db/flyway/sql/`.

## Provisioning
Wrapper (human-in-the-loop) per applicare Flyway:
- Validate: `pwsh db/provisioning/apply-flyway.ps1 -Action validate`
- Migrate: `pwsh db/provisioning/apply-flyway.ps1 -Action migrate`

## Storico / audit (non canonico)
Gli artefatti precedenti sono stati archiviati in:
- Snapshot/provisioning/programmability legacy: `old/db/DataBase_legacy/`
- Export `DDL_PORTAL_*`: `old/db/ddl_portal_exports/`

Nota: la cartella `DataBase/` e' stata rimossa per evitare ambiguita' e link rotti; usa questo file come entrypoint.
