# EasyWay Database Migration Convention

## 📋 Nuova Convenzione (2026+)

### Formato Naming

```
YYYYMMDD_SCHEMA_description.sql
```

**Componenti:**
- `YYYYMMDD` - Data creazione (es. 20260119)
- `SCHEMA` - Schema target (PORTAL, AGENT_MGMT, BRONZE, SILVER, GOLD, etc.)
- `description` - Descrizione breve (snake_case)

### Esempi

```
migrations/
├── 20260119_ALL_baseline.sql                    # Baseline completo (V1-V11 consolidato)
├── 20260119_AGENT_MGMT_console.sql             # Agent Management Console
├── 20260120_PORTAL_add_notifications.sql       # Nuova tabella PORTAL.NOTIFICATIONS
├── 20260121_BRONZE_customer_staging.sql        # Staging area per clienti
├── 20260122_GOLD_sales_aggregates.sql          # Aggregati vendite
└── 20260125_REPORTING_dashboard_views.sql      # Viste per reporting
```

---

## 🎯 Perché Questa Convenzione?

### ✅ Vantaggi

1. **Organizzazione per Schema**
   - Facile capire quale schema viene modificato
   - Raggruppamento logico delle migration

2. **Ordinamento Cronologico**
   - Timestamp garantisce ordine applicazione
   - Nessuna confusione su versioni

3. **Mantenibilità**
   - Nome descrittivo = capire cosa fa senza aprire file
   - Schema prefix = trovare migration correlate

4. **Git-Friendly**
   - Nessun conflict su numeri versione
   - Merge facili tra branch

5. **AI-Friendly**
   - Pattern chiaro e predicibile
   - Facile da parsare e generare

### ❌ Cosa NON Fare

```
❌ V16__new_feature.sql              # Flyway-style (deprecato)
❌ migration_001.sql                 # Numeri sequenziali
❌ add_table.sql                     # Nessun timestamp
❌ 20260119_feature.sql              # Manca schema
❌ 20260119_portal_AddTable.sql      # CamelCase (no!)
```

---

## 📚 Schema Disponibili

### Core Schemas

**PORTAL** - Applicazione principale
- Tenant management
- User management
- Configuration
- ACL

**AGENT_MGMT** - Agent Management Console
- Agent registry
- Execution tracking
- Metrics
- Telemetry

### Data Platform Schemas

**BRONZE** - Raw data layer
- Staging tables
- Landing zone
- Raw ingestion

**SILVER** - Cleaned data layer
- Validated data
- Business logic applied
- Deduplicated

**GOLD** - Aggregated data layer
- Business metrics
- Aggregates
- Denormalized views

**REPORTING** - Reporting layer
- Dashboard views
- Report tables
- Materialized views

**WORK** - Temporary/scratch space
- ETL staging
- Temporary calculations
- Debug tables

---

## 🔧 Come Creare Nuova Migration

### Step 1: Scegli Schema Target

Quale schema stai modificando?
- Tabelle utenti? → `PORTAL`
- Agent tracking? → `AGENT_MGMT`
- Staging data? → `BRONZE`
- Aggregati? → `GOLD`
- Viste reporting? → `REPORTING`

### Step 2: Crea File

```powershell
# Template
$date = Get-Date -Format "yyyyMMdd"
$schema = "PORTAL"
$description = "add_notifications"

$filename = "${date}_${schema}_${description}.sql"
New-Item "db/migrations/$filename"
```

### Step 3: Scrivi Migration

```sql
-- 20260120_PORTAL_add_notifications.sql
-- Add notification system to PORTAL schema

SET NOCOUNT ON;
GO

-- Create table
IF OBJECT_ID('PORTAL.NOTIFICATIONS', 'U') IS NULL
BEGIN
    CREATE TABLE PORTAL.NOTIFICATIONS (
        id INT IDENTITY(1,1) PRIMARY KEY,
        tenant_id NVARCHAR(50) NOT NULL,
        user_id NVARCHAR(50) NOT NULL,
        message NVARCHAR(MAX) NOT NULL,
        is_read BIT NOT NULL DEFAULT 0,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        
        CONSTRAINT FK_NOTIFICATIONS_tenant 
            FOREIGN KEY (tenant_id) 
            REFERENCES PORTAL.TENANT(tenant_id)
    );
    
    CREATE INDEX IX_NOTIFICATIONS_user 
        ON PORTAL.NOTIFICATIONS(tenant_id, user_id, is_read);
END;
GO
```

### Step 4: Applica Migration

```powershell
cd db/scripts
.\apply-migration-simple.ps1 -MigrationFile "20260120_PORTAL_add_notifications.sql"
```

---

## 📦 Migration Speciali

### ALL Schema - Baseline/Multi-Schema

Usa `ALL` quando la migration tocca **più schema**:

```
20260119_ALL_baseline.sql           # Setup iniziale completo
20260125_ALL_security_update.sql    # Update sicurezza cross-schema
```

### Esempio Baseline

```sql
-- 20260119_ALL_baseline.sql
-- Complete database baseline (consolidates V1-V11)

-- Create all schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'PORTAL') 
    EXEC('CREATE SCHEMA PORTAL');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'BRONZE') 
    EXEC('CREATE SCHEMA BRONZE');
-- ... etc

-- Create sequences
-- Create tables
-- Create stored procedures
-- Seed data
```

---

## 🗂️ Organizzazione Directory

```
db/
├── migrations/
│   ├── 20260119_ALL_baseline.sql              # Baseline consolidato
│   ├── 20260119_AGENT_MGMT_console.sql        # Agent Management
│   ├── 20260120_PORTAL_notifications.sql      # Future: Notifications
│   ├── 20260121_BRONZE_customer_staging.sql   # Future: Staging
│   └── _archive/                              # Old V## files (reference only)
│       ├── V1__baseline.sql
│       ├── V2__core_sequences.sql
│       └── ...
├── scripts/
│   ├── apply-migration-simple.ps1
│   └── consolidate-migrations.ps1             # Tool per consolidare
└── README.md
```

---

## 🎯 Best Practices

### 1. Idempotency

Sempre usa `IF NOT EXISTS` / `IF OBJECT_ID(...) IS NULL`:

```sql
-- ✅ Good
IF OBJECT_ID('PORTAL.NOTIFICATIONS', 'U') IS NULL
BEGIN
    CREATE TABLE PORTAL.NOTIFICATIONS (...);
END;

-- ❌ Bad
CREATE TABLE PORTAL.NOTIFICATIONS (...);  -- Fails if exists!
```

### 2. Schema Prefix

Sempre specifica schema:

```sql
-- ✅ Good
CREATE TABLE PORTAL.NOTIFICATIONS (...);
SELECT * FROM PORTAL.USERS;

-- ❌ Bad
CREATE TABLE NOTIFICATIONS (...);  -- Quale schema?
SELECT * FROM USERS;               -- Ambiguo!
```

### 3. Audit Columns

Include sempre:

```sql
created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
created_by NVARCHAR(255) NOT NULL DEFAULT SYSTEM_USER
```

### 4. Transactions

Wrappa operazioni complesse:

```sql
BEGIN TRANSACTION;
BEGIN TRY
    -- Your changes here
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

### 5. Documentation

Commenta sempre:

```sql
-- 20260120_PORTAL_add_notifications.sql
-- Purpose: Add notification system for user alerts
-- Author: Team Platform
-- Related: Ticket #1234
```

---

## 📊 Migration Lifecycle

```
1. Create
   └─> YYYYMMDD_SCHEMA_description.sql

2. Review
   └─> Code review + SQL validation

3. Test (DEV)
   └─> Apply to DEV environment

4. Verify
   └─> Check schema, test queries

5. Deploy (PROD)
   └─> Apply to PROD environment

6. Archive
   └─> Commit to Git, document in README
```

---

## 🚀 Quick Reference

```powershell
# Create new migration
$date = Get-Date -Format "yyyyMMdd"
New-Item "db/migrations/${date}_PORTAL_my_feature.sql"

# Apply migration
cd db/scripts
.\apply-migration-simple.ps1 -MigrationFile "${date}_PORTAL_my_feature.sql"

# Verify
Invoke-Sqlcmd -Query "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'PORTAL'"
```

---

## 📝 Checklist per Nuova Migration

- [ ] Nome segue pattern `YYYYMMDD_SCHEMA_description.sql`
- [ ] Schema prefix su tutte le tabelle/views
- [ ] `IF NOT EXISTS` per idempotency
- [ ] Audit columns (created_at, updated_at, created_by)
- [ ] Indexes appropriati
- [ ] Foreign keys dove necessario
- [ ] Commenti descrittivi
- [ ] Testato in DEV
- [ ] README.md aggiornato

---

**Convenzione approvata: 2026-01-19**  
**Effective date: Immediate**  
**Replaces: Flyway V## pattern**
