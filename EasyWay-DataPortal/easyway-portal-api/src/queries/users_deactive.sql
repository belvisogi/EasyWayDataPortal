-- users_deactive.sql
EXEC PORTAL.sp_delete_user
  @tenant_id = @tenant_id,
  @user_id = @user_id,
  @deleted_by = @deleted_by;
