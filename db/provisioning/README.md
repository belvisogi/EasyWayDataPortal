# Provisioning DB (dev/local) - Wrapper Flyway

Fonte canonica: `db/flyway/sql/`.

Comandi:
- Validate (default): `pwsh db/provisioning/apply-flyway.ps1 -Action validate`
- Migrate (richiede conferma): `pwsh db/provisioning/apply-flyway.ps1 -Action migrate`
- Baseline (solo DB già esistenti, richiede conferma): `pwsh db/provisioning/apply-flyway.ps1 -Action baseline -BaselineVersion 1`

Nota: non usare script SQL “a mano” come provisioning: la storia è mantenuta in Flyway.
