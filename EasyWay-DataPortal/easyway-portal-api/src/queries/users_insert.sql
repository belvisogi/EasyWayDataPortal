-- users_insert.sql
EXEC PORTAL.sp_debug_register_tenant_and_user
  @tenant_id = @tenant_id,
  @email = @email,
  @display_name = @display_name,
  @profile_id = @profile_id;
