# Database Migrations

Questa directory contiene le migrazioni SQL per il database EasyWay Portal.

## Struttura

```
db/
├── migrations/          # File SQL di migrazione
│   ├── V1__baseline.sql
│   ├── V2__core_sequences.sql
│   ├── V3__portal_core_tables.sql
│   └── ...
├── db-deploy-ai/       # Tool AI-native per migrations
├── scripts/            # PowerShell utilities
└── docs/               # Documentazione (SYSTEM_OVERVIEW, USE_CASES, GUARDRAILS)
```

**Note**: `WHY_NOT_FLYWAY.md` spostato in `Wiki/.../01_database_architecture/why-not-flyway.md`

## Applicazione Migrazioni

### Opzione 1: Azure Portal Query Editor
1. Vai su [Azure Portal](https://portal.azure.com)
2. Apri database `EASYWAY_PORTAL_DEV`
3. Click su "Query editor"
4. Copia/incolla contenuto file SQL
5. Esegui

### Opzione 2: sqlcmd
```powershell
sqlcmd -S repos-easyway-dev.database.windows.net `
       -d EASYWAY_PORTAL_DEV `
       -U easyway-admin `
       -P "<password>" `
       -i migrations/V1__baseline.sql
```

### Opzione 3: SQL Server Management Studio (SSMS)
1. Connetti al database
2. Apri file SQL
3. Esegui con F5

## Stato Attuale

Database su **SQL Server 2019** (compatibility level 150)

### ✅ Nuova Convenzione (2026+)

**Formato**: `YYYYMMDD_SCHEMA_description.sql`

Esempi:
- `20260119_ALL_baseline.sql` - Baseline completo (V1-V11 consolidato)
- `20260119_AGENT_MGMT_console.sql` - Agent Management Console
- `20260120_PORTAL_notifications.sql` - Future: Notification system

**Vedi**: [MIGRATION_CONVENTION.md](MIGRATION_CONVENTION.md) per dettagli completi

### 📦 Migrations Disponibili

**Baseline:**
- `20260119_ALL_baseline.sql` - Setup completo database (consolida V1-V11)

**Features:**
- `20260119_AGENT_MGMT_console.sql` - Agent Management Console

**Legacy (Archived in `_archive/`):**
- V1-V11 - Migrations originali Flyway (reference only)

## Applicare Migration

### Baseline (Prima Installazione)

```powershell
cd db/scripts
.\apply-migration-simple.ps1 -MigrationFile "20260119_ALL_baseline.sql"
```

### Nuove Features

```powershell
cd db/scripts
.\apply-migration-simple.ps1 -MigrationFile "20260119_AGENT_MGMT_console.sql"
```

### Manualmente con db-deploy-ai

```powershell
cd db/db-deploy-ai
cat ../migrations/20260119_ALL_baseline.sql | npm run apply
```

## Creare Nuova Migration

### 1. Scegli Schema

- `PORTAL` - App principale (users, tenants, config)
- `AGENT_MGMT` - Agent management
- `BRONZE` - Raw data
- `SILVER` - Cleaned data
- `GOLD` - Aggregates
- `REPORTING` - Reports/views
- `ALL` - Multi-schema changes

### 2. Crea File

```powershell
$date = Get-Date -Format "yyyyMMdd"
$schema = "PORTAL"
$description = "add_notifications"
New-Item "db/migrations/${date}_${schema}_${description}.sql"
```

### 3. Applica

```powershell
cd db/scripts
.\apply-migration-simple.ps1 -MigrationFile "${date}_${schema}_${description}.sql"
```

## Tool AI-Friendly

Usiamo **db-deploy-ai** - tool custom AI-friendly per gestire le migrazioni.
Nessun Flyway, Liquibase o tool enterprise complesso.

## Consolidare Legacy Migrations

Se hai ancora V## files da consolidare:

```powershell
cd db/scripts
.\consolidate-baseline.ps1
```

Questo crea `20260119_ALL_baseline.sql` e archivia i vecchi V## files in `_archive/`.


