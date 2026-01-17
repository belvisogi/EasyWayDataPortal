---
tags:
  - artifact/stored-procedure
id: ew-subscription
title: subscription
summary: 'Documento su subscription.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-stored-procedure, domain/db, layer/reference, audience/dba, privacy/internal, language/it]
title: subscription
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/db|db]] > [[Layer - Reference|Reference]]

### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

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
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



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
  ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



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
  ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



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
  ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



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
 = Ensure-Section ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



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
  ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section ### a) **sp_insert_subscription**

```sql
--INIZIO SEZIONE STORE PROCEDURE SUBSCRIPTION 
--STORE PROCEDURE –  INSERT SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
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
            SELECT 1 FROM PORTAL.SUBSCRIPTION WHERE tenant_id = @tenant_id
              AND plan_code = @plan_code AND start_date = @start_date
        )
        BEGIN
            INSERT INTO PORTAL.SUBSCRIPTION (
                tenant_id, plan_code, status, start_date, end_date, external_payment_id,
                payment_provider, last_payment_date, ext_attributes, created_by
            )
            VALUES (
                @tenant_id, @plan_code, @status, @start_date, @end_date,
                @external_payment_id, @payment_provider, @last_payment_date,
                @ext_attributes, COALESCE(@created_by, 'sp_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql

### b) **sp_update_subscription**

```sql
--STORE PROCEDURE –  UPDATE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_update_subscription
    @id INT,
    @plan_code NVARCHAR(50) = NULL,
    @status NVARCHAR(50) = NULL,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.SUBSCRIPTION
        SET
            plan_code = COALESCE(@plan_code, plan_code),
            status = COALESCE(@status, status),
            start_date = COALESCE(@start_date, start_date),
            end_date = COALESCE(@end_date, end_date),
            external_payment_id = COALESCE(@external_payment_id, external_payment_id),
            payment_provider = COALESCE(@payment_provider, payment_provider),
            last_payment_date = COALESCE(@last_payment_date, last_payment_date),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_subscription')
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
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_subscription',
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO

```sql
### c) **sp_delete_subscription**

```sql
--STORE PROCEDURE –  DELETE SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_subscription
    @id INT,
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.SUBSCRIPTION WHERE id = @id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_subscription',
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @id AS id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO

```sql
### d) **sp_debug_insert_subscription**

```sql
--STORE PROCEDURE –  INSERT DEBUG SUBSCRIPTION
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_subscription
    @tenant_id NVARCHAR(50),
    @plan_code NVARCHAR(50),
    @status NVARCHAR(50) = 'ACTIVE',
    @start_date DATETIME2,
    @end_date DATETIME2,
    @external_payment_id NVARCHAR(100) = NULL,
    @payment_provider NVARCHAR(50) = NULL,
    @last_payment_date DATETIME2 = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO PORTAL.SUBSCRIPTION (
            tenant_id, plan_code, status, start_date, end_date, external_payment_id,
            payment_provider, last_payment_date, ext_attributes, created_by
        )
        VALUES (
            @tenant_id, @plan_code, @status, @start_date, @end_date,
            @external_payment_id, @payment_provider, @last_payment_date,
            @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_subscription')
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_subscription');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_subscription',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.SUBSCRIPTION',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @plan_code AS plan_code, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

--FINE SEZIONE STORE PROCEDURE SUBSCRIPTION

```sql
---
👾 Conversational Intelligence Ready
---

Prompt esempio:
> Inserisci una nuova subscription GOLD per il tenant TEN00000001001 dal 2025-01-01 al 2026-01-01

```sql
EXEC PORTAL.sp_insert_subscription
    @tenant_id = 'TEN00000001001',
    @plan_code = 'GOLD',
    @start_date = '2025-01-01',
    @end_date = '2026-01-01',
    @created_by = 'chatbot_ams';



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














