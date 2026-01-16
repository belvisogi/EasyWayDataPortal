---
id: ew-db-flyway
title: Flyway - DevOps per il Database (EasyWay)
summary: Strumento migration-based per portare DDL/SP/sequence/RLS in un flusso maturo e ripetibile
status: active
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-07'
next: TODO - definire next step.
---

## Contesto
- Source-of-truth DB (canonico): migrazioni Flyway in `db/flyway/sql/`.
- Provisioning dev/local: wrapper `db/provisioning/apply-flyway.ps1` (human-in-the-loop).
- Artefatti storici (non canonici): `old/db/` (ex `DataBase/`, export `DDL_PORTAL_*`).

Cos'è Flyway
- Tool open-source (Redgate) per versionare ed applicare migrazioni DB (DDL, DML, funzioni, SP, RLS.).
- Tiene uno storico (tabella `flyway_schema_history`) e applica solo le nuove versioni.
- Si integra perfettamente con CI/CD e ChatOps (audit nativo + query di stato).

Come funziona
- Crea `flyway_schema_history` nel DB e registra: versione, checksum, autore, timestamp, esito.
- Legge script in ordine dalla cartella configurata (es. `db/flyway/sql/`):
```text
db/flyway/sql/
├─ V1__create_schemas.sql
├─ V2__core_sequences.sql
├─ V3__portal_core_tables.sql
├─ V4__portal_logging_tables.sql
├─ V5__rls_and_masking.sql
└─ V6__stored_procedures_core.sql
```
- Esegue solo le migrazioni non ancora registrate; in caso di errore, si ferma e fallisce la pipeline.

Naming (Flyway Standard)
- Versioned: `V<n>__descrizione.sql`
- Undo (opzionale): `U<n>__rollback.sql`
- Repeatable: `R__nome.sql` (ri-eseguito se cambia file)
- Baseline (per DB già esistenti): `B<n>__baseline.sql` o `flyway baseline`

Best practice EasyWay
- 1 script = 1 scopo (tabella, SP, sequence, RLS.)
- Commento/header standard a inizio file (progetto, autore, scopo, ticket)
- Rollback: dove possibile aggiungere `U__rollback_*.sql`
- Logging: audit Flyway + nostre tabelle `PORTAL.LOG_AUDIT` e `PORTAL.STATS_EXECUTION_*`
- Pipeline: integrazione Azure DevOps (plan/apply gating) e variabili segrete in Variable Group/Key Vault

Integrazione EasyWay
- Cartella migrazioni: `db/flyway/sql/`
- Config: `db/flyway/flyway.conf` (locations, baselineOnMigrate, ecc.)
- Esempio `flyway.conf` (DEV):
```text
locations=filesystem:./sql
baselineOnMigrate=true
sqlMigrationSuffixes=.sql
connectRetries=5
# Le credenziali (URL/USER/PASSWORD) si passano come env nel runner
```

Esecuzione (CLI)
```powershell
# Env (esempio SQL Auth)
$env:FLYWAY_URL = 'jdbc:sqlserver://<host>:1433;databaseName=<db>;encrypt=true'
$env:FLYWAY_USER = '<user>'
$env:FLYWAY_PASSWORD = '<password>'

flyway -configFiles=db/flyway/flyway.conf validate
flyway -configFiles=db/flyway/flyway.conf baseline -baselineVersion=1   # solo su DB esistenti
flyway -configFiles=db/flyway/flyway.conf migrate
```

Installazione locale (Windows, ZIP)
- Scarica Flyway Community (zip) e estrai, es. `C:\Tools\flyway\`.
- Esegui con path completo se non in PATH:
```powershell
$flywayExe = 'C:\Tools\flyway\flyway-10.20.0\flyway.cmd'
& $flywayExe "-configFiles=db/flyway/flyway.conf" validate
& $flywayExe "-configFiles=db/flyway/flyway.conf" migrate
```
- Se `flyway.conf` non ha URL/USER/PASSWORD, Flyway fallisce: impostare le env sopra.

## Troubleshooting (Flyway)
- Errore: "Unable to connect to the database. Configure the url, user and password." -> imposta `FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD` e riesegui `validate`.
- Errore: "No database found to handle jdbc:sqlserver://..." -> verifica il formato JDBC (es. `jdbc:sqlserver://<host>:1433;databaseName=<db>;encrypt=true`).
- Errore: "Invalid file path for -configFiles" -> esegui dal root repo o usa un path assoluto a `db/flyway/flyway.conf`.
- Errore: "Login failed for user" -> verifica credenziali SQL Auth e firewall/VNet del DB; se usi AAD cambia metodo di auth.
- Errore: "SSL/TLS handshake failed" -> verifica rete; per dev valuta `trustServerCertificate=true` solo se consentito.

## Provisioning dev/local (wrapper)
Per setup locale, usa il wrapper (human-in-the-loop) che applica Flyway:
- Validate: `pwsh db/provisioning/apply-flyway.ps1 -Action validate`
- Migrate: `pwsh db/provisioning/apply-flyway.ps1 -Action migrate`

Nota: gli artefatti storici sono in `old/db/` (non canonico).

ChatOps/AMS - Query utili
```sql
-- Ultima migrazione applicata
SELECT TOP 1 version, description, installed_on, installed_by
FROM flyway_schema_history ORDER BY installed_on DESC;

-- Migrazioni fallite o pendenti
SELECT * FROM flyway_schema_history WHERE success = 0;
```

Stato nel repo
- Skeleton già presente: `db/flyway/` con `sql/` e `flyway.conf`.
- Migrazioni baseline create: V1 (schemi), V2 (sequence), V3 (tabelle core PORTAL), V4 (logging/audit).
- Prossime: V5 (RLS), V6 (SP core + debug), V7 (seed), V8 (extended properties).

Nota su DataBase/ vs db/
- `db/` è la fonte canonica (DevOps-ready): migrazioni in `db/flyway/sql/`.
- `DataBase/` e' stata rimossa; gli artefatti storici sono archiviati in `old/db/`.
- Obiettivo: mantenere una sola referenza e rigenerare inventari/documentazione sempre da Flyway.

