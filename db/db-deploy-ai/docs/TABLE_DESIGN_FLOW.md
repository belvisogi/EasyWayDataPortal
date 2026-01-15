# Database Table Design & Deployment Flow

## 🎯 Workflow Overview

```
1. Business Requirements
   ↓
2. Design in Blueprint (JSON)
   ↓
3. Validate Design
   ↓
4. Generate SQL Migration
   ↓
5. Review & Test
   ↓
6. Deploy with db-deploy
   ↓
7. Verify with diff
```

---

## 📋 Step-by-Step Process

### Step 1: Gather Business Requirements

**Questions to Ask:**
- [ ] What data needs to be stored?
- [ ] Who needs access? (single tenant or multi-tenant?)
- [ ] What are the relationships with other tables?
- [ ] What queries will be run most often?
- [ ] What's the expected data volume?
- [ ] Are there any compliance requirements (GDPR, audit trail)?

**Example Requirement:**
```
"We need to store customer notifications with:
- Message content
- Delivery status
- Read/unread flag
- Timestamp
- Link to user and tenant
"
```

---

### Step 2: Design Table in Blueprint

**Location:** `db/db-deploy-ai/schema/easyway-portal.blueprint.json`

**Add new table to blueprint:**
```json
{
  "tables": [
    // ... existing tables ...
    {
      "name": "NOTIFICATIONS",
      "schema": "PORTAL",
      "description": "User notifications with delivery tracking",
      "columns": [
        {
          "name": "id",
          "type": "BIGINT",
          "identity": true,
          "primary_key": true,
          "description": "Auto-increment primary key"
        },
        {
          "name": "tenant_id",
          "type": "NVARCHAR(50)",
          "nullable": false,
          "description": "Multi-tenant isolation"
        },
        {
          "name": "user_id",
          "type": "NVARCHAR(50)",
          "nullable": false,
          "description": "Target user"
        },
        {
          "name": "message",
          "type": "NVARCHAR(MAX)",
          "nullable": false,
          "description": "Notification content"
        },
        {
          "name": "status",
          "type": "NVARCHAR(32)",
          "nullable": false,
          "default": "'PENDING'",
          "description": "PENDING, SENT, FAILED"
        },
        {
          "name": "is_read",
          "type": "BIT",
          "nullable": false,
          "default": "0"
        },
        {
          "name": "created_at",
          "type": "DATETIME2",
          "nullable": false,
          "default": "SYSUTCDATETIME()"
        },
        {
          "name": "read_at",
          "type": "DATETIME2",
          "nullable": true
        }
      ],
      "indexes": [
        {
          "name": "IX_NOTIFICATIONS_tenant_user",
          "columns": ["tenant_id", "user_id", "created_at"],
          "description": "For user notification queries"
        },
        {
          "name": "IX_NOTIFICATIONS_status",
          "columns": ["status", "created_at"],
          "description": "For batch processing pending notifications"
        }
      ]
    }
  ]
}
```

**Design Checklist:**
- [ ] Table name is UPPERCASE
- [ ] Primary key defined (usually `id BIGINT IDENTITY`)
- [ ] `tenant_id` included for multi-tenant tables
- [ ] Audit columns included (`created_at`, `updated_at`, `created_by`)
- [ ] Indexes designed for expected queries
- [ ] All columns have descriptions
- [ ] Default values specified where appropriate
- [ ] Nullable constraints defined

---

### Step 3: Validate Design

**Run Blueprint Validator:**
```bash
cd db/db-deploy-ai
npm run blueprint:validate
```

**Manual Checks:**

#### 3.1 Naming Convention
```
✅ Table: UPPERCASE_WITH_UNDERSCORES
✅ Columns: snake_case
✅ Indexes: IX_TABLENAME_columns or UX_TABLENAME_columns (unique)
✅ Foreign Keys: FK_TABLENAME_REFTABLE
```

#### 3.2 Data Types
```
✅ IDs: BIGINT IDENTITY (not INT for large tables)
✅ Business Keys: NVARCHAR(50)
✅ Names: NVARCHAR(100) or NVARCHAR(255)
✅ Emails: NVARCHAR(320) - RFC 5321 max
✅ Dates: DATETIME2 (not DATETIME)
✅ Flags: BIT
✅ JSON: NVARCHAR(MAX)
✅ Money: DECIMAL(19,4)
```

#### 3.3 Required Columns (Multi-Tenant Tables)
```sql
tenant_id      NVARCHAR(50) NOT NULL  -- ✅ Multi-tenancy
created_by     NVARCHAR(255) NOT NULL DEFAULT 'SYSTEM'
created_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
updated_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
```

#### 3.4 Index Strategy
- **Primary Key**: Always on `id`
- **Unique Indexes**: Business keys (e.g., `tenant_id + email`)
- **Search Indexes**: Frequently filtered columns
- **Compound Indexes**: Match WHERE clause patterns
- **Include Columns**: For covered queries

---

### Step 4: Generate SQL Migration

**Option A: Auto-Generate from Blueprint**
```bash
npm run blueprint:generate > ../migrations/V12__add_notifications.sql
```

**Option B: Manual SQL File**
Create `db/migrations/V12__add_notifications.sql`:
```sql
/* V12 - Notifications table for user messaging */

IF OBJECT_ID('PORTAL.NOTIFICATIONS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.NOTIFICATIONS (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,
    user_id NVARCHAR(50) NOT NULL,
    message NVARCHAR(MAX) NOT NULL,
    status NVARCHAR(32) NOT NULL CONSTRAINT DF_NOTIFICATIONS_status DEFAULT 'PENDING',
    is_read BIT NOT NULL CONSTRAINT DF_NOTIFICATIONS_is_read DEFAULT 0,
    created_at DATETIME2 NOT NULL CONSTRAINT DF_NOTIFICATIONS_created_at DEFAULT SYSUTCDATETIME(),
    read_at DATETIME2 NULL
  );
  
  CREATE INDEX IX_NOTIFICATIONS_tenant_user 
    ON PORTAL.NOTIFICATIONS(tenant_id, user_id, created_at);
  
  CREATE INDEX IX_NOTIFICATIONS_status 
    ON PORTAL.NOTIFICATIONS(status, created_at)
    WHERE status = 'PENDING';  -- Filtered index for performance
END;
GO

/* Extended properties for documentation */
EXEC sp_addextendedproperty 
  @name = N'MS_Description',
  @value = N'User notifications with delivery tracking',
  @level0type = N'SCHEMA', @level0name = 'PORTAL',
  @level1type = N'TABLE', @level1name = 'NOTIFICATIONS';
GO
```

**Migration File Naming:**
```
V{number}__{description}.sql

Examples:
✅ V12__add_notifications.sql
✅ V13__add_user_preferences.sql
✅ V14__modify_tenant_add_status.sql
❌ V12.sql (missing description)
❌ add_notifications.sql (missing version)
```

---

### Step 5: Review & Test

#### 5.1 Peer Review
- [ ] Blueprint matches requirements
- [ ] Column types appropriate
- [ ] Indexes cover expected queries
- [ ] Naming follows conventions
- [ ] Migration SQL is idempotent (IF NOT EXISTS)

#### 5.2 Validate SQL
```bash
npm run analyze -- --file=../migrations/V12__add_notifications.sql
```

#### 5.3 Test Migration (Dry-Run)
```bash
echo '{
  "operation": "apply",
  "connection": {
    "server": "repos-easyway-dev.database.windows.net",
    "database": "EASYWAY_PORTAL_DEV",
    "auth": {
      "username": "easyway-admin",
      "password": "'$DB_PASSWORD'"
    }
  },
  "statements": [{
    "id": "create_notifications",
    "sql": "'$(cat ../migrations/V12__add_notifications.sql)'"
  }]
}' | npm run apply -- --dry-run
```

---

### Step 6: Deploy

#### 6.1 Apply Migration
```bash
# Read SQL file and apply via db-deploy
cat ../migrations/V12__add_notifications.sql | \
npm run apply -- --input <(echo '{
  "connection": {...},
  "statements": [{"id": "v12", "sql": "'$(cat -)'" }]
}')
```

#### 6.2 Or Use Direct sqlcmd
```bash
sqlcmd -S repos-easyway-dev.database.windows.net \
  -d EASYWAY_PORTAL_DEV \
  -U easyway-admin \
  -P "$DB_PASSWORD" \
  -i ../migrations/V12__add_notifications.sql
```

---

### Step 7: Verify Deployment

#### 7.1 Check Table Exists
```bash
npm run diff -- --input <(echo '{
  "connection": {...},
  "desired_schema": {
    "tables": ["PORTAL.NOTIFICATIONS"]
  }
}')
```

Expected output:
```json
{
  "status": "success",
  "diff": {
    "missing": { "tables": [] },  // ✅ Empty = table exists
    "extra": { "tables": [] }
  }
}
```

#### 7.2 Update Blueprint
Ensure `easyway-portal.blueprint.json` reflects deployed state.

#### 7.3 Test Queries
```sql
-- Test insert
INSERT INTO PORTAL.NOTIFICATIONS (tenant_id, user_id, message)
VALUES ('TEN001', 'USR001', 'Test notification');

-- Test query with index
SELECT * FROM PORTAL.NOTIFICATIONS
WHERE tenant_id = 'TEN001' AND user_id = 'USR001'
ORDER BY created_at DESC;

-- Verify index usage
SET STATISTICS IO ON;
-- Check execution plan
```

---

## 🔄 Modification Flow (Existing Table)

### Adding Column
1. Update blueprint: Add column definition
2. Generate migration:
```sql
ALTER TABLE PORTAL.NOTIFICATIONS
ADD priority NVARCHAR(16) NOT NULL CONSTRAINT DF_NOTIFICATIONS_priority DEFAULT 'NORMAL';
```
3. Deploy with backward compatibility consideration

### Renaming Column
**⚠️ Breaking Change** - Requires coordination:
1. Create new column
2. Deploy stored procedures using both columns
3. Migrate data
4. Update procedures to use new column only
5. Drop old column

### Adding Index
```sql
CREATE INDEX IX_NOTIFICATIONS_priority
ON PORTAL.NOTIFICATIONS(priority, created_at)
WHERE priority IN ('HIGH', 'URGENT');  -- Filtered for performance
```

---

## 📊 Decision Matrix

### When to Create New Table?

| Scenario | Decision |
|----------|----------|
| New business entity | ✅ New table |
| Additional attributes for existing entity | ❌ Add columns to existing |
| Many-to-many relationship | ✅ Junction table |
| Historical/audit data | ✅ Separate history table |
| Different access patterns | ✅ Consider separate table |
| < 5 columns of related data | ❌ Add to existing table |

### Column vs JSON (ext_attributes)?

| Use Column When | Use JSON When |
|----------------|---------------|
| Queried frequently | Rarely queried |
| Indexed | Not indexed |
| Strongly typed | Dynamic schema |
| Business-critical | Optional/extensibility |
| Standardized | Tenant-specific |

---

## 🎯 Quick Reference

### Common Table Patterns

#### 1. Master Data Table
```json
{
  "name": "PRODUCT",
  "columns": [
    {"name": "id", "type": "BIGINT", "identity": true},
    {"name": "product_code", "type": "NVARCHAR(50)"},
    {"name": "name", "type": "NVARCHAR(255)"},
    {"name": "description", "type": "NVARCHAR(MAX)"},
    {"name": "is_active", "type": "BIT", "default": "1"},
    {"name": "created_at", "type": "DATETIME2"}
  ]
}
```

#### 2. Multi-Tenant Configuration
```json
{
  "name": "TENANT_SETTINGS",
  "columns": [
    {"name": "tenant_id", "type": "NVARCHAR(50)"},
    {"name": "setting_key", "type": "NVARCHAR(100)"},
    {"name": "setting_value", "type": "NVARCHAR(MAX)"},
    {"name": "enabled", "type": "BIT"}
  ],
  "indexes": [
    {"name": "UX_tenant_key", "columns": ["tenant_id", "setting_key"], "unique": true}
  ]
}
```

#### 3. Audit/Log Table
```json
{
  "name": "AUDIT_LOG",
  "columns": [
    {"name": "id", "type": "BIGINT", "identity": true},
    {"name": "event_time", "type": "DATETIME2"},
    {"name": "tenant_id", "type": "NVARCHAR(50)"},
    {"name": "actor", "type": "NVARCHAR(255)"},
    {"name": "action", "type": "NVARCHAR(64)"},
    {"name": "entity_type", "type": "NVARCHAR(64)"},
    {"name": "entity_id", "type": "NVARCHAR(50)"},
    {"name": "payload", "type": "NVARCHAR(MAX)"}
  ],
  "indexes": [
    {"name": "IX_audit_tenant_time", "columns": ["tenant_id", "event_time"]}
  ]
}
```

---

**Tools**: 
- Design: `schema/easyway-portal.blueprint.json`
- Generate: `npm run blueprint:generate`
- Validate: `npm run analyze`
- Deploy: `npm run apply`
- Verify: `npm run diff`
