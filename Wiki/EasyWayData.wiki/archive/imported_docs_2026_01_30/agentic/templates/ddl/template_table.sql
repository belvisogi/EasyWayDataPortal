/* TEMPLATE TABELLA AGENTICA
Sostituire i segnaposto {{...}} prima del rilascio.
*/

IF OBJECT_ID('{{SCHEMA}}.{{TABLE}}', 'U') IS NULL
BEGIN
  CREATE TABLE {{SCHEMA}}.{{TABLE}} (
    id INT IDENTITY(1,1) PRIMARY KEY,
    -- colonne business
    -- {{COLUMNS}}
    created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END

