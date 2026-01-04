---
id: ew-configuration
title: configuration
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [layer/reference, artifact-stored-procedure, privacy/internal, language/it]
title: configuration
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



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
  ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



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
  ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



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
  ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



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
 = Ensure-Section ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



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
  ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_configuration**

```sql

--INIZIO SEZIONE STORE PROCEDURE CONFIGURATION 
--STORE PROCEDURE – INSERT CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM PORTAL.CONFIGURATION
            WHERE tenant_id = @tenant_id AND config_key = @config_key
        )
        BEGIN
            INSERT INTO PORTAL.CONFIGURATION (
                tenant_id, config_key, config_value, description, is_active, created_by
            )
            VALUES (
                @tenant_id, @config_key, @config_value, @description, @is_active,
                COALESCE(@created_by, 'sp_insert_configuration')
            );
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO


```sql

### b) **sp_update_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
    @id INT,
    @config_value NVARCHAR(MAX) = NULL,
    @description NVARCHAR(255) = NULL,
    @is_active BIT = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.CONFIGURATION
        SET
            config_value = COALESCE(@config_value, config_value),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_configuration')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_configuration',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql

### c) **sp_delete_configuration**

```sql
--STORE PROCEDURE – UPDATE CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.CONFIGURATION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_configuration',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

### d) **sp_debug_insert_configuration**

```sql
--STORE PROCEDURE – INSERT DEBUG CONFIGURATION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_configuration
    @tenant_id NVARCHAR(50) = NULL,
    @config_key NVARCHAR(100),
    @config_value NVARCHAR(MAX),
    @description NVARCHAR(255) = NULL,
    @is_active BIT = 1,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.CONFIGURATION (
            tenant_id, config_key, config_value, description, is_active, created_by
        )
        VALUES (
            @tenant_id, @config_key, @config_value, @description, @is_active,
            COALESCE(@created_by, 'sp_debug_insert_configuration')
        );
        SET @rows_inserted = 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @created_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_configuration');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_configuration',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.CONFIGURATION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @config_key AS config_key, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
--FINE SEZIONE STORE PROCEDURE CONFIGURATION 

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Imposta per il tenant TEN00000001001 la configurazione MAX_FILE_SIZE_MB a 50

```sql
EXEC PORTAL.sp_insert_configuration @tenant_id = 'TEN00000001001', @config_key = 'MAX_FILE_SIZE_MB', @config_value = '50', @created_by = 'chatbot_ams';
```sql

Risposta bot:
| status | tenant_id | config_key | error_message | rows_inserted |
| --- | --- | --- | --- | --- |
| OK | TEN00000001001 | MAX_FILE_SIZE_MB | NULL | 1 |



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










