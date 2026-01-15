# Database Best Practices - Standards & Conventions

## 📋 Naming Conventions

### Tables
- **Format**: `UPPERCASE_WITH_UNDERSCORES`
- **Examples**: `TENANT`, `USERS`, `CONFIGURATION`
- **Schema**: Always prefix with schema name in queries: `PORTAL.TENANT`

### Stored Procedures
- **Prefix**: `sp_`
- **Format**: `sp_action_entity`
- **Examples**:
  - ✅ `sp_insert_tenant`
  - ✅ `sp_update_user`
  - ✅ `sp_delete_configuration`
  - ❌ `InsertTenant` (missing sp_ prefix)
  - ❌ `sp_InsertTenant` (wrong casing)

### Functions
- **Prefix**: `fn_`
- **Format**: `fn_purpose_description`
- **Examples**:
  - ✅ `fn_rls_tenant_filter`
  - ✅ `fn_calculate_discount`
  - ❌ `TenantFilter` (missing fn_ prefix)

### Parameters
- **Prefix**: `@`
- **Format**: `@snake_case`
- **Standard Parameters**:
  - `@tenant_id NVARCHAR(50)` - Tenant identifier
  - `@user_id NVARCHAR(50)` - User identifier
  - `@created_by NVARCHAR(255)` - Actor/creator
  - `@updated_by NVARCHAR(255)` - Actor/updater
  - `@deleted_by NVARCHAR(255)` - Actor/deleter

### Variables
- **Prefix**: `@`
- **Format**: `@snake_case`
- **Examples**: `@start`, `@status`, `@rows`, `@err`

## ✅ Best Practices

### 1. SET NOCOUNT ON
**Always** include at the beginning of stored procedures:
```sql
CREATE PROCEDURE PORTAL.sp_example
AS
BEGIN
  SET NOCOUNT ON;  -- ✅ Required
  -- procedure logic
END
```

### 2. Schema Prefixing
**Always** use schema prefix:
```sql
-- ✅ Good
SELECT * FROM PORTAL.USERS WHERE tenant_id = @tenant_id;

-- ❌ Bad
SELECT * FROM USERS WHERE tenant_id = @tenant_id;
```

### 3. Avoid SELECT *
Specify columns explicitly:
```sql
-- ✅ Good
SELECT user_id, email, display_name 
FROM PORTAL.USERS;

-- ❌ Bad
SELECT * FROM PORTAL.USERS;
```

### 4. Error Handling
Use TRY...CATCH in all procedures:
```sql
BEGIN TRY
  BEGIN TRAN;
  -- operations
  COMMIT;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  SET @status = 'ERROR';
  SET @err = ERROR_MESSAGE();
END CATCH
```

### 5. Transaction Handling
Always have both COMMIT and ROLLBACK paths:
```sql
BEGIN TRAN;
-- operations
IF @error = 0
  COMMIT;
ELSE
  ROLLBACK;
```

### 6. Consistent Return Format
All procedures should return consistent format:
```sql
-- Standard return pattern
SELECT 
  @status AS status,
  @entity_id AS entity_id,
  @err AS error_message,
  @rows AS rows_affected;
```

### 7. Audit Logging
Use `sp_log_stats_execution` for all CRUD operations:
```sql
DECLARE @start DATETIME2 = SYSUTCDAT ETIME();
-- operations
DECLARE @end DATETIME2 = SYSUTCDATETIME();

EXEC PORTAL.sp_log_stats_execution
  @proc_name='sp_insert_tenant',
  @tenant_id=@tenant_id,
  @rows_inserted=@rows,
  @status=@status,
  @error_message=@err,
  @start_time=@start,
  @end_time=@end,
  @affected_tables='PORTAL.TENANT',
  @operation_types='INSERT',
  @created_by=@created_by;
```

### 8. Multi-Tenancy
Always filter by `tenant_id` for multi-tenant tables:
```sql
WHERE tenant_id = @tenant_id  -- ✅ Required for RLS compliance
```

### 9. Idempotency
Use IF NOT EXISTS for table creation:
```sql
IF OBJECT_ID('PORTAL.TENANT', 'U') IS NULL
BEGIN
  CREATE TABLE PORTAL.TENANT (...);
END
```

### 10. SQL Injection Prevention
Use sp_executesql instead of EXEC for dynamic SQL:
```sql
-- ✅ Good
EXEC sp_executesql 
  N'SELECT * FROM PORTAL.USERS WHERE user_id = @uid',
  N'@uid NVARCHAR(50)',
  @uid = @user_id;

-- ❌ Bad (SQL injection risk)
EXEC('SELECT * FROM PORTAL.USERS WHERE user_id = ' + @user_id);
```

## 🔒 Security

### 1. RLS Compliance
Ensure stored procedures respect Row-Level Security:
```sql
-- Include tenant_id filtering
WHERE tenant_id = @tenant_id
  AND other_conditions...
```

### 2. Permission Checks
Document required permissions in procedure header:
```sql
/* 
  PERMISSIONS REQUIRED:
  -SELECT on PORTAL.USERS
  - INSERT on PORTAL.AUDIT_LOG
*/
```

### 3. Sensitive Data
Never log sensitive data (passwords, tokens):
```sql
-- ❌ Never do this
INSERT INTO LOG VALUES(@password);

-- ✅ Log metadata only
INSERT INTO LOG VALUES('Password updated');
```

## 📊 Consistency Requirements

### Parameter Types
| Parameter | Type | Notes |
|-----------|------|-------|
| `@tenant_id` | `NVARCHAR(50)` | Standard across all procedures |
| `@user_id` | `NVARCHAR(50)` | Standard across all procedures |
| `@email` | `NVARCHAR(320)` | RFC 5321 max length |
| `@created_by` | `NVARCHAR(255)` | Actor identifier |
| `@display_name` | `NVARCHAR(100)` | Display names |
| `@ext_attributes` | `NVARCHAR(MAX)` | JSON extensibility |

### Return Columns
Standard return format for all CRUD procedures:
```sql
SELECT 
  @status AS status,           -- 'OK' or 'ERROR'
  @entity_id AS entity_id,      -- Generated/affected ID
  @err AS error_message,         -- NULL or error text
  @rows AS rows_affected         -- Row count
```

## 🚫 Anti-Patterns to Avoid

1. ❌ **No error handling**
2. ❌ **Missing schema prefix**
3. ❌ **SELECT * in production code**
4. ❌ **Hardcoded values instead of parameters**
5. ❌ **No audit logging**
6. ❌ **Inconsistent naming**
7. ❌ **Missing SET NOCOUNT ON**
8. ❌ **Dynamic SQL with concatenation**
9. ❌ **No transaction management**
10. ❌ **Procedures without TRY...CATCH**

## 📝 Checklist for New Procedures

Before committing a new stored procedure:

- [ ] Name follows `sp_action_entity` pattern
- [ ] Includes `SET NOCOUNT ON`
- [ ] Uses TRY...CATCH error handling
- [ ] Has transaction with COMMIT/ROLLBACK
- [ ] Filters by `tenant_id` where applicable
- [ ] Uses schema prefix (PORTAL.TABLE)
- [ ] Specifies columns in SELECT (no SELECT *)
- [ ] Calls `sp_log_stats_execution` for audit
- [ ] Returns consistent format
- [ ] Parameters match standard types
- [ ] Includes comments/documentation
- [ ] Tested with edge cases

---

**Validator**: Run `npm run analyze` to check your procedures against these standards.
