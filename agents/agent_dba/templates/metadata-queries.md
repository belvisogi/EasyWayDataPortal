# SQL Server Metadata Extraction Queries
# Complete script to extract all database metadata as JSON

## Query 1: Extract Tables Metadata
```sql
SELECT 
  t.TABLE_SCHEMA AS [schema],
  t.TABLE_NAME AS [table],
  t.TABLE_TYPE AS [type],
  (
    SELECT 
      c.COLUMN_NAME AS [name],
      c.DATA_TYPE AS [type],
      c.CHARACTER_MAXIMUM_LENGTH AS [maxLength],
      c.NUMERIC_PRECISION AS [precision],
      c.NUMERIC_SCALE AS [scale],
      c.IS_NULLABLE AS [nullable],
      c.COLUMN_DEFAULT AS [default],
      CAST(COLUMNPROPERTY(OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity') AS BIT) AS [identity],
      (
        SELECT 1
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
          ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
        WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
          AND kcu.TABLE_SCHEMA = c.TABLE_SCHEMA
          AND kcu.TABLE_NAME = c.TABLE_NAME
          AND kcu.COLUMN_NAME = c.COLUMN_NAME
      ) AS [primaryKey]
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA
      AND c.TABLE_NAME = t.TABLE_NAME
    ORDER BY c.ORDINAL_POSITION
    FOR JSON PATH
  ) AS columns,
  (
    SELECT 
      i.name AS [indexName],
      CAST(i.is_unique AS BIT) AS [unique],
      CAST(i.is_primary_key AS BIT) AS [primaryKey],
      STRING_AGG(col.name, ', ') AS [columns]
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
    WHERE i.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME)
      AND i.type > 0  -- Exclude heaps
    GROUP BY i.name, i.is_unique, i.is_primary_key
    FOR JSON PATH
  ) AS indexes
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_TYPE = 'BASE TABLE'
FOR JSON PATH;
```

## Query 2: Extract Stored Procedures
```sql
SELECT 
  ROUTINE_SCHEMA AS [schema],
  ROUTINE_NAME AS [name],
  ROUTINE_TYPE AS [type],
  CREATED AS [created],
  LAST_ALTERED AS [modified],
  (
    SELECT 
      PARAMETER_NAME AS [name],
      DATA_TYPE AS [type],
      CHARACTER_MAXIMUM_LENGTH AS [maxLength],
      PARAMETER_MODE AS [mode]
    FROM INFORMATION_SCHEMA.PARAMETERS p
    WHERE p.SPECIFIC_SCHEMA = r.ROUTINE_SCHEMA
      AND p.SPECIFIC_NAME = r.ROUTINE_NAME
    ORDER BY ORDINAL_POSITION
    FOR JSON PATH
  ) AS parameters
FROM INFORMATION_SCHEMA.ROUTINES r
WHERE ROUTINE_TYPE = 'PROCEDURE'
FOR JSON PATH;
```

## Query 3: Extract Functions
```sql
SELECT 
  ROUTINE_SCHEMA AS [schema],
  ROUTINE_NAME AS [name],
  ROUTINE_TYPE AS [type],
  DATA_TYPE AS [returnType],
  CREATED AS [created],
  LAST_ALTERED AS [modified]
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION'
FOR JSON PATH;
```

## Query 4: Extract Views
```sql
SELECT 
  TABLE_SCHEMA AS [schema],
  TABLE_NAME AS [name],
  (SELECT TOP 1 VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS v WHERE v.TABLE_SCHEMA = t.TABLE_SCHEMA AND v.TABLE_NAME = t.TABLE_NAME) AS [definition]
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'VIEW'
FOR JSON PATH;
```

## Query 5: Extract Sequences
```sql
SELECT 
  SEQUENCE_SCHEMA AS [schema],
  SEQUENCE_NAME AS [name],
  DATA_TYPE AS [type],
  START_VALUE AS [start],
  INCREMENT AS [increment],
  MINIMUM_VALUE AS [minimum],
  MAXIMUM_VALUE AS [maximum]
FROM INFORMATION_SCHEMA.SEQUENCES
FOR JSON PATH;
```

## Query 6: Extract Security (RLS Policies)
```sql
SELECT 
  SCHEMA_NAME(sp.schema_id) AS [schema],
  sp.name AS [policyName],
  OBJECT_NAME(sp.object_id) AS [targetTable],
  sp.is_enabled AS [enabled],
  (
    SELECT 
      pp.predicate_type_desc AS [type],
      SCHEMA_NAME(f.schema_id) + '.' + f.name AS [function]
    FROM sys.security_predicates pp
    INNER JOIN sys.objects f ON pp.predicate_object_id = f.object_id
    WHERE pp.object_id = sp.object_id
    FOR JSON PATH
  ) AS [predicates]
FROM sys.security_policies sp
FOR JSON PATH;
```

## Combined Query for Complete Metadata
```sql
SELECT 
  (SELECT * FROM (
    -- Tables query here
  ) t FOR JSON PATH) AS tables,
  (SELECT * FROM (
    -- Procedures query here
  ) p FOR JSON PATH) AS procedures,
  (SELECT * FROM (
    -- Functions query here
  ) f FOR JSON PATH) AS functions,
  (SELECT * FROM (
    -- Views query here
  ) v FOR JSON PATH) AS views,
  (SELECT * FROM (
    -- Sequences query here
  ) s FOR JSON PATH) AS sequences,
  (SELECT * FROM (
    -- Security query here
  ) sec FOR JSON PATH) AS security
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
```

## Usage Notes

1. **Run via sqlcmd**:
```powershell
sqlcmd -S server -d database -U user -P pass -i extract-metadata.sql -o metadata.json
```

2. **Parse JSON in PowerShell**:
```powershell
$metadata = Get-Content metadata.json | ConvertFrom-Json
$metadata.tables | ForEach { Write-Host $_.table }
```

3. **Performance**: Queries use INFORMATION_SCHEMA where possible for ANSI compliance, sys tables for SQL Server specific details.

4. **Permissions Required**: SELECT on all objects, VIEW DEFINITION permission.
