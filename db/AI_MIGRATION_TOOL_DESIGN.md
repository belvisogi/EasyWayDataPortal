# AI-Friendly Database Migration Tool - Design

## 🎯 Obiettivo

Tool semplice per deploy database che un'AI può usare facilmente, senza complessità di Flyway/Liquibase.

## 📋 Principi di Design

### 1. **AI-First**
- Input: JSON chiaro e strutturato
- Output: JSON con risultati deterministici
- Zero configurazione
- Errori espliciti e actionable

### 2. **Semplicità**
- Un comando fa una cosa
- Nessuno stato nascosto
- Idempotente per natura

### 3. **Trasparenza**
- SQL visibile sempre
- Transazioni esplicite
- Rollback automatico su errore

## 🏗️ Architettura

```
AI Agent
   ↓ JSON request
┌─────────────────────┐
│  db-deploy CLI      │
│  (Node.js/Python)   │
└─────────────────────┘
   ↓ SQL execution
┌─────────────────────┐
│  Azure SQL DB       │
└─────────────────────┘
   ↓ JSON response
AI Agent
```

## 📦 Comandi Principali

### 1. `db-deploy apply`
Applica uno o più statement SQL con gestione transazioni.

**Input**:
```json
{
  "operation": "apply",
  "connection": {
    "server": "repos-easyway-dev.database.windows.net",
    "database": "EASYWAY_PORTAL_DEV",
    "auth": {
      "type": "sql",
      "username": "easyway-admin",
      "password": "${DB_PASSWORD}"
    }
  },
  "statements": [
    {
      "id": "create_tenant_table",
      "sql": "CREATE TABLE PORTAL.TENANT (...)",
      "rollback_on_error": true
    },
    {
      "id": "create_users_table", 
      "sql": "CREATE TABLE PORTAL.USERS (...)",
      "depends_on": ["create_tenant_table"]
    }
  ],
  "transaction": {
    "mode": "auto",
    "isolation": "READ_COMMITTED"
  }
}
```

**Output**:
```json
{
  "status": "success",
  "results": [
    {
      "id": "create_tenant_table",
      "status": "success",
      "rows_affected": 0,
      "execution_time_ms": 145
    },
    {
      "id": "create_users_table",
      "status": "success", 
      "rows_affected": 0,
      "execution_time_ms": 132
    }
  ],
  "total_time_ms": 277
}
```

**Errore**:
```json
{
  "status": "error",
  "failed_at": "create_users_table",
  "error": {
    "code": "SQL42S01",
    "message": "Table 'USERS' already exists",
    "line": 5,
    "suggestion": "Use 'IF NOT EXISTS' or DROP first"
  },
  "rollback": {
    "executed": true,
    "statements_reverted": ["create_tenant_table"]
  }
}
```

### 2. `db-deploy validate`
Valida SQL senza eseguire (dry-run).

**Input**:
```json
{
  "operation": "validate",
  "connection": { ... },
  "statements": [ ... ]
}
```

**Output**:
```json
{
  "status": "valid",
  "warnings": [
    {
      "statement_id": "create_tenant_table",
      "warning": "Table already exists - statement will be skipped",
      "severity": "low"
    }
  ]
}
```

### 3. `db-deploy diff`
Confronta schema attuale con schema desiderato.

**Input**:
```json
{
  "operation": "diff",
  "connection": { ... },
  "desired_schema": {
    "tables": ["TENANT", "USERS", "CONFIGURATION"],
    "functions": ["fn_rls_tenant_filter"],
    "procedures": ["sp_insert_tenant"]
  }
}
```

**Output**:
```json
{
  "status": "success",
  "diff": {
    "missing": {
      "tables": ["USERS", "CONFIGURATION"],
      "procedures": ["sp_insert_tenant"]
    },
    "extra": {
      "tables": ["OLD_TABLE"]
    },
    "modified": []
  },
  "suggested_actions": [
    "Run migrations/V3__portal_core_tables.sql",
    "Run migrations/V6__stored_procedures_core.sql"
  ]
}
```

### 4. `db-deploy snapshot`
Crea snapshot dello schema corrente.

**Output**:
```json
{
  "status": "success",
  "snapshot": {
    "timestamp": "2026-01-14T23:32:00Z",
    "database": "EASYWAY_PORTAL_DEV",
    "compatibility_level": 150,
    "tables": [
      {
        "schema": "PORTAL",
        "name": "TENANT",
        "columns": [...],
        "indexes": [...]
      }
    ],
    "functions": [...],
    "procedures": [...]
  },
  "snapshot_file": "db/snapshots/2026-01-14_233200.json"
}
```

## 🔧 Implementazione

### Tech Stack Proposto
- **Runtime**: Node.js (facile da deployare, ottimo per AI)
- **DB Driver**: `mssql` npm package
- **CLI**: `commander.js`
- **Config**: Variabili ambiente + JSON

### File Structure
```
db-deploy/
├── src/
│   ├── cli.js              # Entry point CLI
│   ├── executor.js         # SQL execution engine
│   ├── validator.js        # SQL validation
│   ├── differ.js           # Schema diff
│   └── snapshot.js         # Schema snapshot
├── package.json
└── README.md
```

## 🚀 Uso da AI

### Scenario 1: AI vuole creare tabella
```javascript
// AI genera questo JSON
const request = {
  operation: "apply",
  connection: { ... },
  statements: [{
    id: "create_notifications",
    sql: `
      IF OBJECT_ID('PORTAL.NOTIFICATIONS','U') IS NULL
      BEGIN
        CREATE TABLE PORTAL.NOTIFICATIONS (
          id INT IDENTITY PRIMARY KEY,
          message NVARCHAR(MAX)
        );
      END
    `
  }]
};

// Esegue
const result = await dbDeploy(request);

// AI legge risultato JSON
if (result.status === "success") {
  console.log("✅ Tabella creata");
} else {
  console.log(`❌ Errore: ${result.error.message}`);
  // AI can retry with fixes
}
```

### Scenario 2: AI vuole verificare schema
```javascript
const diff = await dbDeploy({
  operation: "diff",
  desired_schema: {
    tables: ["TENANT", "USERS"]
  }
});

// AI decide quali migrazioni applicare
for (const tableName of diff.diff.missing.tables) {
  // Apply migration for this table
}
```

## 🎁 Vantaggi vs Flyway

| Feature | Flyway | db-deploy AI |
|---------|--------|-------------|
| **Input format** | File SQL + config TOML | JSON API |
| **Output** | Testo console | JSON strutturato |
| **Error handling** | Eccezioni | JSON con suggestions |
| **Idempotenza** | Manuale (IF EXISTS) | Built-in |
| **Dry-run** | ❌ No | ✅ validate command |
| **Schema diff** | ❌ No | ✅ diff command |
| **AI-friendly** | ❌ No | ✅ Yes |
| **Config** | Multiple files | Env vars + JSON |
| **Transaction** | ❌ Manual | ✅ Auto |

## 📝 Example: Deploy Complete Schema

```json
{
  "operation": "apply_batch",
  "connection": { ... },
  "batch": {
    "name": "initial_schema",
    "migrations_dir": "db/migrations",
    "order": [
      "V1__baseline.sql",
      "V2__core_sequences.sql",
      "V3__portal_core_tables.sql"
    ],
    "stop_on_error": false,
    "collect_errors": true
  }
}
```

**Output**:
```json
{
  "status": "partial_success",
  "summary": {
    "total": 3,
    "succeeded": 2,
    "failed": 1
  },
  "results": [...],
  "errors": [
    {
      "file": "V3__portal_core_tables.sql",
      "error": "...",
      "suggestion": "Fix ISNULL in index definition"
    }
  ]
}
```

## 🔐 Security

- Password mai in JSON (usa env vars `${VAR}`)
- Connection string masking in logs
- Audit log di ogni operazione
- Supporto Azure AD authentication

## 🎯 MVP Features (Fase 1)

1. ✅ `apply` command con JSON input/output
2. ✅ Transaction management automatico
3. ✅ Error reporting strutturato
4. ✅ IF EXISTS handling automatico

## 🚀 Advanced Features (Fase 2)

1. `diff` command per schema comparison
2. `validate` con syntax check
3. `rollback` a snapshot specifico
4. Multi-database support (PostgreSQL, MySQL)

## 💡 Differenza Chiave

**Flyway pensa**: "Migrazione = file SQL da eseguire in ordine"  
**db-deploy AI pensa**: "Migrazione = API call con SQL che ritorna JSON"

Questo rende db-deploy **perfetto per AI** che ragionano in termini di API e JSON.

---

**Next Steps**: 
1. Implementare MVP in Node.js
2. Testare con EasyWayDataPortal migrations
3. Iterare basandosi su feedback AI
