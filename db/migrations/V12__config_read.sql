/* V12 — Config Read SP (missing dependency) */
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_get_config_by_tenant
  @tenant_id NVARCHAR(50),
  @section NVARCHAR(64) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  SELECT config_key, config_value
  FROM PORTAL.CONFIGURATION
  WHERE tenant_id = @tenant_id
    AND enabled = 1
    AND ISNULL(section, '') = ISNULL(@section, '')
END
GO
