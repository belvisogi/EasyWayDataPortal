---
id: ew-db-migrations
title: Gestione Migrazioni Database (Git + SQL Diretto)
summary: Guida canonica per gestire migrazioni database in EasyWayDataPortal usando approccio Git + SQL diretto (senza Flyway).
status: active
owner: team-data
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-18'
next: Sviluppare tool AI-friendly custom per automazione migrazioni (db/db-deploy-ai/).
---

[Home](.././start-here.md) > [[domains/db|db]] > 

# Gestione Migrazioni Database (Git + SQL Diretto)

## Contesto

**Source-of-truth DB (canonico)**: Migrazioni SQL in `db/migrations/`.

**Approccio**: Git + SQL diretto (senza Flyway).

**Perché NON usiamo Flyway**: Dopo valutazione approfondita (2+ ore debugging), Flyway è stato dismesso per questo progetto. Vedi [why-not-flyway.md](./why-not-flyway.md) per dettagli completi.

**Motivazioni principali**:
- SQL Server con 50+ stored procedures richiede gestione complessa dei batch separator `GO`
- Overhead di configurazione non giustificato per team piccolo (1-2 dev)
- Git già fornisce versioning e tracking
- Applicazione diretta via sqlcmd/Azure Portal è più semplice e veloce

---

## Come Funziona

### Struttura Directory

```sql
db/
├── migrations/              # File SQL di migrazione (SOURCE OF TRUTH)
│   ├── V1__baseline.sql
│   ├── V2__core_sequences.sql
│   ├── V3__portal_core_tables.sql
│   ├── V4__portal_logging_tables.sql
│   ├── V5__rls_setup.sql
│   ├── V6__stored_procedures_core.sql
│   └── ...
├── db-deploy-ai/           # Tool AI-friendly per automazione (futuro)
└── README.md
```sql

### Naming Convention

**Versioned migrations**: `Vxx__description.sql`

Esempi:
- `V1__baseline.sql` - Schema iniziale
- `V3__portal_core_tables.sql` - Tabelle core PORTAL
- `V6__stored_procedures_core.sql` - SP fondamentali
- `V14__refactor_onboarding_sp.sql` - Refactoring SP onboarding

**Best practice**:
- 1 file = 1 scopo (tabella, SP, sequence, RLS)
- Numerazione sequenziale (V1, V2, V3...)
- Descrizione chiara e concisa
- Idempotenza: usare `IF OBJECT_ID(...) IS NULL` per DDL

---

## Applicazione Migrazioni

### Opzione 1: Azure Portal Query Editor (Consigliato per Dev)

1. Vai su [Azure Portal](https://portal.azure.com)
2. Apri database `EASYWAY_PORTAL_DEV`
3. Click su "Query editor"
4. Copia/incolla contenuto file SQL
5. Esegui (F5 o click "Run")

**Vantaggi**: Zero setup, interfaccia web, ideale per test rapidi.

---

### Opzione 2: sqlcmd (CLI)

```powershell
# Imposta variabili ambiente (opzionale)
$server = "repos-easyway-dev.database.windows.net"
$database = "EASYWAY_PORTAL_DEV"
$user = "easyway-admin"

# Applica migrazione
sqlcmd -S $server `
       -d $database `
       -U $user `
       -P "<password>" `
       -i db/migrations/V3__portal_core_tables.sql
```sql

**Vantaggi**: Scriptabile, automazione CI/CD, batch processing.

---

### Opzione 3: SQL Server Management Studio (SSMS)

1. Connetti al database Azure SQL
2. File → Open → `db/migrations/Vxx__*.sql`
3. Esegui con F5

**Vantaggi**: IDE completo, debugging avanzato, intellisense.

---

## Workflow Creazione Nuova Migrazione

### 1. Crea File Migrazione

```powershell
# Esempio: aggiungere tabella NOTIFICATIONS
cd c:\old\EasyWayDataPortal

# Crea nuovo file con numero sequenziale successivo
New-Item -Path "db/migrations/V15__add_notifications_table.sql" -ItemType File
```sql

### 2. Scrivi DDL Idempotente

```sql
/* V15 — Tabella NOTIFICATIONS per sistema notifiche */

IF OBJECT_ID('PORTAL.NOTIFICATIONS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.NOTIFICATIONS (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id     NVARCHAR(50) NOT NULL,
    user_id       NVARCHAR(50) NOT NULL,
    message       NVARCHAR(MAX) NOT NULL,
    is_read       BIT NOT NULL DEFAULT (0),
    created_at    DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME())
  );
  
  CREATE INDEX IX_PORTAL_NOTIFICATIONS_tenant_user 
    ON PORTAL.NOTIFICATIONS(tenant_id, user_id);
END;
```sql

**Principi**:
- Sempre `IF OBJECT_ID(...) IS NULL` per evitare errori su re-run
- Commento header con numero versione e scopo
- Indici e constraint nella stessa migrazione
- Usare `SYSUTCDATETIME()` per timestamp UTC

### 3. Applica Migrazione

```powershell
# Opzione A: Azure Portal Query Editor (copia/incolla)

# Opzione B: sqlcmd
sqlcmd -S $server -d $database -U $user -P $password `
       -i db/migrations/V15__add_notifications_table.sql
```sql

### 4. Commit in Git

```powershell
git add db/migrations/V15__add_notifications_table.sql
git commit -m "Migration V15: Add NOTIFICATIONS table"
git push
```sql

### 5. Aggiorna Wiki

Crea pagina documentazione tabella:
```sql
Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/
  01b_schema_structure/PORTAL/tables/portal-notifications.md
```sql

Aggiorna inventario DDL:
```powershell
pwsh scripts/db-ddl-inventory.ps1 -WriteWiki
```sql

---

## Best Practice EasyWay

### Idempotenza

✅ **Corretto**:
```sql
IF OBJECT_ID('PORTAL.USERS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.USERS (...);
END;
```sql

❌ **Errato**:
```sql
CREATE TABLE PORTAL.USERS (...);  -- Fallisce se già esistente
```sql

### Stored Procedures

✅ **Corretto** (SQL Server 2016+):
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320)
AS
BEGIN
  -- Logic here
END;
```sql

✅ **Corretto** (SQL Server 2014):
```sql
IF OBJECT_ID('PORTAL.sp_insert_user','P') IS NOT NULL
  DROP PROCEDURE PORTAL.sp_insert_user;
GO

CREATE PROCEDURE PORTAL.sp_insert_user
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320)
AS
BEGIN
  -- Logic here
END;
GO
```sql

### Batch Separator `GO`

**Quando usare**:
- Dopo ogni `CREATE PROCEDURE`
- Dopo ogni `CREATE FUNCTION`
- Quando necessario separare batch T-SQL

**Esempio**:
```sql
CREATE PROCEDURE PORTAL.sp_one AS BEGIN SELECT 1; END;
GO

CREATE PROCEDURE PORTAL.sp_two AS BEGIN SELECT 2; END;
GO
```sql

### Logging e Auditing

Tutte le SP di mutazione devono loggare su `PORTAL.STATS_EXECUTION_LOG`:

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320)
AS
BEGIN
  -- Insert logic
  INSERT INTO PORTAL.USERS (...) VALUES (...);
  
  -- Log execution
  EXEC PORTAL.sp_log_stats_execution 
    @procedure_name = 'sp_insert_user',
    @tenant_id = @tenant_id,
    @status = 'SUCCESS';
END;
```sql

---

## Tracking e Versioning

### Git Come Source of Truth

**Vantaggi**:
- ✅ Storico completo di tutte le migrazioni
- ✅ Diff visibili tra versioni
- ✅ Rollback tramite `git revert`
- ✅ Branching per feature parallele
- ✅ Code review via Pull Request

**Workflow**:
```powershell
# Feature branch per nuova migrazione
git checkout -b feature/add-notifications
git add db/migrations/V15__add_notifications_table.sql
git commit -m "Migration V15: Add NOTIFICATIONS table"
git push origin feature/add-notifications

# Pull Request → Review → Merge to main
```sql

### Verifica Stato Database

```sql
-- Verifica esistenza tabella
SELECT OBJECT_ID('PORTAL.NOTIFICATIONS','U') AS table_exists;

-- Lista tutte le tabelle PORTAL
SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('PORTAL');

-- Lista tutte le SP PORTAL
SELECT name FROM sys.procedures WHERE schema_id = SCHEMA_ID('PORTAL');
```sql

---

## Tool AI-Friendly (Futuro)

Stiamo sviluppando un tool custom AI-native per automazione migrazioni:

**Directory**: `db/db-deploy-ai/`

**Funzionalità previste**:
- Generazione automatica DDL da intent JSON
- Validazione idempotenza
- Applicazione controllata con human-in-the-loop
- Logging strutturato
- Integrazione con gates CI/CD

**Vedi**: `db/AI_MIGRATION_TOOL_DESIGN.md` per dettagli.

---

## Troubleshooting

### Errore: "There is already an object named 'USERS' in the database"

**Causa**: Migrazione non idempotente.

**Fix**: Aggiungere `IF OBJECT_ID(...) IS NULL` prima di `CREATE TABLE`.

---

### Errore: "CREATE PROCEDURE must be the first statement in a query batch"

**Causa**: Manca `GO` dopo statement precedente.

**Fix**: Aggiungere `GO` prima di `CREATE PROCEDURE`.

---

### Errore: "Login failed for user"

**Causa**: Credenziali errate o firewall Azure.

**Fix**:
1. Verifica username/password
2. Controlla firewall rules in Azure Portal
3. Aggiungi tuo IP client alle allowed IPs

---

## Riferimenti

- [why-not-flyway.md](./why-not-flyway.md) - Perché NON usiamo Flyway
- [ddl-inventory.md](./ddl-inventory.md) - Inventario DDL canonico
- [portal.md](./portal.md) - Overview schema PORTAL
- [storeprocess.md](./storeprocess.md) - Guida stored procedures
- [db/README.md](file:///c:/old/EasyWayDataPortal/db/README.md) - README database

---

**Ultima revisione**: 2026-01-18  
**Approccio**: Git + SQL Diretto  
**Tool**: sqlcmd, Azure Portal, SSMS

