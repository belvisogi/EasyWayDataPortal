# Database Management - Real Use Cases & Pain Points

## 🎯 Use Cases Raccolti dal Team

### UC1: Stored Procedures Non Standard
**Pain Point**: SP esistenti non rispettano gli standard AI-friendly definiti per EasyWay

**Current Situation**:
- SP senza `SET NOCOUNT ON`
- Nessun error handling (TRY...CATCH)
- Return inconsistenti (alcuni SELECT, altri RETURN, altri niente)
- Naming non uniforme (`InsertUser` vs `sp_insert_user`)
- Nessun audit logging

**Impact**:
- ❌ Agent AI non può chiamarle in modo affidabile
- ❌ Debugging difficile
- ❌ Nessun tracking operazioni

**Desired Solution**:
- ✅ **Validator automatico** che scansiona tutte le SP
- ✅ **Report gap** con violazioni specifiche
- ✅ **Auto-fix** per violazioni semplici (es. aggiungere SET NOCOUNT ON)
- ✅ **Template generator** per creare SP standard-compliant

**Priority**: 🔥 CRITICAL

---

### UC2: Tabelle Senza Campi Tecnici
**Pain Point**: Tabelle legacy mancano i campi standard (audit trail)

**Missing Fields**:
```sql
created_by    NVARCHAR(255) NOT NULL DEFAULT 'SYSTEM'
created_at    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
updated_by    NVARCHAR(255) NULL
updated_at    DATETIME2 NULL
deleted_by    NVARCHAR(255) NULL  -- soft delete
deleted_at    DATETIME2 NULL
version       INT DEFAULT 1      -- optimistic locking
```

**Current Situation**:
- Impossibile sapere CHI ha creato/modificato record
- Impossibile sapere QUANDO
- Soft delete non possibile
- Nessuna protezione da concurrent updates

**Impact**:
- ❌ No audit trail (compliance issue!)
- ❌ No soft delete pattern
- ❌ Concurrency bugs

**Desired Solution**:
- ✅ **Table scanner** che identifica tabelle senza campi tecnici
- ✅ **Migration generator** per aggiungere campi (in posizione corretta!)
- ✅ **Trigger auto-generator** per popolare created_by/updated_by
- ✅ **Soft delete helper** (views che filtrano deleted_at IS NULL)

**Priority**: 🔥 HIGH

---

### UC3: Tabelle Senza Chiave Naturale
**Pain Point**: Tabelle con solo ID auto-increment, nessun business key

**Example**:
```sql
-- ❌ BAD
CREATE TABLE CUSTOMER (
  id INT IDENTITY PRIMARY KEY,
  name NVARCHAR(100),
  email NVARCHAR(320)
);

-- ✅ GOOD  
CREATE TABLE CUSTOMER (
  id INT IDENTITY PRIMARY KEY,
  customer_code NVARCHAR(50) NOT NULL,  -- Business key
  name NVARCHAR(100),
  email NVARCHAR(320),
  CONSTRAINT UX_CUSTOMER_code UNIQUE(customer_code)
);
```

**Impact**:
- ❌ Impossibile riferimenti stabili tra sistemi
- ❌ Data import/export difficile
- ❌ Debugging complicato ("qual è il customer 12345?")
- ❌ AI agent fatica a interpretare dati

**Desired Solution**:
- ✅ **Business key detector** (regex patterns comuni: code, ref, external_id)
- ✅ **Suggestion engine**: "Questa tabella potrebbe beneficiare di customer_code"
- ✅ **Migration wizard**: Guida per aggiungere chiave naturale
- ✅ **Unique constraint checker**: Verifica che business key sia UNIQUE

**Priority**: 🟡 MEDIUM

---

### UC4: Gap Analysis per Campo
**Pain Point**: Voglio sapere quali campi mancano DIRETTAMENTE dal DB, non da documentazione

**Scenario**:
- Ho 50 tabelle
- Standard dice: ogni tabella deve avere `tenant_id` (multi-tenancy)
- Quali tabelle lo hanno? Quali no?

**Current Solution**: Query manuale
```sql
SELECT t.TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES t
WHERE NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS c
  WHERE c.TABLE_NAME = t.TABLE_NAME AND c.COLUMN_NAME = 'tenant_id'
);
```

**Impact**:
- ⏱️ Time consuming
- ❌ Deve sapere SQL
- ❌ Nessuna UI

**Desired Solution**:
- ✅ **Gap Analyzer UI**: Interface web che mostra:
  ```
  Standard Field: tenant_id
  Expected Type: NVARCHAR(50) NOT NULL
  
  ✅ Has field (42 tables)
  ❌ Missing (8 tables):
    - CUSTOMER
    - ORDER
    - INVOICE
    ...
  ⚠️ Wrong type (2 tables):
    - LEGACY_TABLE (VARCHAR(50) instead of NVARCHAR)
  ```
- ✅ **One-click migration**: "Fix all 8 missing tables"
- ✅ **Custom standards**: Define your own required fields

**Priority**: 🔥 HIGH

---

### UC5: ADD COLUMN in Posizione Corretta
**Pain Point**: Aggiungere colonna DEVE andare PRIMA dei campi tecnici, non dopo

**Problem**:
```sql
-- Tabella esistente
CREATE TABLE USERS (
  id INT IDENTITY,
  name NVARCHAR(100),
  email NVARCHAR(320),
  created_at DATETIME2,  -- Campo tecnico
  updated_at DATETIME2   -- Campo tecnico
);

-- Voglio aggiungere "phone"
-- ❌ BAD: ALTER TABLE USERS ADD phone NVARCHAR(20);
-- Risultato: phone va DOPO updated_at (brutto!)

-- ✅ GOOD: phone va PRIMA di created_at
```

**SQL Server Issue**: `ALTER TABLE ADD` aggiunge SEMPRE alla fine!

**Current Solution**: "Travaso con le tre carte"
```sql
-- 1. Crea tabella temporanea con ordine corretto
-- 2. Copia dati
-- 3. Drop vecchia
-- 4. Rename nuova
-- Rischio: Downtime, dati persi se errore
```

**Desired Solution**:
- ✅ **Smart Column Adder**:
  1. Detecta campi tecnici (pattern: created_*, updated_*, deleted_*)
  2. Genera script travaso automatico
  3. Include transazione + rollback
  4. Backup safety check
  5. Zero downtime (se possibile)
- ✅ **Column Order Validator**: Warning se ordine non standard

**Priority**: 🟡 MEDIUM

---

## 💡 Altri Use Cases Proposti (Brainstorming)

### UC6: Index Recommendations
**Pain Point**: Query lente, non so quali index servono

**Solution**:
- Analyze query patterns (da SQL Server DMVs)
- Suggest missing indexes
- Detect unused indexes (waste of space)
- Cost/benefit analysis

**Priority**: 🟡 MEDIUM

---

### UC7: Data Type Inconsistency
**Pain Point**: Stesso campo, tipi diversi in tabelle diverse

**Example**:
```sql
USERS.email       NVARCHAR(320)
CUSTOMERS.email   VARCHAR(255)   -- ❌ Inconsistent!
CONTACTS.email    NVARCHAR(MAX)  -- ❌ Overkill!
```

**Solution**:
- Scan all tables for "semantic fields" (email, phone, name, etc.)
- Report inconsistencies
- Suggest standardization
- Generate migration

**Priority**: 🟢 LOW

---

### UC8: Constraint Naming
**Pain Point**: Constraints auto-generated hanno nomi brutti

**Example**:
```sql
-- ❌ BAD: PK__USERS__3213E83F7F60ED59
-- ✅ GOOD: PK_USERS_id
```

**Solution**:
- Detect auto-generated constraint names
- Suggest standard names
- Generate RENAME scripts

**Priority**: 🟢 LOW

---

### UC9: Foreign Key Gaps
**Pain Point**: Relazioni logiche non enforced da FK

**Example**:
```sql
-- ORDERS.customer_id → CUSTOMERS.id (no FK!)
```

**Solution**:
- Detect "FK candidates" (columns ending in _id)
- Check if FK exists
- Report orphaned records (blockers for FK creation)
- Generate FK creation script

**Priority**: 🟡 MEDIUM

---

### UC10: Multi-Tenancy Audit
**Pain Point**: RLS configurato? Tutte le tabelle tenant-aware?

**Checks**:
- [ ] Table has `tenant_id` column
- [ ] RLS policy defined
- [ ] RLS policy enabled
- [ ] All queries filter by tenant_id
- [ ] No cross-tenant data leaks

**Solution**:
- Multi-tenancy health check
- Security audit report
- Auto-fix suggestions

**Priority**: 🔥 CRITICAL (security!)

---

## 📚 Use Cases dalla Wiki EasyWay

### UC11: Extended Properties Missing
**Pain Point**: Campi senza descrizione/metadata (da Wiki best-practices)

**Wiki Standard**:
> "Tutto ha naming self-explained, descrizione extended property e audit"

**Current Situation**:
- Colonne senza `sys.extended_properties`
- Impossibile capire significato senza leggere codice
- AI agent non può interpretare schema

**Solution**:
- **Extended Property Scanner**: Trova colonne senza descrizione
- **AI-powered describer**: Genera descrizioni da naming + context
- **PII Tagger**: Automaticamente marca campi PII (email, phone, SSN)
- **One-click apply**: Aggi

unge tutte le extended properties

**Priority**: 🔥 HIGH

---

### UC12: Debug Versions Missing
**Pain Point**: SP senza versione DEBUG (da Wiki storeprocess.md)

**Wiki Standard**:
> "Versione `sp_debug_*` per ambienti test"

**Example**:
```sql
-- PROD version
PORTAL.sp_insert_tenant

-- DEBUG version (dovrebbe esistere!)
PORTAL.sp_debug_insert_tenant  -- ❌ Missing!
```

**Solution**:
- **Debug Version Checker**: Trova SP senza coppia DEBUG
- **Auto-generator**: Crea versione DEBUG con:
  - Logging verboso
  - Parametri mock
  - Rollback automatico
  - Output dettagliato

**Priority**: 🟡 MEDIUM

---

### UC13: Conversational Intelligence Non-Ready
**Pain Point**: SP non AI-friendly (da Wiki architecture master)

**Wiki Standard**:
> "Output strutturato e standard (OK/KO, ID, messaggio), facilmente parsabile da bot"

**Checklist da Wiki**:
- [ ] Parametri chiari e documentati
- [ ] Logging centralizzato (`sp_log_stats_execution`)
- [ ] Output JSON-friendly (`status`, `id`, `error_message`, `rows`)
- [ ] Extended property con esempi prompt

**Solution**:
- **AI-Readiness Score**: Valuta SP 0-100
- **Output Standardizer**: Converte return ad hoc → standard
- **Logging Injector**: Aggiunge chiamata a `sp_log_stats_execution`
- **Prompt Generator**: Crea esempi di chiamata per agents

**Priority**: 🔥 CRITICAL (core differentiator!)

---

### UC14: Sequence Drift (NDG Generation)
**Pain Point**: Sequence fuori sync tra ambienti

**Wiki Standard**:
> "Sequence, function e store procedure sempre in doppia versione: PROD e DEBUG"

**Example**:
```sql
-- DEV: Sequence started at 1000
-- PROD: Sequence started at 1

-- Result: NDG collisions on sync!
```

**Solution**:
- **Sequence Inventory**: Confronta MIN/MAX/CURRENT tra envs
- **Drift Detector**: Identifica sequenze non allineate
- **Re-seed Script Generator**: Script per allineare PROD
- **NDG Validator**: Check unicità cross-environment

**Priority**: 🟡 MEDIUM

---

### UC15: Migration File Lint
**Pain Point**: Migrazioni non seguono convenzioni (da Wiki howto-create-table)

**Wiki Best Practices**:
- 1 file = 1 scopo
- Commento/header con scopo e ticket
- Naming standard `V{N}__{description}.sql`
- Idempotent (IF NOT EXISTS)

**Common Violations**:
- ❌ `migration.sql` (no version number!)
- ❌ Nessun header comment
- ❌ Mix di CREATE TABLE + INSERT in stesso file
- ❌ No idempotency (fail if re-run)

**Solution**:
- **Migration File Linter**: Check naming, structure, idempotency
- **Auto-fixer**: Aggiunge headers, split multi-purpose files
- **Convention Reporter**: Export violations as CI/CD artifact

**Priority**: 🟡 MEDIUM

---

### UC16: Schema Inventory Drift
**Pain Point**: Inventario DDL non allineato con DB reale

**Wiki Standard**:
> "Genera/aggiorna ERD & SP Catalog con `npm run db:generate-docs` dopo modifiche strutturali"

**Current Problem**:
- Dev fa `ALTER TABLE` direttamente su DB
- Non aggiorna migration files
- Inventario Wiki obsoleto
- Blueprint JSON out-of-sync

**Solution**:
- **Reverse Engineer**: Scan DB reale → genera blueprint JSON
- **Drift Report**: Confronta Migration files vs DB vs Blueprint vs Wiki
- **Auto-sync**: Opzione per aggiornare tutto da DB (dangerous ma utile)
- **CI/CD Gate**: Block merge se drift detected

**Priority**: 🔥 HIGH

---

### UC17: Excel-to-Intent Workflow
**Pain Point**: Non-tecnici non sanno scrivere JSON intent

**Wiki Solution**:
> "Template Excel-friendly (CSV) per compilazione facile anche da non esperti"

**Current Workflow**:
1. Product owner compila Excel
2. Dev converte manualmente a JSON
3. Passa ad agent_dba
4. Genera migration

**Desired**:
- ✅ **Drag & Drop Excel**: UI web per upload CSV
- ✅ **Preview**: Mostra tabella renderizzata
- ✅ **Validate**: Check naming, types, constraints
- ✅ **One-Click Generate**: CSV → Intent JSON → Migration → Apply

**Priority**: 🟡 MEDIUM (great UX!)

---

### UC18: RLS Policy Tester
**Pain Point**: RLS attivo ma non testato = security risk!

**Wiki Warning**:
> "Abilita security policy solo dopo aver verificato che l'app imposti SESSION_CONTEXT"

**Current Issue**:
- RLS policy created
- Policy enabled in PROD
- App non setta `SESSION_CONTEXT('tenant_id')`
- Result: Query returns 0 rows! (app broken)

**Solution**:
- **RLS Test Generator**: Auto-genera test cases per ogni policy
- **Context Simulator**: Testa query con/senza SESSION_CONTEXT
- **App Integration Checker**: Verifica che API setta context
- **Safe Enable**: Step-by-step wizard per abilitare RLS

**Priority**: 🔥 CRITICAL (security + reliability)

---

### UC19: PII/Masking Audit
**Pain Point**: Non so quali campi contengono PII

**Wiki Standard**:
> "Mascheramento e RLS sempre previsti dove serve"

**GDPR Requirement**:
- Identify all PII fields
- Document data retention
- Apply masking for non-admin users
- Audit access logs

**Solution**:
- **PII Detector**: Scan per pattern (email, phone, SSN, IP, etc.)
- **Masking Policy Generator**: Create SQL masking functions
- **Compliance Reporter**: Export PII inventory per GDPR
- **Access Audit**: Who accessed PII when?

**Priority**: 🔥 CRITICAL (legal compliance!)

---

### UC20: Migration Rollback Plan
**Pain Point**: Deploy fails, how to rollback?

**Current Situation**:
- Migration applicate
- App breaks in PROD
- Panico: come tornare indietro?
- Nessun rollback script preparato

**Solution**:
- **Auto Rollback Generator**: Per ogni UP migration, genera DOWN
- **Snapshot Before Deploy**: Backup schema pre-migration
- **One-Click Rollback**: Esegue DOWN migration
- **Data Preservation Check**: Warning se rollback perde dati

**Priority**: 🔥 HIGH

---

### UC21: INSERT Without Column List
**Pain Point**: INSERT senza lista colonne - dipende dall'ordine fisico della tabella

**Problem**:
```sql
-- ❌ BAD - Dipende da ordine colonne!
INSERT INTO LEGAL_ENTITY
SELECT le_code, branch, name, ...
FROM source_table;

-- Se qualcuno fa ALTER TABLE ADD COLUMN a metà tabella, questo esplode!
```

**Impact**:
- ❌ Fragile - cambia ordine colonne → query broken
- ❌ Difficile da leggere - quali colonne stai inserendo?
- ❌ Non esplicito su NULL/DEFAULT handling

**Desired Solution**:
```sql
-- ✅ GOOD - Lista colonne esplicita
INSERT INTO LEGAL_ENTITY (
  legal_entity_code,
  branch,
  name,
  status,
  created_by,
  created_at
)
SELECT 
  le.code,
  le.branch,
  le.name,
  'ACTIVE',
  @created_by,
  SYSUTCDATETIME()
FROM source_table le;
```

**Tool Feature**:
- ✅ **Column List Validator**: Detect INSERT without column list
- ✅ **Auto-fixer**: Generate explicit column list from table schema
- ✅ **CI/CD Blocker**: Block commits with implicit INSERT

**Priority**: 🟡 MEDIUM

---

### UC22: Missing NOT NULL Columns in INSERT
**Pain Point**: INSERT manca colonne chiave NOT NULL/PK

**Example Problem**:
```sql
-- ❌ BAD
INSERT INTO LEGAL_ENTITY (legal_entity_code, branch)
SELECT le_code, 'IN'  -- Wrong! Should be 'GLD&A'
FROM source;

-- Missing: status (NOT NULL), created_by (NOT NULL), created_at (NOT NULL)
-- Wrong value: branch should be 'GLD&A' not 'IN'
-- Result: INSERT fails or inserts wrong data!
```

**Current Situation**:
- Dev non sa quali colonne sono NOT NULL
- Runtime error solo quando esegue INSERT
- Dati parziali se alcuni campi hanno DEFAULT

**Desired Solution**:
- ✅ **NOT NULL Column Checker**: 
  ```
  INSERT into LEGAL_ENTITY...
  
  ⚠️ Missing NOT NULL columns:
    - status (NVARCHAR(32) NOT NULL)
    - created_by (NVARCHAR(255) NOT NULL)  
    - created_at (DATETIME2 NOT NULL)
  
  💡 Add these to your INSERT:
    status = 'ACTIVE',
    created_by = @created_by,
    created_at = SYSUTCDATETIME()
  ```

- ✅ **INSERT Template Generator**: "Voglio inserire in LEGAL_ENTITY" → genera skeleton con tutte colonne NOT NULL
- ✅ **Pre-execution Validation**: Check before running INSERT

**Priority**: 🔥 HIGH

---

### UC23: SELECT DISTINCT "A Caso" in INSERT
**Pain Point**: SELECT DISTINCT nasconde moltiplicazioni dati

**Problem**:
```sql
-- ❌ VERY BAD
INSERT INTO LEGAL_ENTITY (legal_entity_code, branch)
SELECT DISTINCT  -- ⚠️ Perché DISTINCT??
  le.code,
  perm.branch
FROM legal_entities le
JOIN perimeter p ON le.id = p.legal_entity_id
JOIN local_hub lh ON le.id = lh.legal_entity_id;

-- Se perimeter o local_hub hanno N righe per lo stesso LE:
--   - Senza DISTINCT: N insert duplicati (ERROR!)
--   - Con DISTINCT: nasconde il problema (silently wrong data!)
```

**Real Issue**:
- **Root cause**: JOIN sbagliato (moltiplicazione righe)
- **Symptom**: DISTINCT "fix" apparente
- **Result**: Dati inconsistenti o missing

**Desired Solution**:
- ✅ **DISTINCT Smell Detector**: 
  ```
  ⚠️ Found SELECT DISTINCT in INSERT statement
  
  Common causes:
  1. JOIN moltiplicates rows (fix JOIN logic)
  2. Source data has duplicates (deduplicate source first)
  3. Missing GROUP BY
  
  💡 Suggestions:
  - Review JOINs for cartesian products
  - Add GROUP BY if aggregating
  - Use ROW_NUMBER() / PARTITION BY for intentional dedup
  ```

- ✅ **JOIN Cardinality Analyzer**: "This JOIN produces 1:N relationship - are you sure?"
- ✅ **Alternative Suggester**: 
  ```sql
  -- Instead of DISTINCT, use:
  SELECTле.code, lh.branch
  FROM legal_entities le
  CROSS APPLY (
    SELECT TOP 1 branch 
    FROM local_hub 
    WHERE legal_entity_id = le.id
    ORDER BY priority
  ) lh;
  ```

**Priority**: 🟡 MEDIUM (but important for data quality!)

---

### UC24: SQL Code Indentation
**Pain Point**: SQL non indentato - illeggibile e difficile da debuggare

**Problem**:
```sql
-- ❌ BAD - Zero indentation!
CREATE PROCEDURE sp_get_user @user_id INT AS BEGIN SET NOCOUNT ON;
SELECT u.id,u.name,u.email FROM USERS u WHERE u.id=@user_id AND u.deleted_at IS NULL;END;

-- Impossibile leggere, capire nesting, trovare errori
```

**Impact**:
- ❌ Code review difficili
- ❌ Debugging lento
- ❌ Manutenzione rischiosa
- ❌ AI agent fatica a comprendere struttura

**Desired Solution**:
```sql
-- ✅ GOOD - Properly indented
CREATE PROCEDURE PORTAL.sp_get_user
  @user_id INT
AS
BEGIN
  SET NOCOUNT ON;
  
  SELECT 
    u.id,
    u.name,
    u.email
  FROM USERS u
  WHERE u.id = @user_id
    AND u.deleted_at IS NULL;
END;
```

**Tool Features**:
- ✅ **SQL Formatter**: Auto-format con regole standard
  - 2 spaces indentation (or 4, configurable)
  - Keywords UPPERCASE
  - Comma-first or comma-last (configurable)
  - Align keywords (SELECT, FROM, WHERE, JOIN)

- ✅ **Pre-commit Hook**: Block commits con SQL non formattato

- ✅ **Format on Save**: IDE integration

- ✅ **Batch Formatter**: Formatta tutti i file migration in un colpo

**Configuration Example**:
```json
{
  "indent": 2,
  "keywordCase": "UPPER",
  "commaStyle": "trailing",
  "alignKeywords": true,
  "maxLineLength": 120
}
```

**Priority**: 🟡 MEDIUM

---

### UC25: Step-by-Step Comments Missing
**Pain Point**: SP complesse senza commenti - nessuno capisce cosa fa

**Problem**:
```sql
-- ❌ BAD - No comments!
CREATE PROCEDURE sp_complex_operation
AS
BEGIN
  DECLARE @temp TABLE (id INT, val NVARCHAR(100));
  
  INSERT INTO @temp
  SELECT id, name FROM source WHERE status = 'ACTIVE';
  
  UPDATE target
  SET val = t.val
  FROM target tgt
  JOIN @temp t ON tgt.id = t.id;
  
  DELETE FROM archive WHERE id NOT IN (SELECT id FROM @temp);
END;

-- Che diavolo fa questa SP??
```

**Impact**:
- ❌ Nessuno capisce logica senza leggere tutto
- ❌ Manutenzione impossibile dopo 6 mesi
- ❌ Onboarding lento per nuovi dev
- ❌ AI agent non può spiegare funzionamento

**Desired Solution**:
```sql
-- ✅ GOOD - Step-by-step comments
CREATE PROCEDURE PORTAL.sp_sync_active_entities
  @created_by NVARCHAR(255)
AS
BEGIN
  SET NOCOUNT ON;
  
  -- Step 1: Prepare temp table for active entities
  -- Purpose: Hold current active entities for processing
  DECLARE @active_entities TABLE (
    entity_id INT,
    entity_name NVARCHAR(100)
  );
  
  -- Step 2: Load active entities from source
  -- Filters: Only status='ACTIVE', excludes soft-deleted
  INSERT INTO @active_entities (entity_id, entity_name)
  SELECT 
    id, 
    name 
  FROM source_entities
  WHERE status = 'ACTIVE'
    AND deleted_at IS NULL;
  
  -- Step 3: Sync to target table
  -- Updates existing records with latest names
  UPDATE target_entities
  SET 
    entity_name = ae.entity_name,
    updated_at = SYSUTCDATETIME(),
    updated_by = @created_by
  FROM target_entities te
  INNER JOIN @active_entities ae ON te.entity_id = ae.entity_id;
  
  -- Step 4: Clean up archive
  -- Removes archived entities that are no longer active
  DELETE FROM archive_entities
  WHERE entity_id NOT IN (
    SELECT entity_id FROM @active_entities
  );
  
  -- Step 5: Log execution
  EXEC sp_log_stats_execution 
    @procedure_name = 'sp_sync_active_entities',
    @rows_affected = @@ROWCOUNT;
END;
```

**Tool Features**:
- ✅ **Comment Template Generator**: 
  ```
  Analyze SP structure → generate comment skeleton:
  -- Step 1: [Describe what this block does]
  -- Step 2: [Describe next block]
  ...
  ```

- ✅ **AI-Powered Describer**: 
  ```sql
  -- Auto-generated comment:
  -- This block filters active users and updates their status
  SELECT ... FROM ... WHERE ...
  ```

- ✅ **Comment Coverage Checker**:
  ```
  ⚠️ This SP has 127 lines but only 2 comments
  
  Recommended: 1 comment block every 10-15 lines
  Missing comments at:
    - Line 23 (complex JOIN)
    - Line 45 (temp table usage)
    - Line 89 (dynamic SQL)
  ```

- ✅ **Commenting Standards**:
  - Header comment: Purpose, params, return, author, date
  - Step comments: What + Why (not How - code shows that)
  - Complex logic: Explain business rule
  - Magic numbers: Why this value?

**Example Header**:
```sql
/*
 * Procedure: sp_sync_active_entities
 * Purpose: Sync active entities from source to target, clean archive
 * 
 * Parameters:
 *   @created_by - User who triggered sync (for audit)
 * 
 * Returns: Number of entities synced
 * 
 * Called by: Daily sync job, manual admin trigger
 * 
 * Author: DBA Team
 * Created: 2026-01-15
 * Modified: 2026-01-15 - Added archive cleanup
 */
```

**Priority**: 🟡 MEDIUM (but critical for maintainability!)

---

### UC26: Dependency Tracking & Impact Analysis
**Pain Point**: Non so dove viene usata una tabella/colonna - impossibile capire impatto di modifiche

**Scenario**:
```
DBA: "Voglio rinominare la colonna USERS.email"
Dev: "ASPETTA! È usata in 47 stored procedures!"
DBA: "Quali?? Come faccio a saperlo??"
```

**Current Situation**:
- Cerca manualmente in tutti gli SP
- Grep nel codice (soggetto a errori)
- Nessuna visibilità su viste, funzioni, FK
- Rischio di rompere tutto in PROD

**Impact**:
- ❌ Change management rischioso
- ❌ Refactoring impossibile
- ❌ Impact analysis manuale (ore di lavoro)
- ❌ Breaking changes accidentali

**Desired Solution**:
- ✅ **Dependency Graph JSON**: Export completo di tutti gli oggetti e le loro dipendenze
- ✅ **Impact Analyzer**: "Cosa succede se cambio X?"
- ✅ **Reverse Lookup**: "Dove viene usata questa colonna?"
- ✅ **Searchable Index**: UI per cercare dipendenze

**JSON Schema Example**:
```json
{
  "database": "EASYWAY_PORTAL_DEV",
  "extracted_at": "2026-01-15T08:00:00Z",
  "objects": {
    "tables": [
      {
        "schema": "PORTAL",
        "name": "USERS",
        "columns": [
          {
            "name": "email",
            "type": "NVARCHAR(320)",
            "is_nullable": false,
            "used_by": "sp_insert_user|sp_update_user|sp_get_user_by_email|vw_active_users"
          }
        ],
        "referenced_by": {
          "foreign_keys": ["ORDERS.user_id", "SESSIONS.user_id"],
          "procedures": ["sp_insert_user", "sp_update_user", "sp_delete_user"],
          "views": ["vw_active_users", "vw_user_profile"],
          "functions": ["fn_get_user_tenant"]
        }
      }
    ],
    "procedures": [
      {
        "schema": "PORTAL",
        "name": "sp_insert_user",
        "depends_on": {
          "tables": ["USERS", "TENANT", "STATS_EXECUTION_LOG"],
          "columns": [
            "USERS.email",
            "USERS.display_name",
            "USERS.tenant_id",
            "TENANT.id"
          ],
          "functions": ["fn_generate_user_code"],
          "sequences": ["seq_user_id"]
        },
        "called_by": ["sp_register_tenant_and_user", "API.CreateUser"]
      }
    ],
    "views": [
      {
        "schema": "PORTAL",
        "name": "vw_active_users",
        "depends_on": {
          "tables": ["USERS", "TENANT"],
          "columns": ["USERS.email", "USERS.status", "TENANT.name"]
        },
        "used_by": ["sp_get_all_users", "REPORTING.rpt_users"]
      }
    ]
  }
}
```

**SQL Implementation avec STRING_AGG**:
```sql
-- Function per estrarre dipendenze
CREATE FUNCTION fn_get_column_usage
(
  @schema_name NVARCHAR(128),
  @table_name NVARCHAR(128),
  @column_name NVARCHAR(128)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
  DECLARE @usage NVARCHAR(MAX);
  
  -- Aggrega tutti gli oggetti che usano questa colonna
  SELECT @usage = STRING_AGG(
    object_type + '.' + object_name, 
    '|'
  ) WITHIN GROUP (ORDER BY object_name)
  FROM (
    -- Stored Procedures
    SELECT 
      'SP' AS object_type,
      OBJECT_NAME(object_id) AS object_name
    FROM sys.sql_expression_dependencies
    WHERE referenced_schema_name = @schema_name
      AND referenced_entity_name = @table_name
      AND OBJECT_TYPE(referencing_id) = 'P'
    
    UNION
    
    -- Views
    SELECT 
      'VIEW' AS object_type,
      OBJECT_NAME(object_id) AS object_name
    FROM sys.sql_expression_dependencies
    WHERE referenced_schema_name = @schema_name
      AND referenced_entity_name = @table_name
      AND OBJECT_TYPE(referencing_id) = 'V'
    
    UNION
    
    -- Functions
    SELECT 
      'FN' AS object_type,
      OBJECT_NAME(object_id) AS object_name
    FROM sys.sql_expression_dependencies
    WHERE referenced_schema_name = @schema_name
      AND referenced_entity_name = @table_name
      AND OBJECT_TYPE(referencing_id) IN ('FN', 'IF', 'TF')
  ) deps;
  
  RETURN ISNULL(@usage, 'NONE');
END;

-- Query per dependency export completo
WITH all_dependencies AS (
  SELECT 
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.IS_NULLABLE,
    -- Usa la function per ottenere tutti gli usi
    dbo.fn_get_column_usage(t.TABLE_SCHEMA, t.TABLE_NAME, c.COLUMN_NAME) AS used_by
  FROM INFORMATION_SCHEMA.TABLES t
  INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA 
    AND t.TABLE_NAME = c.TABLE_NAME
  WHERE t.TABLE_TYPE = 'BASE TABLE'
)
SELECT 
  TABLE_SCHEMA,
  TABLE_NAME,
  -- Aggrega colonne e usi in un unico JSON
  STRING_AGG(
    CONCAT(
      COLUMN_NAME, ':', 
      DATA_TYPE, '|', 
      used_by
    ),
    ';'
  ) AS columns_and_usage
FROM all_dependencies
GROUP BY TABLE_SCHEMA, TABLE_NAME
FOR JSON PATH;
```

**Tool Features**:

1. **Full Dependency Extractor**:
   ```bash
   npm run db:extract-dependencies --output deps.json
   ```
   Output: Complete dependency graph in JSON

2. **Impact Analyzer**:
   ```bash
   npm run db:impact-analysis --table USERS --column email
   ```
   Output:
   ```
   ⚠️ Impact Analysis: USERS.email
   
   This column is used by:
   - 12 Stored Procedures
   - 3 Views
   - 1 Function
   - 2 Foreign Keys
   
   Total objects impacted: 18
   
   🔥 CRITICAL dependencies:
     - sp_authenticate_user (login flow!)
     - vw_active_users (used by API)
   
   💡 Recommendation: 
     Instead of renaming, consider aliasing or creating migration path
   ```

3. **Reverse Lookup UI**:
   ```
   Search: "email"
   
   Results:
   📊 Tables with 'email' column:
     - PORTAL.USERS (320 NVARCHAR)
     - PORTAL.CUSTOMERS (255 VARCHAR) ⚠️ Type mismatch!
   
   📝 Procedures using 'email':
     - sp_insert_user
     - sp_update_user
     - sp_get_user_by_email
     ...
   
   👁️ Views with 'email':
     - vw_active_users
     - vw_user_profile
   ```

4. **Dependency Visualization**:
   - Graph view (tipo dbdiagram.io)
   - Show table → SP → functions connections
   - Highlight circular dependencies
   - Export as PNG/SVG

**Integration con Metadata Diff**:
```javascript
// Confronta dependencies tra DEV e PROD
const devDeps = await extractDependencies('DEV');
const prodDeps = await extractDependencies('PROD');

const diff = {
  new_dependencies: findNew(devDeps, prodDeps),
  broken_dependencies: findBroken(devDeps, prodDeps),
  changed_dependencies: findChanged(devDeps, prodDeps)
};

// Example output:
{
  "new_dependencies": [
    "sp_new_feature → USERS.new_column (not in PROD yet!)"
  ],
  "broken_dependencies": [
    "vw_legacy → OLD_TABLE (table dropped in DEV)"
  ]
}
```

**Searchable Index Structure**:
```json
{
  "search_index": {
    "by_column": {
      "email": [
        "PORTAL.USERS.email",
        "PORTAL.CUSTOMERS.email"
      ]
    },
    "by_table": {
      "USERS": {
        "referenced_by": ["ORDERS", "SESSIONS"],
        "references": ["TENANT"],
        "procedures": ["sp_insert_user", "sp_update_user"]
      }
    },
    "by_procedure": {
      "sp_insert_user": {
        "tables": ["USERS", "TENANT"],
        "columns": ["USERS.email", "USERS.tenant_id"]
      }
    }
  }
}
```

**Priority**: 🔥 CRITICAL (essential for safe refactoring!)

---

### UC27: DROP/CREATE Loses Permissions (Use ALTER)
**Pain Point**: Migration usa DROP/CREATE per SP/Views - perde tutti i GRANT

**Problem**:
```sql
-- ❌ BAD - Loses all permissions!
DROP PROCEDURE IF EXISTS sp_get_users;
GO

CREATE PROCEDURE sp_get_users
AS
BEGIN
  SELECT * FROM USERS;
END;
GO

-- Result: Tutti i GRANT persi!
-- Utente "reporting_user" aveva EXEC, ora non può più eseguire!
```

**Impact**:
- ❌ Permessi persi dopo ogni deploy
- ❌ Applicazioni broken (permission denied)
- ❌ DBA deve riapplicare GRANT manualmente
- ❌ Nessun tracking di quali permessi esistevano

**Current Situation**:
- Migrations usano DROP + CREATE pattern
- Dopo deploy: "Permission denied" errors in PROD
- Emergency: DBA deve scoprire e riapplicare GRANT
- Downtime applicativo

**Desired Solution (SQL Server 2016+)**:
```sql
-- ✅ GOOD - Preserves permissions!
CREATE OR ALTER PROCEDURE sp_get_users
AS
BEGIN
  SELECT * FROM USERS WHERE deleted_at IS NULL;
END;

-- Permissions preserved automatically!
```

**For Older SQL Server (<2016)**:
```sql
-- ✅ ALTERNATIVE - Use ALTER if exists
IF OBJECT_ID('sp_get_users', 'P') IS NOT NULL
  -- Alter existing (keeps permissions)
  EXEC('ALTER PROCEDURE sp_get_users AS BEGIN SELECT * FROM USERS; END');
ELSE
  -- Create new
  EXEC('CREATE PROCEDURE sp_get_users AS BEGIN SELECT * FROM USERS; END');
```

**Database Support Matrix**:
```
SQL Server 2019+:  ✅ CREATE OR ALTER (native)
SQL Server 2016+:  ✅ CREATE OR ALTER (native)
SQL Server 2014:   ⚠️ Use IF EXISTS + ALTER pattern
PostgreSQL:        ✅ CREATE OR REPLACE (native)
Oracle:            ✅ CREATE OR REPLACE (native)
MySQL:             ❌ Must DROP/CREATE + re-grant
```

**Tool Features**:

1. **Migration Pattern Detector**:
   ```bash
   npm run db:check-permissions-loss
   ```
   Output:
   ```
   ⚠️ Found 12 migrations using DROP/CREATE pattern
   
   Files with permission loss risk:
   - V6__stored_procedures_core.sql (8 procedures)
   - V9__stored_procedures_users.sql (4 procedures)
   
   💡 Recommendation:
   Replace with CREATE OR ALTER to preserve permissions
   
   SQL Server version: 2019 → ✅ Supports CREATE OR ALTER
   ```

2. **Auto-Converter**:
   ```sql
   -- Before (loses permissions):
   DROP PROCEDURE sp_insert_user;
   GO
   CREATE PROCEDURE sp_insert_user...
   
   -- After (preserves permissions):
   CREATE OR ALTER PROCEDURE sp_insert_user...
   ```

3. **Permission Backup/Restore**:
   ```sql
   -- Backup permissions before migration
   CREATE PROCEDURE sp_backup_permissions
   AS
   BEGIN
     SELECT 
       OBJECT_NAME(major_id) AS object_name,
       USER_NAME(grantee_principal_id) AS grantee,
       permission_name,
       state_desc
     INTO #permissions_backup
     FROM sys.database_permissions
     WHERE major_id IN (
       SELECT object_id 
       FROM sys.objects 
       WHERE type IN ('P', 'V', 'FN')
     );
   END;
   
   -- Restore permissions after migration
   CREATE PROCEDURE sp_restore_permissions
   AS
   BEGIN
     DECLARE @sql NVARCHAR(MAX);
     
     SELECT @sql = STRING_AGG(
       CONCAT(
         state_desc, ' ', permission_name, 
         ' ON ', object_name, 
         ' TO ', grantee
       ),
       '; '
     )
     FROM #permissions_backup;
     
     EXEC sp_executesql @sql;
   END;
   ```

4. **Pre-deployment Permission Check**:
   ```bash
   npm run db:check-permissions --env PROD
   ```
   Output:
   ```
   📊 Current Permissions on Objects to Modify:
   
   sp_insert_user:
     - EXECUTE granted to role_api_user
     - EXECUTE granted to role_admin
   
   sp_get_users:
     - EXECUTE granted to role_reporting
     - EXECUTE granted to role_readonly
   
   vw_active_users:
     - SELECT granted to role_reporting
   
   ⚠️ These permissions will be preserved with CREATE OR ALTER
   ✅ Safe to deploy
   ```

**Migration Template Generator**:
```sql
-- Template for SQL Server 2019+
CREATE OR ALTER PROCEDURE [{schema}].[{name}]
  {parameters}
AS
BEGIN
  SET NOCOUNT ON;
  
  {body}
END;

-- Template for SQL Server 2014
IF OBJECT_ID('{schema}.{name}', 'P') IS NOT NULL
BEGIN
  EXEC('
    ALTER PROCEDURE [{schema}].[{name}]
      {parameters}
    AS
    BEGIN
      SET NOCOUNT ON;
      {body}
    END
  ');
END
ELSE
BEGIN
  EXEC('
    CREATE PROCEDURE [{schema}].[{name}]
      {parameters}
    AS
    BEGIN
      SET NOCOUNT ON;
      {body}
    END
  ');
END;
```

**Views Pattern**:
```sql
-- ✅ GOOD - Preserves SELECT permissions
CREATE OR ALTER VIEW vw_active_users
AS
  SELECT id, name, email 
  FROM USERS 
  WHERE deleted_at IS NULL;
```

**Functions Pattern**:
```sql
-- ✅ GOOD - Preserves EXEC permissions
CREATE OR ALTER FUNCTION fn_get_user_tenant
(
  @user_id INT
)
RETURNS NVARCHAR(50)
AS
BEGIN
  DECLARE @tenant_id NVARCHAR(50);
  
  SELECT @tenant_id = tenant_id 
  FROM USERS 
  WHERE id = @user_id;
  
  RETURN @tenant_id;
END;
```

**Guardrail Integration**:
```markdown
## G11: Preserve Permissions (NEW)
**Severity**: 🔥 CRITICAL  
**Owner**: agent_dba

**Rules**:
- [ ] Use CREATE OR ALTER for SP/Views/Functions (SQL Server 2016+)
- [ ] Never use DROP PROCEDURE + CREATE PROCEDURE
- [ ] Never use DROP VIEW + CREATE VIEW
- [ ] Backup permissions before risky migrations
- [ ] Verify permissions after deploy

**Exceptions**:
- MySQL (doesn't support CREATE OR ALTER)
- Must rename object (use sp_rename + ALTER)

**Auto-fix Available**: ✅ Yes - convert DROP/CREATE to CREATE OR ALTER
```

**CI/CD Gate**:
```yaml
# .github/workflows/db-migration-check.yml
- name: Check Permission Preservation
  run: |
    npm run db:check-permissions-loss
    if [ $? -ne 0 ]; then
      echo "❌ Migration uses DROP/CREATE pattern - will lose permissions!"
      exit 1
    fi
```

**Priority**: 🔥 HIGH (prevents production incidents!)

---

### UC28: User/Role/Permission Management (SQL Server)
**Pain Point**: Nessun sistema per gestire utenti, ruoli e permessi - tutto manuale e non tracciato

**Current Situation**:
- CREATE USER/ROLE fatto manualmente via SSMS
- GRANT/REVOKE fatti ad-hoc senza documentazione
- Nessun template standard per ruoli applicativi
- Impossibile replicare setup tra DEV/PROD
- Nessun audit trail delle modifiche permessi

**Impact**:
- ❌ Setup manuale lento e error-prone
- ❌ Drift tra ambienti (DEV ha permessi diversi da PROD)
- ❌ Onboarding nuovo applicativo richiede ore
- ❌ Nessuna tracciabilità chi ha accesso a cosa
- ❌ Compliance/audit difficile

**Desired Solution**:
- ✅ **Template-based Role Creation**: Ruoli standard (readonly, api_user, admin)
- ✅ **User Provisioning Scripts**: Automated user creation
- ✅ **Permission Management**: Grant/Revoke tracked in migrations
- ✅ **Cross-environment Sync**: Deploy same security model everywhere
- ✅ **Audit Trail**: Track all permission changes

---

**SQL Server Security Model**:

```
Server Level:                Database Level:
├── Logins                   ├── Users (mapped to logins)
│   ├── SQL Auth            │   ├── Database Roles
│   └── Windows Auth        │   └── Permissions
└── Server Roles            └── Schemas
```

---

**Standard Role Templates (SQL Server)**:

### 1. **role_readonly** - Read-only access
```sql
-- Create role
CREATE ROLE role_readonly;

-- Grant SELECT on all tables
GRANT SELECT ON SCHEMA::PORTAL TO role_readonly;
GRANT SELECT ON SCHEMA::REPORTING TO role_readonly;

-- Grant VIEW DEFINITION (can see object definitions)
GRANT VIEW DEFINITION TO role_readonly;

-- DENY dangerous operations
DENY INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::PORTAL TO role_readonly;
```

### 2. **role_api_user** - Application user
```sql
-- Create role
CREATE ROLE role_api_user;

-- Grant EXECUTE on stored procedures only (no direct table access!)
GRANT EXECUTE ON SCHEMA::PORTAL TO role_api_user;

-- Specific table permissions if needed
GRANT SELECT, INSERT, UPDATE ON PORTAL.USERS TO role_api_user;
GRANT SELECT ON PORTAL.CONFIGURATION TO role_api_user;

-- DENY direct modifications to sensitive tables
DENY DELETE ON PORTAL.USERS TO role_api_user;
DENY ALL ON PORTAL.ACL TO role_api_user;
```

### 3. **role_admin** - DBA/Admin access
```sql
-- Create role
CREATE ROLE role_admin;

-- Grant full access
GRANT CONTROL ON SCHEMA::PORTAL TO role_admin;
ALTER ROLE db_owner ADD MEMBER role_admin;

-- Grant ALTER on objects (can modify structure)
GRANT ALTER ANY SCHEMA TO role_admin;
GRANT CREATE TABLE TO role_admin;
GRANT CREATE PROCEDURE TO role_admin;
```

### 4. **role_reporting** - Analytics/BI access
```sql
-- Create role
CREATE ROLE role_reporting;

-- Grant SELECT on views only (not base tables)
GRANT SELECT ON SCHEMA::REPORTING TO role_reporting;

-- Grant SELECT on specific base tables if needed
GRANT SELECT ON PORTAL.USERS TO role_reporting;
GRANT SELECT ON PORTAL.STATS_EXECUTION_LOG TO role_reporting;

-- Grant EXECUTE on reporting procedures
GRANT EXECUTE ON PORTAL.sp_get_dashboard_stats TO role_reporting;
```

---

**User Creation Patterns**:

### SQL Authentication User:
```sql
-- Step 1: Create server login
USE master;
CREATE LOGIN [api_user_dev] 
  WITH PASSWORD = '<strong_password>',
  DEFAULT_DATABASE = [EASYWAY_PORTAL_DEV],
  CHECK_POLICY = ON,
  CHECK_EXPIRATION = OFF;

-- Step 2: Create database user
USE [EASYWAY_PORTAL_DEV];
CREATE USER [api_user_dev] FOR LOGIN [api_user_dev];

-- Step 3: Add to role
ALTER ROLE role_api_user ADD MEMBER [api_user_dev];
```

### Azure AD Authentication User:
```sql
-- Step 1: Create user from Azure AD
CREATE USER [user@domain.com] FROM EXTERNAL PROVIDER;

-- Step 2: Add to role
ALTER ROLE role_readonly ADD MEMBER [user@domain.com];
```

### Managed Identity (Azure SQL):
```sql
-- Create user for managed identity
CREATE USER [my-app-service] FROM EXTERNAL PROVIDER;
ALTER ROLE role_api_user ADD MEMBER [my-app-service];
```

---

**Group Management (Windows Auth)**:

```sql
-- Create user from AD group
CREATE USER [DOMAIN\DevelopersGroup] FROM LOGIN [DOMAIN\DevelopersGroup];
ALTER ROLE role_api_user ADD MEMBER [DOMAIN\DevelopersGroup];

-- All AD group members automatically have permissions!
```

---

**Permission Audit Query**:

```sql
-- List all users and their roles/permissions
SELECT 
  dp.name AS principal_name,
  dp.type_desc AS principal_type,
  -- Roles
  STRING_AGG(r.name, ', ') AS roles,
  -- Direct permissions
  (
    SELECT STRING_AGG(
      perm.state_desc + ' ' + perm.permission_name + ' ON ' + 
      OBJECT_SCHEMA_NAME(perm.major_id) + '.' + OBJECT_NAME(perm.major_id),
      ', '
    )
    FROM sys.database_permissions perm
    WHERE perm.grantee_principal_id = dp.principal_id
  ) AS direct_permissions
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.type IN ('S', 'U', 'G') -- SQL user, Windows user, Windows group
  AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
GROUP BY dp.name, dp.type_desc, dp.principal_id
ORDER BY dp.name;
```

---

**Migration Template for Security Setup**:

```sql
-- V100__security_setup.sql

-- ============================================
-- STEP 1: Create Standard Roles
-- ============================================

IF DATABASE_PRINCIPAL_ID('role_readonly') IS NULL
  CREATE ROLE role_readonly;

IF DATABASE_PRINCIPAL_ID('role_api_user') IS NULL
  CREATE ROLE role_api_user;

IF DATABASE_PRINCIPAL_ID('role_admin') IS NULL
  CREATE ROLE role_admin;

IF DATABASE_PRINCIPAL_ID('role_reporting') IS NULL
  CREATE ROLE role_reporting;

-- ============================================
-- STEP 2: Grant Permissions to Roles
-- ============================================

-- role_readonly
GRANT SELECT ON SCHEMA::PORTAL TO role_readonly;
GRANT VIEW DEFINITION TO role_readonly;
DENY INSERT, UPDATE, DELETE ON SCHEMA::PORTAL TO role_readonly;

-- role_api_user
GRANT EXECUTE ON SCHEMA::PORTAL TO role_api_user;
GRANT SELECT, INSERT, UPDATE ON PORTAL.USERS TO role_api_user;
DENY DELETE ON PORTAL.USERS TO role_api_user;

-- role_admin
GRANT CONTROL ON SCHEMA::PORTAL TO role_admin;

-- role_reporting
GRANT SELECT ON SCHEMA::REPORTING TO role_reporting;
GRANT EXECUTE ON PORTAL.sp_get_dashboard_stats TO role_reporting;

-- ============================================
-- STEP 3: Create Application Users
-- (Only if not exists - idempotent)
-- ============================================

-- API User (SQL Auth)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'api_user_dev')
BEGIN
  EXEC('USE master; CREATE LOGIN [api_user_dev] WITH PASSWORD = ''<REPLACE_ME>'';');
END;

IF DATABASE_PRINCIPAL_ID('api_user_dev') IS NULL
BEGIN
  CREATE USER [api_user_dev] FOR LOGIN [api_user_dev];
  ALTER ROLE role_api_user ADD MEMBER [api_user_dev];
END;

-- Reporting User (Azure AD)
IF DATABASE_PRINCIPAL_ID('reporting@company.com') IS NULL
BEGIN
  CREATE USER [reporting@company.com] FROM EXTERNAL PROVIDER;
  ALTER ROLE role_reporting ADD MEMBER [reporting@company.com];
END;
```

---

**Tool Features**:

### 1. **Role Template Generator**:
```bash
npm run db:create-role --name role_custom --template api_user
```
Generates:
```sql
CREATE ROLE role_custom;
GRANT EXECUTE ON SCHEMA::PORTAL TO role_custom;
-- ... (based on template)
```

### 2. **User Provisioning**:
```bash
npm run db:create-user \
  --name "new_api_user" \
  --type sql_auth \
  --role role_api_user \
  --env DEV
```

### 3. **Permission Diff**:
```bash
npm run db:diff-permissions --source DEV --target PROD
```
Output:
```
⚠️ Permission Differences:

Users in DEV not in PROD:
  - dev_tester (role_api_user)
  
Roles with different permissions:
  - role_api_user
    DEV: EXECUTE ON PORTAL, SELECT ON USERS
    PROD: EXECUTE ON PORTAL only
    
💡 Missing in PROD:
  GRANT SELECT ON PORTAL.USERS TO role_api_user;
```

### 4. **Security Audit Report**:
```bash
npm run db:security-audit --output security-report.html
```
Generates HTML report with:
- All users and their roles
- All permissions granted
- Orphaned users (no login)
- Over-privileged users (db_owner)
- Unused roles

---

**Best Practices**:

✅ **DO**:
- Use roles, not direct user permissions
- Principle of least privilege
- Separate read/write roles
- Use managed identities (Azure) when possible
- Document why each permission is needed
- Version control all security scripts
- Test permissions in DEV before PROD

❌ **DON'T**:
- Grant db_owner to applications
- Use sa account for applications
- Hard-code passwords in scripts
- Grant permissions directly to users (use roles!)
- Share accounts between applications
- Skip permission testing

---

**Cross-Database Comparison**:

| Feature | SQL Server | PostgreSQL | Oracle |
|---------|-----------|------------|---------|
| Roles | ✅ CREATE ROLE | ✅ CREATE ROLE | ✅ CREATE ROLE |
| Users | ✅ CREATE USER | ✅ CREATE USER | ✅ CREATE USER |
| Managed Identity | ✅ Azure AD | ❌ | ❌ |
| Row-level Security | ✅ RLS Policies | ✅ RLS Policies | ✅ VPD |
| Group Support | ✅ Windows Auth | ✅ LDAP | ✅ LDAP |

---

**Integration with agent_dba**:

```javascript
// Agent action example
agent_dba.execute({
  action: "security:create-role",
  params: {
    roleName: "role_custom",
    template: "api_user",
    permissions: {
      schemas: ["PORTAL"],
      operations: ["EXECUTE", "SELECT"]
    }
  }
});

// Output:
{
  "status": "success",
  "sql_generated": "CREATE ROLE role_custom; GRANT ...",
  "applied": true,
  "users_in_role": []
}
```

---

**Guardrail Integration** (G12):

```markdown
## G12: Security Best Practices
**Severity**: 🔥 CRITICAL  
**Owner**: agent_dba + agent_security

**Rules**:
- [ ] Application users NEVER have db_owner
- [ ] Use roles, not direct grants
- [ ] SQL Auth passwords must be strong (12+ chars, complexity)
- [ ] Managed identities preferred over SQL auth
- [ ] No shared accounts between apps
- [ ] Document all permission grants (WHY in comments)
- [ ] Test permissions before PROD deploy

**Auto-fix Available**: ❌ No - security requires manual review
```

---

**Priority**: 🔥 HIGH (security + compliance!)

---

## 🎯 Feature Prioritization (Aggiornata)

### Must Have (Phase 1) - Foundation
1. ✅ UC1: SP Standards Validator
2. ✅ UC2: Technical Fields Checker
3. ✅ UC4: Gap Analyzer
4. ✅ UC10: Multi-Tenancy Audit
5. ✅ UC11: Extended Properties Missing
6. ✅ UC13: Conversational Intelligence Ready
7. ✅ UC16: Schema Inventory Drift
8. ✅ UC18: RLS Policy Tester
9. ✅ UC19: PII/Masking Audit
10. ✅ UC26: Dependency Tracking & Impact Analysis

### Should Have (Phase 2) - Intelligence
10. ✅ UC3: Business Key Detector
11. ✅ UC5: Smart Column Adder
12. ✅ UC9: Foreign Key Gaps
13. ✅ UC12: Debug Versions Missing
14. ✅ UC15: Migration File Lint
15. ✅ UC20: Migration Rollback Plan
16. ✅ UC21: INSERT Column List Required
17. ✅ UC22: Missing NOT NULL Columns
18. ✅ UC23: SELECT DISTINCT Smell Detector
19. ✅ UC24: SQL Code Indentation
20. ✅ UC25: Step-by-Step Comments
21. ✅ UC27: Preserve Permissions (CREATE OR ALTER)
22. ✅ UC28: User/Role/Permission Management (SQL Server)

### Nice to Have (Phase 3) - Optimization
16. ✅ UC6: Index Recommendations
17. ✅ UC7: Data Type Consistency
18. ✅ UC8: Constraint Naming
19. ✅ UC14: Sequence Drift
20. ✅ UC17: Excel-to-Intent Workflow

---

## 📊 Use Case Mapping to Wiki Standards

| Wiki Requirement | Use Case Addressing It |
|------------------|----------------------|
| Extended properties su ogni campo | UC11 |
| Output JSON-friendly per agents | UC13 |
| Versione DEBUG per SP | UC12 |
| RLS policy verification | UC10, UC18 |
| Mascheramento PII | UC19 |
| Logging centralizzato | UC13 |
| Campi tecnici standard | UC2 |
| Sequence PROD+DEBUG | UC14 |
| Inventory allineato | UC16 |
| Migrazioni idempotent | UC15 |
| FK su PORTAL schema | UC9 |

---

## 💭 Discussion Points

**Q1**: Campi tecnici - quale set è "standard"?
- Minimal: `created_at`, `updated_at`
- Standard: + `created_by`, `updated_by`
- Full: + `deleted_at`, `deleted_by`, `version`
- **EasyWay Wiki**: `created_by`, `created_at`, `updated_at`, `ext_attributes`, `status`

**Q2**: Auto-fix vs Manual?
- Auto-fix: Veloce ma rischioso
- Manual review: Lento ma safe
- **Hybrid**: Auto-fix per cose sicure (SET NOCOUNT ON), manual per schema changes
- **Wiki approach**: WhatIf mode first, then apply with gates

**Q3**: Breaking changes handling?
- Add column: Safe
- Rename column: BREAKING! Needs app deploy sync
- Drop column: BREAKING! Needs careful planning
- **Soluzione**: Change impact analyzer + UC20 rollback!

**Q4**: Conversational Intelligence - how deep?
- Level 1: Structured output (status/id/error)
- Level 2: + Logging + Extended properties
- Level 3: + Prompt examples + Test cases
- **Wiki target**: Level 3 for all objects!

---

**Ready per feedback e brainstorming!** 🚀

**Total Use Cases Identified**: 28  
**Critical Priority**: 10  
**High Priority**: 6 👈 +1 UC28!  
**Medium Priority**: 10  
**Low Priority**: 2
