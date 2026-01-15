/* V11 - Users read SP (list by tenant) */
GO

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
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_list_users_by_tenant',
    @tenant_id=@tenant_id,
    @rows_updated=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.USERS',
    @operation_types='SELECT',
    @created_by=COALESCE(@requested_by,'sp_list_users_by_tenant');
END
GO
