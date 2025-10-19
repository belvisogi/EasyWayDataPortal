/* V9 — SP CRUD for USERS, CONFIGURATION, PROFILE_DOMAINS (ACL) */
GO

/* USERS */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
  @user_id NVARCHAR(50) = NULL,
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320),
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    BEGIN TRAN;
    IF @user_id IS NULL OR @user_id=''
    BEGIN DECLARE @seq BIGINT=NEXT VALUE FOR PORTAL.SEQ_USER_ID; SET @user_id='CDI'+RIGHT('000000000'+CAST(@seq AS NVARCHAR),9); END
    IF NOT EXISTS(SELECT 1 FROM PORTAL.USERS WHERE tenant_id=@tenant_id AND email=@email)
    BEGIN
      INSERT INTO PORTAL.USERS(user_id, tenant_id, email, display_name, profile_id, is_active, status, created_by)
      VALUES(@user_id, @tenant_id, @email, @display_name, @profile_id, 1, 'ACTIVE', COALESCE(@created_by,'sp_insert_user'));
      SET @rows=1;
    END
    COMMIT;
  END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_user', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_inserted;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @email NVARCHAR(320) = NULL,
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @is_active BIT = NULL,
  @updated_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    BEGIN TRAN;
    UPDATE PORTAL.USERS SET
      email=COALESCE(@email,email), display_name=COALESCE(@display_name,display_name), profile_id=COALESCE(@profile_id,profile_id), is_active=COALESCE(@is_active,is_active), updated_at=SYSUTCDATETIME(), created_by=COALESCE(@updated_by,'sp_update_user')
    WHERE tenant_id=@tenant_id AND user_id=@user_id;
    SET @rows=@@ROWCOUNT; COMMIT;
  END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_user', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_updated;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    BEGIN TRAN;
    UPDATE PORTAL.USERS SET is_active=0, status='INACTIVE', updated_at=SYSUTCDATETIME(), created_by=COALESCE(@deleted_by,'sp_delete_user')
    WHERE tenant_id=@tenant_id AND user_id=@user_id;
    SET @rows=@@ROWCOUNT; COMMIT;
  END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_user', @tenant_id=@tenant_id, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_deleted;
END
GO

/* CONFIGURATION */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
  @tenant_id NVARCHAR(50), @section NVARCHAR(64)=NULL, @config_key NVARCHAR(100), @config_value NVARCHAR(MAX), @enabled BIT=1, @created_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN;
    IF NOT EXISTS(SELECT 1 FROM PORTAL.CONFIGURATION WHERE tenant_id=@tenant_id AND ISNULL(section,'')=ISNULL(@section,'') AND config_key=@config_key)
    BEGIN INSERT INTO PORTAL.CONFIGURATION(tenant_id, section, config_key, config_value, enabled, created_by) VALUES(@tenant_id,@section,@config_key,@config_value,@enabled,COALESCE(@created_by,'sp_insert_configuration')); SET @rows=1; END
    COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_configuration', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.CONFIGURATION', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_configuration'); SELECT @status AS status, @rows AS rows_inserted; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
  @tenant_id NVARCHAR(50), @section NVARCHAR(64)=NULL, @config_key NVARCHAR(100), @config_value NVARCHAR(MAX)=NULL, @enabled BIT=NULL, @updated_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN;
    UPDATE PORTAL.CONFIGURATION SET config_value=COALESCE(@config_value,config_value), enabled=COALESCE(@enabled,enabled), updated_at=SYSUTCDATETIME(), created_by=COALESCE(@updated_by,'sp_update_configuration')
    WHERE tenant_id=@tenant_id AND ISNULL(section,'')=ISNULL(@section,'') AND config_key=@config_key; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_configuration', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.CONFIGURATION', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_configuration'); SELECT @status AS status, @rows AS rows_updated; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
  @tenant_id NVARCHAR(50), @section NVARCHAR(64)=NULL, @config_key NVARCHAR(100), @deleted_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; DELETE FROM PORTAL.CONFIGURATION WHERE tenant_id=@tenant_id AND ISNULL(section,'')=ISNULL(@section,'') AND config_key=@config_key; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_configuration', @tenant_id=@tenant_id, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.CONFIGURATION', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_configuration'); SELECT @status AS status, @rows AS rows_deleted; END
GO

/* ACL: PROFILE_DOMAINS */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
  @profile_code NVARCHAR(50), @description NVARCHAR(255)=NULL, @created_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; IF NOT EXISTS(SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code=@profile_code) BEGIN INSERT INTO PORTAL.PROFILE_DOMAINS(profile_code,description,created_by) VALUES(@profile_code,@description,COALESCE(@created_by,'sp_insert_profile_domain')); SET @rows=1; END COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_profile_domain', @tenant_id=NULL, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.PROFILE_DOMAINS', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_profile_domain'); SELECT @status AS status, @rows AS rows_inserted; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
  @profile_code NVARCHAR(50), @description NVARCHAR(255)=NULL, @updated_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; UPDATE PORTAL.PROFILE_DOMAINS SET description=COALESCE(@description,description), updated_at=SYSUTCDATETIME(), created_by=COALESCE(@updated_by,'sp_update_profile_domain') WHERE profile_code=@profile_code; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_profile_domain', @tenant_id=NULL, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.PROFILE_DOMAINS', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_profile_domain'); SELECT @status AS status, @rows AS rows_updated; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
  @profile_code NVARCHAR(50), @deleted_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code=@profile_code; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_profile_domain', @tenant_id=NULL, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.PROFILE_DOMAINS', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_profile_domain'); SELECT @status AS status, @rows AS rows_deleted; END
GO

