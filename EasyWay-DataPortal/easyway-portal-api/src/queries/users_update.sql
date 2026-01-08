-- Esegue update utenti solo tramite SP canonica: audit, parametri DDL-compliant
EXEC PORTAL.sp_update_user
  @tenant_id = @tenant_id,
  @user_id = @user_id,
  @email = @email,
  @display_name = @display_name,
  @profile_id = @profile_id,
  @is_active = @is_active,
  @updated_by = @updated_by;
