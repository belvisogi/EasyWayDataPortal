-- PORTAL.sp_update_user
-- Aggiorna un utente: solo parametri DDL-canonici. Log su STATS_EXECUTION_LOG.
CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
  @user_id NVARCHAR(50),
  @tenant_id NVARCHAR(50),
  @name NVARCHAR(100),
  @surname NVARCHAR(100),
  @profile_code NVARCHAR(50),
  @status NVARCHAR(50),
  @is_tenant_admin BIT,
  @updated_by NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    UPDATE PORTAL.USERS
    SET
      name = @name,
      surname = @surname,
      profile_code = @profile_code,
      status = @status,
      is_tenant_admin = @is_tenant_admin,
      updated_at = SYSUTCDATETIME(),
      updated_by = @updated_by
    WHERE user_id = @user_id AND tenant_id = @tenant_id;

    INSERT INTO PORTAL.STATS_EXECUTION_LOG
      (event_type, entity, entity_id, changes, triggered_by, event_time)
    VALUES
      ('user_update', 'USERS', @user_id, 'update', @updated_by, SYSUTCDATETIME());

    SELECT * FROM PORTAL.USERS WHERE user_id = @user_id AND tenant_id = @tenant_id;
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
  END CATCH
END
