---
id: ew-db-flyway
title: Flyway – DevOps per il Database (EasyWay)
summary: Strumento migration‑based per portare DDL/SP/sequence/RLS in un flusso maturo e ripetibile
status: draft
owner: team-data
tags: [domain/db, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

Cos’è Flyway
- Tool open‑source (Redgate) per versionare ed applicare migrazioni DB (DDL, DML, funzioni, SP, RLS…).
- Tiene uno storico (tabella `flyway_schema_history`) e applica solo le nuove versioni.
- Si integra perfettamente con CI/CD e ChatOps (audit nativo + query di stato).

Come funziona
- Crea `flyway_schema_history` nel DB e registra: versione, checksum, autore, timestamp, esito.
- Legge script in ordine dalla cartella configurata (es. `db/flyway/sql/`):
```sql
db/flyway/sql/
├─ V1__create_schemas.sql
├─ V2__core_sequences.sql
├─ V3__portal_core_tables.sql
├─ V4__portal_logging_tables.sql
├─ V5__rls_and_masking.sql
└─ V6__stored_procedures_core.sql
```sql
- Esegue solo le migrazioni non ancora registrate; in caso di errore, si ferma e fallisce la pipeline.

Naming (Flyway Standard)
- Versioned: `V<n>__descrizione.sql`
- Undo (opzionale): `U<n>__rollback.sql`
- Repeatable: `R__nome.sql` (ri‑eseguito se cambia file)
- Baseline (per DB già esistenti): `B<n>__baseline.sql` o `flyway baseline`

Best practice EasyWay
- 1 script = 1 scopo (tabella, SP, sequence, RLS…)
- Commento/header standard a inizio file (progetto, autore, scopo, ticket)
- Rollback: dove possibile aggiungere `U__rollback_*.sql`
- Logging: audit Flyway + nostre tabelle `PORTAL.LOG_AUDIT` e `PORTAL.STATS_EXECUTION_*`
- Pipeline: integrazione Azure DevOps (plan/apply gating) e variabili segrete in Variable Group/Key Vault

Integrazione EasyWay
- Cartella migrazioni: `db/flyway/sql/` (già presente nello skeleton)
- Config: `db/flyway/flyway.conf` (locations, baselineOnMigrate, ecc.)
- Esempio `flyway.conf` (DEV):
```sql
locations=filesystem:./sql
baselineOnMigrate=true
sqlMigrationSuffixes=.sql
connectRetries=5
# Le credenziali (URL/USER/PASSWORD) si passano come env nel runner
```sql

Esecuzione (CLI)
```sql
# Env (esempio SQL Auth)
$env:FLYWAY_URL = 'jdbc:sqlserver://<host>:1433;databaseName=<db>;encrypt=true'
$env:FLYWAY_USER = '<user>'
$env:FLYWAY_PASSWORD = '<password>'

flyway -configFiles=db/flyway/flyway.conf validate
flyway -configFiles=db/flyway/flyway.conf baseline -baselineVersion=1   # solo su DB esistenti
flyway -configFiles=db/flyway/flyway.conf migrate
```sql

ChatOps/AMS – Query utili
```sql
-- Ultima migrazione applicata
SELECT TOP 1 version, description, installed_on, installed_by
FROM flyway_schema_history ORDER BY installed_on DESC;

-- Migrazioni fallite o pendenti
SELECT * FROM flyway_schema_history WHERE success = 0;
```sql

Stato nel repo
- Skeleton già presente: `db/flyway/` con `sql/` e `flyway.conf`.
- Migrazioni baseline create: V1 (schemi), V2 (sequence), V3 (tabelle core PORTAL), V4 (logging/audit).
- Prossime: V5 (RLS), V6 (SP core + debug), V7 (seed), V8 (extended properties).

Nota su DataBase/ vs db/
- `db/` è il nuovo “source of truth” per migrazioni (DevOps‑ready).
- `DataBase/` contiene SQL storici: mantenerla come archivio finché non confluisce in migrazioni Flyway.
- Obiettivo: migrare i DDL storici in `db/flyway/sql/` (V1..Vn) e deprecare gradualmente `DataBase/`.





