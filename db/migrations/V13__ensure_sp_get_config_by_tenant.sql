/* V13 — Ensure PORTAL.sp_get_config_by_tenant definition */
/* Fixes impedance mismatch between dbConfigLoader and legacy SP versions */

CREATE OR ALTER PROCEDURE PORTAL.sp_get_config_by_tenant
  @tenant_id NVARCHAR(50),
  @section NVARCHAR(64) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  /* 
     Select config_key, config_value 
     from PORTAL.CONFIGURATION
     where tenant_id matches
     and enabled = 1 (not is_active)
     and section matches (handling NULLs as empty string for normalization)
  */
  SELECT config_key, config_value
  FROM PORTAL.CONFIGURATION
  WHERE tenant_id = @tenant_id
    AND enabled = 1
    AND ISNULL(section, '') = ISNULL(@section, '')
END
GO
