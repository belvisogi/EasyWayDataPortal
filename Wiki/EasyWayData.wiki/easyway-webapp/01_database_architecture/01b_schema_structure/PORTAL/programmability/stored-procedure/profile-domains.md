---
tags:
  - artifact/stored-procedure
id: ew-profile-domains
title: profile domains
summary: 'Documento su profile domains.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it, artifact-stored-procedure, profile]
title: profile domains
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[Home](../../../../.././start-here.md) > [[domains/db|db]] > 

### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.

## Schema/DDL
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
`sql
-- Esempio DDL idempotente
`
"@
  ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->

## Esempi Query
`sql
-- SELECT ... FROM ...
`
"@
  ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.

## Schema/DDL
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
`sql
-- Esempio DDL idempotente
`
"@
  ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->
 = Ensure-Section ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.

## Schema/DDL
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
`sql
-- Esempio DDL idempotente
`
"@
  ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_profile_domain**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.PROFILE_DOMAINS
        SET
            description = COALESCE(@description, description),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_profile_domain')
        WHERE profile_code = @profile_code;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_profile_domain',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
    @profile_code NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_profile_domain',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

```sql
-- DEBUG (inserimento di profilo ACL per test/debug)
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_profile_domain
    @profile_code NVARCHAR(50),
    @description NVARCHAR(255) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = @profile_code)
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, ext_attributes, created_by)
            VALUES (@profile_code, @description, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_profile_domain'));
            SET @rows_inserted = 1;
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_profile_domain');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_profile_domain',
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.PROFILE_DOMAINS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @profile_code AS profile_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

* * *




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->
 'Domande a cui risponde' @"
- Cosa fa?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Collegamenti
- [Entities Index](../../../../../../entities-index.md)














