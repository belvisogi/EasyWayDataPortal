-- LEGACY: questo provisioning SQL può divergere da Flyway.
-- Usa `db/flyway/sql/` tramite `db/provisioning/apply-flyway.ps1`.
--
-- Debug helper used by API for local/dev onboarding and user insert
-- Idempotent: CREATE OR ALTER

CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = NULL,
    @user_email NVARCHAR(255) = NULL,
    @email NVARCHAR(255) = NULL, -- alias
    @display_name NVARCHAR(255) = NULL,
    @profile_id NVARCHAR(50) = NULL,
    @ext_attributes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @status_out NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Normalize inputs
        SET @user_email = COALESCE(@user_email, @email);
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            IF @tenant_name IS NULL OR @tenant_name = '' SET @tenant_name = 'Tenant Demo';
            IF NOT EXISTS (SELECT 1 FROM PORTAL.tenants WHERE tenant_id = 'TENDEBUG001')
            BEGIN
                INSERT INTO PORTAL.tenants(tenant_id, tenant_name, tenant_description)
                VALUES ('TENDEBUG001', @tenant_name, 'Debug tenant (auto)');
            END
            SET @tenant_id = 'TENDEBUG001';
        END

        -- Ensure profile exists if provided
        IF @profile_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM PORTAL.profiles WHERE profile_id = @profile_id)
        BEGIN
            INSERT INTO PORTAL.profiles(profile_id, profile_name, profile_description)
            VALUES(@profile_id, @profile_id, 'Auto-created for debug');
        END

        DECLARE @uid NVARCHAR(255);
        SET @uid = CONCAT('USR-DBG-', RIGHT(CONVERT(NVARCHAR(20), ABS(CHECKSUM(NEWID()))), 8));

        IF NOT EXISTS (SELECT 1 FROM PORTAL.users WHERE email = @user_email AND tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.users(user_id, tenant_id, profile_id, email, display_name, password, is_active, is_notify_enabled, updated_at)
            VALUES(@uid, @tenant_id, @profile_id, @user_email, @display_name, NULL, 1, 1, SYSUTCDATETIME());
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status_out = 'ERROR'; SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    SELECT @status_out AS status, @tenant_id AS tenant_id, @user_email AS user_email, SYSUTCDATETIME() AS completed_at;
END
GO
