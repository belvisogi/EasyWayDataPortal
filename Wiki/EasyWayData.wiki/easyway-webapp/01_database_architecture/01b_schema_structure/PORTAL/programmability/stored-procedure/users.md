---
tags:
  - artifact/stored-procedure
id: ew-users
title: users
summary: 'Documento su users.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-stored-procedure, domain/db, layer/reference, audience/dba, privacy/internal, language/it]
title: users
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/db|db]] > [[Layer - Reference|Reference]]

**Nota implementazione canonica**
--------------------------------

Le definizioni canoniche delle SP USERS sono in `db/flyway/sql/V9__stored_procedures_users_config_acl.sql` (soft delete su `is_active`, parametri `email/display_name/profile_id`).

a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

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

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |


e) **sp_list_users_by_tenant**
------------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_list_users_by_tenant
  @tenant_id NVARCHAR(50),
  @include_inactive BIT = 0,
  @requested_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    SELECT user_id, tenant_id, email, display_name, profile_id, is_active, status, ext_attributes, created_at, updated_at
    FROM PORTAL.USERS
    WHERE tenant_id=@tenant_id AND (@include_inactive=1 OR is_active=1);
    SET @rows=@@ROWCOUNT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err=ERROR_MESSAGE();
  END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_list_users_by_tenant', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='SELECT', @created_by=COALESCE(@requested_by,'sp_list_users_by_tenant');
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
  a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




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
  a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




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
  a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




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
 = Ensure-Section a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




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
  a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section a) **sp_insert_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    -- **Conversational Intelligence output**
    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

```sql


b) **sp_update_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
    @user_id NVARCHAR(50),
    @tenant_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = NULL,
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50) = NULL,
    @is_tenant_admin BIT = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_updated INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE PORTAL.USERS
        SET
            tenant_id = COALESCE(@tenant_id, tenant_id),
            email = COALESCE(@email, email),
            name = COALESCE(@name, name),
            surname = COALESCE(@surname, surname),
            password = COALESCE(@password, password),
            provider = COALESCE(@provider, provider),
            provider_user_id = COALESCE(@provider_user_id, provider_user_id),
            status = COALESCE(@status, status),
            profile_code = COALESCE(@profile_code, profile_code),
            is_tenant_admin = COALESCE(@is_tenant_admin, is_tenant_admin),
            ext_attributes = COALESCE(@ext_attributes, ext_attributes),
            updated_at = SYSUTCDATETIME(),
            created_by = COALESCE(@updated_by, 'sp_update_user')
        WHERE user_id = @user_id;
        SET @rows_updated = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @updated_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @updated_by_final = COALESCE(@updated_by, 'sp_update_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_update_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_updated = @rows_updated,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'UPDATE',
        @created_by = @updated_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_updated AS rows_updated;
END
GO


```sql


c) **sp_delete_user**
---------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
    @user_id NVARCHAR(50),
    @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_deleted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM PORTAL.USERS WHERE user_id = @user_id;
        SET @rows_deleted = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    DECLARE @deleted_by_final NVARCHAR(255);
    DECLARE @end_time DATETIME2 = SYSUTCDATETIME();
    SET @deleted_by_final = COALESCE(@deleted_by, 'sp_delete_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_delete_user',
        @user_id = @user_id,
        @rows_deleted = @rows_deleted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'DELETE',
        @created_by = @deleted_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_deleted AS rows_deleted;
END
GO


```sql


d) **sp_debug_insert_user**
---------------------------

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_user
    @user_id NVARCHAR(50) = NULL,
    @tenant_id NVARCHAR(50),
    @email NVARCHAR(255),
    @name NVARCHAR(100) = NULL,
    @surname NVARCHAR(100) = NULL,
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @status NVARCHAR(50) = NULL,
    @profile_code NVARCHAR(50),
    @is_tenant_admin BIT = 0,
    @ext_attributes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (user_id, tenant_id, email, name, surname, password,
                                      provider, provider_user_id, status, profile_code, is_tenant_admin,
                                      ext_attributes, created_by)
            VALUES (@user_id, @tenant_id, @email, @name, @surname, @password,
                    @provider, @provider_user_id, @status, @profile_code, @is_tenant_admin,
                    @ext_attributes, COALESCE(@created_by, 'sp_debug_insert_user'));
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
    SET @created_by_final = COALESCE(@created_by, 'sp_debug_insert_user');

    EXEC PORTAL.sp_log_stats_execution
        @proc_name = 'sp_debug_insert_user',
        @tenant_id = @tenant_id,
        @user_id = @user_id,
        @rows_inserted = @rows_inserted,
        @status = @status_out,
        @error_message = @error_message,
        @start_time = @start_time,
        @end_time = @end_time,
        @affected_tables = 'PORTAL.USERS',
        @operation_types = 'INSERT',
        @created_by = @created_by_final;

    SELECT @status_out AS status, @user_id AS user_id, @error_message AS error_message, @rows_inserted AS rows_inserted;
END
GO

GO

```sql
---
👾 Conversational Intelligence Ready
---

Prompt di esempio chatbot:
> Crea utente “luca@azienda.it” per tenant TEN00000001001, profilo ADMIN

```sql
EXEC PORTAL.sp_insert_user @tenant_id='TEN00000001001', @email='luca@azienda.it', @profile_code='ADMIN', @created_by='chatbot_ams';
```sql

Risposta bot:

| status | user_id | error_message | rows_inserted |
| --- | --- | --- | --- |
| OK | CDI00000001001 | NULL | 1 |




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











