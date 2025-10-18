# DB Provisioning (Azure SQL Server)

- Order of execution:
  - `00_schema.sql`
  - `10_tables.sql`
  - `20_fk_indexes.sql`
  - `30_seed_minimal.sql`
  - `40_extended_properties.sql`

- All scripts are idempotent and safe to re-run.
- Types mapped for Azure SQL: `bit` used instead of `boolean`.

