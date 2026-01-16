---
tags:
  - artifact/stored-procedure
id: ew-user-notification-settings
title: user notification settings
summary: 'Documento su user notification settings.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/db, layer/reference, audience/dev, audience/dba, privacy/internal, language/it, artifact-stored-procedure, notifications]
title: user notification settings
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
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
  ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
```sql




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
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
  ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
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
  ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
```sql




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
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
 = Ensure-Section ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
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
  ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
```sql




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_user_notification_settings**

```sql
--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


### b) **sp_update_user_notification_settings**


```sql
--STORE PROCEDURE –  UPDATE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = NULL,
    @notify_on_alert BIT = NULL,
    @notify_on_digest BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USER_NOTIFICATION_SETTINGS
        SET
            notify_on_upload = COALESCE(@notify_on_upload, notify_on_upload),
            notify_on_alert = COALESCE(@notify_on_alert, notify_on_alert),
            notify_on_digest = COALESCE(@notify_on_digest, notify_on_digest),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user_notification_setting')
        WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_user_notification_settings**


```sql
--STORE PROCEDURE –  DELETE SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE tenant_id = @tenant_id AND user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql

### d) **sp_debug_insert_user_notification_settings**


```sql
--STORE PROCEDURE –  INSERT DEBUG SECTION_ACCESS
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user_notification_setting
    @tenant_id NVARCHAR(50),
    @user_id NVARCHAR(50),
    @notify_on_upload BIT = 0,
    @notify_on_alert BIT = 0,
    @notify_on_digest BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS
            WHERE tenant_id = @tenant_id AND user_id = @user_id
        )
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS
                (tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, ext_attributes, created_by)
            VALUES
                (@tenant_id, @user_id, @notify_on_upload, @notify_on_alert, @notify_on_digest, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user_notification_setting'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user_notification_setting');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user_notification_setting',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USER_NOTIFICATION_SETTINGS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS
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











