# DB Provisioning (dev/local) via Flyway

## Fonte canonica
- La fonte corrente del DB è `db/flyway/sql/` (migrazioni incrementali).
- Questa cartella fornisce un wrapper per applicare Flyway in dev/local (human-in-the-loop).

## Wrapper (sicuro)
- Validate (default): `pwsh db/provisioning/apply-flyway.ps1 -Action validate`
- Migrate (richiede conferma): `pwsh db/provisioning/apply-flyway.ps1 -Action migrate`
- Baseline (solo DB già esistenti, richiede conferma): `pwsh db/provisioning/apply-flyway.ps1 -Action baseline -BaselineVersion 1`

Parametri: usa `-Url/-User/-Password` oppure le env `FLYWAY_URL/FLYWAY_USER/FLYWAY_PASSWORD`.

## File SQL legacy (da deprecare)
I file `00_schema.sql` ... `50_sp_debug_register_tenant_and_user.sql` sono mantenuti solo per storico/audit e possono divergere da Flyway.
Non sono più il percorso consigliato per provisioning locale.
