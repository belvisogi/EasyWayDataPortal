# Agent Management Console - Integrazione con db-deploy-ai

## 📋 Riepilogo Integrazione

L'Agent Management Console è stato **adattato all'infrastruttura esistente** EasyWayDataPortal:

### ✅ Cosa è Cambiato

1. **Rimosso Versioning Flyway**
   - ❌ `V15__agent_management_console.sql` (stile Flyway)
   - ✅ `20260119_agent_management_console.sql` (timestamp-based)

2. **Integrazione con db-deploy-ai**
   - Tool custom AI-friendly (NO Flyway/Liquibase)
   - JSON API per migrations
   - Pipe SQL direttamente al tool

3. **Script di Deployment Creati**
   - `apply-agent-management-migration.ps1` - Full-featured con validazione
   - `apply-migration-simple.ps1` - Wrapper semplice per qualsiasi migration

---

## 🚀 Come Applicare la Migration

### Opzione 1: Script Semplice (Raccomandato)

```powershell
cd c:\old\EasyWayDataPortal\db\scripts
.\apply-migration-simple.ps1 -MigrationFile "20260119_agent_management_console.sql"
```

### Opzione 2: Script Completo con Parametri

```powershell
cd c:\old\EasyWayDataPortal\db\scripts
.\apply-agent-management-migration.ps1 `
    -Server "repos-easyway-dev.database.windows.net" `
    -Database "EASYWAY_PORTAL_DEV" `
    -Username "easyway-admin" `
    -Password "YourPassword"
```

### Opzione 3: Manuale con db-deploy-ai

```powershell
cd c:\old\EasyWayDataPortal\db\db-deploy-ai

# Assicurati che .env sia configurato
cat .env.example

# Applica migration
cat ../migrations/20260119_agent_management_console.sql | npm run apply
```

### Opzione 4: Azure Portal Query Editor

1. Vai su [Azure Portal](https://portal.azure.com)
2. Apri database `EASYWAY_PORTAL_DEV`
3. Click su "Query editor"
4. Copia/incolla contenuto di `20260119_agent_management_console.sql`
5. Esegui

---

## 📊 Cosa Crea la Migration

### Schema: `AGENT_MGMT`

**Tabelle:**
- `agent_registry` - Registry di tutti gli agenti con metadata
- `agent_executions` - Tracking esecuzioni (TODO/ONGOING/DONE)
- `agent_metrics` - Metriche time-series (token, tempo, costi)
- `agent_capabilities` - Capabilities per agente
- `agent_triggers` - Triggers configurabili

**Stored Procedures:**
- `sp_sync_agent_from_manifest` - Sync da manifest.json
- `sp_toggle_agent_status` - Enable/disable agente
- `sp_start_execution` - Crea nuova esecuzione
- `sp_update_execution_status` - Aggiorna status (TODO→ONGOING→DONE)
- `sp_get_agent_dashboard` - Dati dashboard
- `sp_get_execution_history` - Storico esecuzioni

**Views:**
- `vw_agent_dashboard` - Vista real-time per console

---

## 🔧 Prossimi Passi Dopo Migration

### 1. Sync Agenti al Database

```powershell
cd c:\old\EasyWayDataPortal\scripts\pwsh

# Configura connection string
$connStr = "Server=repos-easyway-dev.database.windows.net;Database=EASYWAY_PORTAL_DEV;User Id=admin;Password=pass;"

# Sync tutti gli agenti
.\sync-agents-to-db.ps1 -ConnectionString $connStr
```

### 2. Test Telemetry Module

```powershell
# Importa modulo
Import-Module "c:\old\EasyWayDataPortal\scripts\pwsh\modules\Agent-Management-Telemetry.psm1"

# Inizializza
Initialize-AgentTelemetry -ConnectionString $connStr

# Test con Agent GEDI
$execId = Start-AgentExecution -AgentId "agent_gedi" -ActionName "test" -TriggeredBy "manual"
Update-AgentExecutionStatus -ExecutionId $execId -Status "ONGOING"
Update-AgentExecutionStatus -ExecutionId $execId -Status "DONE" -TokensConsumed 1500

# Verifica dashboard
Get-AgentDashboard
```

### 3. Integra Telemetry in Agente

Esempio con Agent GEDI:

```powershell
# In agent-gedi.ps1
Import-Module ".\modules\Agent-Management-Telemetry.psm1"

Initialize-AgentTelemetry -ConnectionString $env:DB_CONNECTION_STRING

Invoke-AgentWithTelemetry -AgentId "agent_gedi" -ActionName "gedi:ooda.loop" -ScriptBlock {
    # La tua logica agente qui
    Write-Host "💙 GEDI: Analyzing decision quality..."
    
    # Telemetry traccia automaticamente token e tempo
}
```

---

## 🎯 Convenzioni per Nuove Migration

### Naming Format

```
YYYYMMDD_description.sql
```

**Esempi:**
- ✅ `20260119_agent_management_console.sql`
- ✅ `20260120_add_notification_table.sql`
- ✅ `20260125_update_user_permissions.sql`
- ❌ `V16__new_feature.sql` (NO più Flyway!)

### Best Practices

1. **Idempotent**: Usa `IF NOT EXISTS` / `IF OBJECT_ID(...) IS NULL`
2. **Schema Prefix**: Sempre `SCHEMA.TABLE` (es. `AGENT_MGMT.agent_registry`)
3. **Audit Columns**: Include `created_at`, `updated_at`, `created_by`
4. **Transactions**: Wrappa in `BEGIN TRANSACTION` / `COMMIT`
5. **Error Handling**: Usa `TRY...CATCH` per SP complesse

---

## 📚 File Creati/Modificati

### Nuovi File

1. **Migration**
   - `db/migrations/20260119_agent_management_console.sql` (rinominato da V15)

2. **PowerShell Scripts**
   - `db/scripts/apply-agent-management-migration.ps1`
   - `db/scripts/apply-migration-simple.ps1`
   - `scripts/pwsh/modules/Agent-Management-Telemetry.psm1`
   - `scripts/pwsh/sync-agents-to-db.ps1`

### File Modificati

1. **Documentation**
   - `db/README.md` - Aggiunto Agent Management migration e nuove convenzioni

---

## 🔍 Verifica Post-Migration

```sql
-- Verifica schema creato
SELECT name FROM sys.schemas WHERE name = 'AGENT_MGMT';

-- Verifica tabelle
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'AGENT_MGMT';

-- Verifica stored procedures
SELECT ROUTINE_NAME 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'AGENT_MGMT' 
  AND ROUTINE_TYPE = 'PROCEDURE';

-- Test dashboard view
SELECT * FROM AGENT_MGMT.vw_agent_dashboard;
```

---

## 💡 Troubleshooting

### Errore: "Schema AGENT_MGMT already exists"

La migration è idempotent, ma se vuoi ricreare:

```sql
-- Drop schema (ATTENZIONE: perdi tutti i dati!)
DROP SCHEMA AGENT_MGMT;
```

### Errore: "npm: command not found"

Installa Node.js:
```powershell
winget install OpenJS.NodeJS
```

### Errore: "Connection failed"

Verifica credenziali e firewall:
```powershell
# Test connessione
Test-NetConnection -ComputerName "repos-easyway-dev.database.windows.net" -Port 1433
```

---

## 🎉 Pronto!

Ora hai:
- ✅ Migration rinominata secondo nuove convenzioni
- ✅ Script per applicarla con db-deploy-ai
- ✅ Telemetry module per tracking
- ✅ Sync script per popolare DB
- ✅ Documentazione completa

**Next**: Applica la migration e inizia a monitorare gli agenti! 🚀
