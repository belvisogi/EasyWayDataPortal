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

### ✅ Applicate
- V1: Baseline schema
- V2: Sequences
- V3_1: Tabelle estese
- V4: Sistema logging

### ⏳ Da Applicare
- V3: Core tables (TENANT, USERS, CONFIGURATION)
- V5: RLS function
- V6: Stored procedures core
- V7: Seed data
- V9: Stored procedures users/config
- V10: RLS configuration
- V11: Stored procedures users read

## Tool AI-Friendly (Futuro)

Svilupperemo un tool custom AI-friendly per gestire le migrazioni automaticamente.
Nessun Flyway, Liquibase o tool enterprise complesso.

## Note

- File SQL testati con SQL Server 2019+
- Ordine applicazione: V1 → V2 → V3 → V3_1 → V4 → V5 → V6 → V7 → V8 → V9 → V10 → V11
- Tracking versioni: Git
