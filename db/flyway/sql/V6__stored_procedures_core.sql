/* V6 — Core Stored Procedures (logging + TENANT CRUD + debug register tenant+user + notify stub) */
GO

/* Logging: sp_log_stats_execution */
CREATE OR ALTER PROCEDURE PORTAL.sp_log_stats_execution
  @proc_name NVARCHAR(255),
  @tenant_id NVARCHAR(50) = NULL,
  @rows_inserted INT = NULL,
  @rows_updated INT = NULL,
  @rows_deleted INT = NULL,
  @status NVARCHAR(16) = NULL,
  @error_message NVARCHAR(MAX) = NULL,
  @start_time DATETIME2 = NULL,
  @end_time DATETIME2 = NULL,
  @affected_tables NVARCHAR(512) = NULL,
  @operation_types NVARCHAR(128) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @exec_id UNIQUEIDENTIFIER = NEWSEQUENTIALID();
  INSERT INTO PORTAL.STATS_EXECUTION_LOG(execution_id, proc_name, tenant_id, start_time, end_time, status, error_message, rows_inserted, rows_updated, rows_deleted, created_by)
  VALUES(@exec_id, @proc_name, @tenant_id, COALESCE(@start_time, SYSUTCDATETIME()), COALESCE(@end_time, SYSUTCDATETIME()), @status, @error_message, @rows_inserted, @rows_updated, @rows_deleted, @created_by);
  IF @affected_tables IS NOT NULL
  BEGIN
    INSERT INTO PORTAL.STATS_EXECUTION_TABLE_LOG(execution_id, table_name, operation_types, rows_affected)
    SELECT @exec_id, value, @operation_types, NULL FROM STRING_SPLIT(@affected_tables, ',');
  END
END
GO

/* Optional detail SP (not strictly required by above, but available) */
CREATE OR ALTER PROCEDURE PORTAL.sp_log_stats_table
  @execution_id UNIQUEIDENTIFIER,
  @table_name NVARCHAR(256),
  @operation_types NVARCHAR(64) = NULL,
  @rows_affected INT = NULL
AS
BEGIN
  INSERT INTO PORTAL.STATS_EXECUTION_TABLE_LOG(execution_id, table_name, operation_types, rows_affected)
  VALUES(@execution_id, @table_name, @operation_types, @rows_affected);
END
GO

/* TENANT CRUD (aligned to manifesto: tenant_name) */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
  @tenant_id NVARCHAR(50) = NULL,
  @tenant_name NVARCHAR(255),
  @plan_code NVARCHAR(50),
  @ext_attributes NVARCHAR(MAX) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT = 0, @status NVARCHAR(50) = 'OK', @err NVARCHAR(2000) = NULL;
  BEGIN TRY
    BEGIN TRAN;
    IF @tenant_id IS NULL OR @tenant_id = ''
    BEGIN
      DECLARE @seq BIGINT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
      SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
    END
    IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id=@tenant_id)
    BEGIN
      INSERT INTO PORTAL.TENANT(tenant_id, tenant_name, plan_code, status, ext_attributes, created_by)
      VALUES(@tenant_id, @tenant_name, @plan_code, 'ACTIVE', @ext_attributes, COALESCE(@created_by,'sp_insert_tenant'));
      SET @rows = 1;
    END
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_tenant', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_inserted;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
  @tenant_id NVARCHAR(50),
  @tenant_name NVARCHAR(255) = NULL,
  @plan_code NVARCHAR(50) = NULL,
  @status_in NVARCHAR(50) = NULL,
  @ext_attributes NVARCHAR(MAX) = NULL,
  @updated_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT=0, @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  BEGIN TRY
    BEGIN TRAN;
    UPDATE PORTAL.TENANT
      SET tenant_name = COALESCE(@tenant_name, tenant_name),
          plan_code = COALESCE(@plan_code, plan_code),
          status = COALESCE(@status_in, status),
          ext_attributes = COALESCE(@ext_attributes, ext_attributes),
          updated_at = SYSUTCDATETIME(),
          created_by = COALESCE(@updated_by,'sp_update_tenant')
    WHERE tenant_id=@tenant_id;
    SET @rows = @@ROWCOUNT;
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_tenant', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_updated;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
  @tenant_id NVARCHAR(50),
  @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT=0, @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  BEGIN TRY
    BEGIN TRAN;
    DELETE FROM PORTAL.TENANT WHERE tenant_id=@tenant_id;
    SET @rows = @@ROWCOUNT;
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_tenant', @tenant_id=@tenant_id, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_deleted;
END
GO

/* DEBUG combined register: tenant + user (used by API onboarding/users) */
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
  @tenant_id NVARCHAR(50) = NULL,
  @tenant_name NVARCHAR(255) = NULL,
  @user_email NVARCHAR(320) = NULL,
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @ext_attributes NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  DECLARE @rows_ins INT=0, @rows_user INT=0;
  DECLARE @user_id NVARCHAR(50) = NULL;
  BEGIN TRY
    BEGIN TRAN;
    IF (@tenant_id IS NULL OR @tenant_id='') AND @tenant_name IS NOT NULL
    BEGIN
      DECLARE @seqT BIGINT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
      SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@seqT AS NVARCHAR),3);
      IF NOT EXISTS(SELECT 1 FROM PORTAL.TENANT WHERE tenant_id=@tenant_id)
        INSERT INTO PORTAL.TENANT(tenant_id, tenant_name, plan_code, status, ext_attributes, created_by)
        VALUES(@tenant_id, @tenant_name, 'GOLD', 'ACTIVE', @ext_attributes, 'sp_debug_register_tenant_and_user');
      SET @rows_ins = 1;
    END
    /* create user if provided */
    IF @user_email IS NOT NULL
    BEGIN
      DECLARE @seqU BIGINT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
      SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@seqU AS NVARCHAR),3);
      IF NOT EXISTS(SELECT 1 FROM PORTAL.USERS WHERE tenant_id=@tenant_id AND email=@user_email)
      BEGIN
        INSERT INTO PORTAL.USERS(user_id, tenant_id, email, display_name, profile_id, is_active, status, ext_attributes, created_by)
        VALUES(@user_id, @tenant_id, @user_email, @display_name, @profile_id, 1, 'ACTIVE', @ext_attributes, 'sp_debug_register_tenant_and_user');
        SET @rows_user = 1;
      END
    END
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_debug_register_tenant_and_user', @tenant_id=@tenant_id, @rows_inserted=@rows_user, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT,PORTAL.USERS', @operation_types='INSERT', @created_by='sp_debug_register_tenant_and_user';
  SELECT @status AS status, @tenant_id AS tenant_id, @user_id AS user_id, @err AS error_message, @rows_ins AS rows_tenant_inserted, @rows_user AS rows_user_inserted;
END
GO

/* Notifications stub used by API */
CREATE OR ALTER PROCEDURE PORTAL.sp_send_notification
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @category NVARCHAR(32),
  @channel NVARCHAR(16),
  @message NVARCHAR(MAX),
  @ext_attributes NVARCHAR(MAX) = NULL
AS
BEGIN
  INSERT INTO PORTAL.LOG_AUDIT(event_time, tenant_id, actor, origin, category, message, payload, status)
  VALUES(SYSUTCDATETIME(), @tenant_id, @user_id, 'api', @category, @message, @ext_attributes, 'SENT');
  SELECT 'OK' AS status;
END
GO

