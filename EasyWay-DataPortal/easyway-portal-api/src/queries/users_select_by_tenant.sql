EXEC PORTAL.sp_list_users_by_tenant
  @tenant_id = @tenant_id,
  @include_inactive = 0;
