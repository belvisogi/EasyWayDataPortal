-- PORTAL.sp_subscribe_notification
-- Sottoscrive un utente a una categoria/canale notifiche. Audit log automatico.
CREATE OR ALTER PROCEDURE PORTAL.sp_subscribe_notification
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @category NVARCHAR(50),
  @channel NVARCHAR(50),
  @updated_by NVARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    MERGE PORTAL.USER_NOTIFICATION_SETTINGS AS target
    USING (SELECT @tenant_id AS tenant_id, @user_id AS user_id, @category AS category, @channel AS channel) AS src
    ON target.tenant_id = src.tenant_id AND target.user_id = src.user_id AND target.category = src.category AND target.channel = src.channel
    WHEN MATCHED THEN
      UPDATE SET updated_at = SYSUTCDATETIME(), updated_by = @updated_by
    WHEN NOT MATCHED THEN
      INSERT (tenant_id, user_id, category, channel, updated_by, updated_at)
      VALUES (src.tenant_id, src.user_id, src.category, src.channel, @updated_by, SYSUTCDATETIME());

    INSERT INTO PORTAL.STATS_EXECUTION_LOG
      (event_type, entity, entity_id, changes, triggered_by, event_time)
    VALUES
      ('notification_subscribe', 'USER_NOTIFICATION_SETTINGS', @user_id, 'subscribe', @updated_by, SYSUTCDATETIME());

    SELECT * FROM PORTAL.USER_NOTIFICATION_SETTINGS
    WHERE tenant_id = @tenant_id AND user_id = @user_id AND category = @category AND channel = @channel;

  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    RAISERROR(@msg, 16, 1);
  END CATCH
END
