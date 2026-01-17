---
tags:
  - artifact/stored-procedure
id: ew-section-access
title: section access
summary: 'Documento su section access.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it, artifact-stored-procedure, access-control]
title: section access
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/db|db]] > [[Layer - Reference|Reference]]

### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



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
  ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



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
  ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



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
  ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



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
 = Ensure-Section ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



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
  ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_section_access**

```sql
-- INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_section_access**

```sql
-- UPDATE
CREATE OR ALTER PROCEDURE PORTAL.sp_update_section_access
    @id INT,
    @is_enabled BIT = NULL,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SECTION_ACCESS
        SET
            is_enabled = COALESCE(@is_enabled, is_enabled),
            valid_from = COALESCE(@valid_from, valid_from),
            valid_to = COALESCE(@valid_to, valid_to),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_section_access')
        WHERE id = @id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_section_access',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_section_access**

```sql
-- DELETE
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_section_access
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SECTION_ACCESS WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_section_access',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;
    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql


### d) **sp_debug_insert_section_access**

```sql
-- DEBUG INSERT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_section_access
    @tenant_id NVARCHAR(50),
    @section_code NVARCHAR(50),
    @profile_code NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @is_enabled BIT,
    @valid_from DATETIME2 = NULL,
    @valid_to DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SECTION_ACCESS (tenant_id, section_code, profile_code, user_id, is_enabled, valid_from, valid_to, ext_attributes, created_by)
        VALUES (@tenant_id, @section_code, @profile_code, @user_id, @is_enabled, @valid_from, @valid_to, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_section_access'));
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH
    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_section_access');
    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_section_access',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SECTION_ACCESS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;
    SELECT @status_out AS status, @tenant_id AS tenant_id, @section_code AS section_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql



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












