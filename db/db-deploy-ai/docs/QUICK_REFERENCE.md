# Quick Decision Trees

## 🌳 Table Design Decisions

### Do I need a new table?
```
START: New data requirement
    ↓
Is it a new business entity?
    YES → Create new table
    NO ↓
Is it attributes of existing entity?
    YES → Add columns to existing table
    NO ↓
Is it a many-to-many relationship?
    YES → Create junction table
    NO ↓
Is it historical/audit data?
    YES → Create history/log table
    NO ↓
Reconsider requirements - might be config/JSON
```

### Column Type Decision
```
What kind of data?
├─ ID/Key → BIGINT (large tables) or INT (small tables)
├─ Business Code → NVARCHAR(50)
├─ Name/Label → NVARCHAR(100) or NVARCHAR(255)
├─ Email → NVARCHAR(320)
├─ Phone → NVARCHAR(20)
├─ Date/Time → DATETIME2
├─ Yes/No → BIT
├─ Money → DECIMAL(19,4)
├─ Large Text → NVARCHAR(MAX)
└─ Dynamic/JSON → NVARCHAR(MAX) with validation
```

### Index Decision
```
Will this column be in WHERE clause often?
    YES ↓
Is it unique business key?
    YES → UNIQUE INDEX
    NO ↓
Is it filtered with other columns?
    YES → COMPOUND INDEX (all filtered columns)
    NO → SINGLE COLUMN INDEX
    
Is it low cardinality (few distinct values)?
    YES → FILTERED INDEX (WHERE clause)
    NO → REGULAR INDEX
```

### Naming Decision
```
Table Name?
├─ Entity name (singular or plural based on convention)
├─ UPPERCASE_WITH_UNDERSCORES
└─ Examples: USER, TENANT, NOTIFICATION

Column Name?
├─ Descriptive snake_case
├─ No abbreviations (except standard: id, fk, qty)
└─ Examples: user_id, created_at, is_active

Index Name?
├─ IX_TABLENAME_column1_column2 (non-unique)
├─ UX_TABLENAME_column1_column2 (unique)
└─ PK_TABLENAME (primary key - auto-generated)
```

## 📋 Checklists

### New Table Checklist
- [ ] Business requirement documented
- [ ] Table name follows convention (UPPERCASE)
- [ ] Primary key defined (`id BIGINT IDENTITY`)
- [ ] tenant_id included (if multi-tenant)
- [ ] Audit columns (created_at, updated_at, created_by)
- [ ] Appropriate indexes for queries
- [ ] NULL/NOT NULL specified for all columns
- [ ] Default values defined where needed
- [ ] Added to blueprint JSON
- [ ] Migration SQL created
- [ ] Migration is idempotent (IF NOT EXISTS)
- [ ] Peer reviewed
- [ ] Tested in DEV
- [ ] Documentation added

### Modify Table Checklist
- [ ] Backward compatibility considered
- [ ] Default values for new columns
- [ ] Index impact assessed
- [ ] Stored procedures reviewed
- [ ] Migration tested
- [ ] Blueprint updated
- [ ] Rollback plan documented

### Index Checklist
- [ ] Covers expected WHERE clauses
- [ ] Column order optimized (equality → range → sort)
- [ ] Include columns considered for covering
- [ ] Filtered index for low cardinality
- [ ] Impact on INSERT/UPDATE acceptable
- [ ] Tested with actual query patterns

## ⚡ Quick Commands

### Create New Table (Full Flow)
```bash
# 1. Edit blueprint
code schema/easyway-portal.blueprint.json

# 2. Generate SQL
npm run blueprint:generate > ../migrations/V{N}__add_{table}.sql

# 3. Validate
npm run analyze -- --file=../migrations/V{N}__add_{table}.sql

# 4. Deploy
cat ../migrations/V{N}__add_{table}.sql | npm run apply

# 5. Verify
npm run diff
```

### Check Current Schema
```bash
npm run diff -- --input <(echo '{
  "connection": env,
  "desired_schema": {"tables": ["PORTAL.TENANT", "PORTAL.USERS"]}
}')
```

### Analyze All Procedures
```bash
npm run analyze > analysis-report.txt
```

---

**Next**: See [TABLE_DESIGN_FLOW.md](TABLE_DESIGN_FLOW.md) for detailed steps
