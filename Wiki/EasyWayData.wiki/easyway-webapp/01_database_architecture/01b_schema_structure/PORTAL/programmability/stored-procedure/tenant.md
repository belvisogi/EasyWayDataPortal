---
tags:
  - artifact/stored-procedure
id: ew-tenant
title: tenant
summary: 'Documento su tenant.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-stored-procedure, domain/db, layer/reference, audience/dba, privacy/internal, language/it]
title: tenant
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
type: guide
---
[Home](../../../../.././start-here.md) > [[domains/db|db]] > 

**Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





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
  **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





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
  **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





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
  **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





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
 = Ensure-Section **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





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
  **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section **Di seguito troverai:**
----------------------------

*   Store **INSERT** (con NDG, logging, auditing)
    
*   Store **UPDATE** (update fields, logging, auditing)
    
*   Store **DELETE** (soft delete o hard, logging, auditing)
    
*   Versione **DEBUG** per ogni store process


1️⃣ `sp_insert_tenant`
```sql
--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql

2️⃣ `sp_update_tenant`

```sql
--STORE PROCEDURE – AGGIORNA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
    @tenant_id NVARCHAR(50),
    @name NVARCHAR(255) = NULL,
    @plan_code NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.TENANT
        SET
            name = COALESCE(@name, name),
            plan_code = COALESCE(@plan_code, plan_code),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_tenant')
        WHERE tenant_id = @tenant_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_tenant',
        @tenant_id = @tenant_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO
```sql

3️⃣ `sp_delete_tenant`

```sql
--STORE PROCEDURE – CANCELLA TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
    @tenant_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.TENANT WHERE tenant_id = @tenant_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_tenant',
        @tenant_id = @tenant_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO
```sql

5️⃣ `sp_debug_insert_tenant`

```sql
--STORE PROCEDURE – DEBUG INSERT TENANT
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_tenant
    @tenant_id NVARCHAR(50) = NULL,
    @name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, ext_attributes, created_by)
            VALUES (@tenant_id, @name, @plan_code, @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_tenant'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_tenant');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_tenant',
        @tenant_id = @tenant_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.TENANT',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @tenant_id AS tenant_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO
```sql


📑 **Documentazione .md**
-------------------------

Per ogni store procedure avrai la sezione .md standard così:

### sp_insert_tenant

| Parametro      | Tipo           | Descrizione                  |
|----------------|----------------|------------------------------|
| tenant_id      | NVARCHAR(50)   | Codice NDG (auto se NULL)    |
| name           | NVARCHAR(255)  | Ragione sociale/nome tenant  |
| plan_code      | NVARCHAR(50)   | Piano EasyWay                |
| ext_attributes | NVARCHAR(MAX)  | Estensioni JSON custom       |
| created_by     | NVARCHAR(255)  | Utente/SP di creazione       |

- Logging automatico su STATS_EXECUTION_LOG.
- Gestione NDG e transazione atomica.
- Versione DEBUG disponibile.





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















