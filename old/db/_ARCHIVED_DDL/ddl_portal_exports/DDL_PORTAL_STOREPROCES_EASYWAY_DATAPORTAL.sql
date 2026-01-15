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


--INIZIO SEZIONE STORE PROCEDURE USERS 
--STORE PROCEDURE – INSERIMENTO UTENTE
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

--STORE PROCEDURE – AGGIORNA UTENTE
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

--STORE PROCEDURE – CANCELLA UTENTE
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

--STORE PROCEDURE – DEBUG INSERT USER
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
--FINE SEZIONE STORE PROCEDURE USERS 

--INIZIO SEZIONE STORE PROCEDURE PROFILE_DOMAINS 
--STORE PROCEDURE – INSERT PROFILE_DOMAINS
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

--STORE PROCEDURE – UPDATE PROFILE_DOMAINS
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

--STORE PROCEDURE – DELETE PROFILE_DOMAINS
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

--STORE PROCEDURE –  DEBUG (inserimento di profilo ACL per test/debug)
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
--FINE SEZIONE STORE PROCEDURE PROFILE_DOMAINS 

--INIZIO SEZIONE STORE PROCEDURE SECTION_ACCESS 
--STORE PROCEDURE –  INSERT SECTION_ACCESS
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

--STORE PROCEDURE –  UPDATE SECTION_ACCESS
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

--STORE PROCEDURE –  DELETE SECTION_ACCESS
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

--STORE PROCEDURE –  DEBUG INSERT SECTION_ACCESS
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
--FINE SEZIONE STORE PROCEDURE SECTION_ACCESS



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


