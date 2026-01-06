-- PORTAL.sp_get_config_by_tenant
-- Restituisce tutte le configurazioni attive per un tenant. No legacy, parametri DDL-compliant.
CREATE OR ALTER PROCEDURE PORTAL.sp_get_config_by_tenant
  @tenant_id NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT config_key, config_value
  FROM PORTAL.CONFIGURATION
  WHERE tenant_id = @tenant_id AND is_active = 1;
END
