-- LEGACY: questo provisioning SQL può divergere da Flyway.
-- Usa `db/flyway/sql/` tramite `db/provisioning/apply-flyway.ps1`.
--
-- Extended properties (idempotent)

-- Column description for users.user_id
IF NOT EXISTS (
  SELECT 1 FROM sys.extended_properties ep
  JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
  JOIN sys.tables t ON t.object_id = c.object_id
  JOIN sys.schemas s ON s.schema_id = t.schema_id
  WHERE ep.name = N'Column_Description'
    AND s.name = N'PORTAL'
    AND t.name = N'users'
    AND c.name = N'user_id')
BEGIN
    EXEC sp_addextendedproperty
      @name = N'Column_Description',
      @value = 'NDG - Codice Cliente es: CDI00000001000',
      @level0type = N'Schema', @level0name = 'PORTAL',
      @level1type = N'Table',  @level1name = 'users',
      @level2type = N'Column', @level2name = 'user_id';
END
GO

-- Column description for users.password
IF NOT EXISTS (
  SELECT 1 FROM sys.extended_properties ep
  JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
  JOIN sys.tables t ON t.object_id = c.object_id
  JOIN sys.schemas s ON s.schema_id = t.schema_id
  WHERE ep.name = N'Column_Description'
    AND s.name = N'PORTAL'
    AND t.name = N'users'
    AND c.name = N'password')
BEGIN
    EXEC sp_addextendedproperty
      @name = N'Column_Description',
      @value = 'Criptata, standard industry',
      @level0type = N'Schema', @level0name = 'PORTAL',
      @level1type = N'Table',  @level1name = 'users',
      @level2type = N'Column', @level2name = 'password';
END
GO
