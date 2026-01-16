/* V14 — Refactor Onboarding to use nested-safe SPs (DRY + Atomic) */
GO

/* 1. Make sp_insert_tenant transaction-aware (Nested Transaction Pattern) */
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
  
  /* Nested Transaction Logic */
  DECLARE @hasOuterTran BIT = 0;
  IF @@TRANCOUNT > 0 SET @hasOuterTran = 1;

  BEGIN TRY
    IF @hasOuterTran = 0 BEGIN TRAN; END
    
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

    IF @hasOuterTran = 0 COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE();
    /* Only rollback if we started the transaction, OR if the error is severe enough to doom the transaction.
       Standard pattern: If outer exists, just re-throw or return error status. 
       However, simplified approach: If local, Rollback. If outer, do nothing (caller rolls back) OR commit impossible.
    */
    IF @hasOuterTran = 0 AND @@TRANCOUNT > 0 ROLLBACK;
    /* If outer exists, we do NOT rollback here, we return Error and let caller rollback. */
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_tenant', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_inserted;
END
GO

/* 2. Make sp_insert_user transaction-aware */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
  @user_id NVARCHAR(50) = NULL,
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320),
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; 
  DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  
  DECLARE @hasOuterTran BIT = 0;
  IF @@TRANCOUNT > 0 SET @hasOuterTran = 1;

  BEGIN TRY
    IF @hasOuterTran = 0 BEGIN TRAN; END

    IF @user_id IS NULL OR @user_id=''
    BEGIN DECLARE @seq BIGINT=NEXT VALUE FOR PORTAL.SEQ_USER_ID; SET @user_id='CDI'+RIGHT('000000000'+CAST(@seq AS NVARCHAR),9); END
    
    IF NOT EXISTS(SELECT 1 FROM PORTAL.USERS WHERE tenant_id=@tenant_id AND email=@email)
    BEGIN
      INSERT INTO PORTAL.USERS(user_id, tenant_id, email, display_name, profile_id, is_active, status, created_by)
      VALUES(@user_id, @tenant_id, @email, @display_name, @profile_id, 1, 'ACTIVE', COALESCE(@created_by,'sp_insert_user'));
      SET @rows=1;
    END
    
    IF @hasOuterTran = 0 COMMIT;
  END TRY 
  BEGIN CATCH 
    SET @status='ERROR'; SET @err=ERROR_MESSAGE(); 
    IF @hasOuterTran = 0 AND @@TRANCOUNT>0 ROLLBACK; 
  END CATCH

  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_user', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_inserted;
END
GO

/* 3. Create formal sp_register_tenant_and_user (Production) calling atomic SPs */
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
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
  
  /* Output table to capture results from nested calls */
  DECLARE @ResTenant TABLE (status NVARCHAR(50), tenant_id NVARCHAR(50), error_message NVARCHAR(2000), rows_inserted INT);
  DECLARE @ResUser TABLE (status NVARCHAR(50), user_id NVARCHAR(50), error_message NVARCHAR(2000), rows_inserted INT);

  BEGIN TRY
    BEGIN TRAN; /* Outer Transaction */

    /* 3.1 Insert Tenant */
    INSERT INTO @ResTenant EXEC PORTAL.sp_insert_tenant
      @tenant_id = @tenant_id,
      @tenant_name = @tenant_name,
      @plan_code = 'GOLD', /* Default plan */
      @ext_attributes = @ext_attributes,
      @created_by = 'sp_register_tenant_and_user';
      
    /* Check Tenant Result */
    DECLARE @tStatus NVARCHAR(50), @tErr NVARCHAR(2000), @tId NVARCHAR(50);
    SELECT TOP 1 @tStatus=status, @tErr=error_message, @tId=tenant_id, @rows_ins=rows_inserted FROM @ResTenant;
    
    IF @tStatus <> 'OK' THROW 50000, @tErr, 1;
    SET @tenant_id = @tId; /* In case it was auto-generated */

    /* 3.2 Insert User (optional but typical in registration) */
    IF @user_email IS NOT NULL
    BEGIN
      INSERT INTO @ResUser EXEC PORTAL.sp_insert_user
        @tenant_id = @tenant_id,
        @email = @user_email,
        @display_name = @display_name,
        @profile_id = @profile_id,
        @created_by = 'sp_register_tenant_and_user';
        
      DECLARE @uStatus NVARCHAR(50), @uErr NVARCHAR(2000), @uId NVARCHAR(50);
      SELECT TOP 1 @uStatus=status, @uErr=error_message, @uId=user_id, @rows_user=rows_inserted FROM @ResUser;

      IF @uStatus <> 'OK' THROW 50001, @uErr, 1;
      SET @user_id = @uId;
    END

    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); 
    IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_register_tenant_and_user', @tenant_id=@tenant_id, @rows_inserted=@rows_user, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT,PORTAL.USERS', @operation_types='INSERT', @created_by='sp_register_tenant_and_user';
  
  SELECT @status AS status, @tenant_id AS tenant_id, @user_id AS user_id, @err AS error_message, @rows_ins AS rows_tenant_inserted, @rows_user AS rows_user_inserted;
END
GO

/* 4. Drop legacy debug SP */
DROP PROCEDURE IF EXISTS PORTAL.sp_debug_register_tenant_and_user;
GO
