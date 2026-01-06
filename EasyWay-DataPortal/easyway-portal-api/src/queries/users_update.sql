-- Esegue update utenti solo tramite SP canonica: audit, parametri DDL-compliant
EXEC PORTAL.sp_update_user
  @user_id = @user_id,
  @tenant_id = @tenant_id,
  @name = @name,
  @surname = @surname,
  @profile_code = @profile_code,
  @status = @status,
  @is_tenant_admin = @is_tenant_admin,
  @updated_by = @updated_by;
