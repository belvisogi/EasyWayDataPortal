# Archivio DB (legacy)

Fonte corrente (unica): `db/flyway/sql/`.

Questa cartella contiene artefatti DB storici spostati da `DataBase/` per preservare audit e ricostruibilità:
- `old/db/DataBase_legacy/` (snapshot/provisioning/programmability storici)
- `old/db/ddl_portal_exports/` (export `DDL_PORTAL_*`)

Nota: questi file non sono source-of-truth e non devono essere usati per generare inventario canonico.

