CREATE SCHEMA [PORTAL]
GO

CREATE TABLE [PORTAL].[users] (
  [user_id] nvarchar(255) UNIQUE PRIMARY KEY,
  [tenant_id] nvarchar(255),
  [profile_id] nvarchar(255),
  [email] nvarchar(255) UNIQUE,
  [password] nvarchar(255),
  [is_active] boolean,
  [is_notify_enabled] boolean
)
GO

CREATE TABLE [PORTAL].[profiles] (
  [profile_id] nvarchar(255) UNIQUE PRIMARY KEY,
  [profile_name] nvarchar(255),
  [profile_description] nvarchar(255)
)
GO

CREATE TABLE [PORTAL].[tenants] (
  [tenant_id] nvarchar(255) UNIQUE PRIMARY KEY,
  [tenant_name] nvarchar(255),
  [tenant_description] nvarchar(255)
)
GO

CREATE TABLE [PORTAL].[user_notification_settings] (
  [user_id] nvarchar(255) PRIMARY KEY,
  [notify_email] boolean,
  [notify_portal] boolean,
  [notify_sms] boolean
)
GO

CREATE TABLE [PORTAL].[masking_metadata] (
  [masking_id] int PRIMARY KEY IDENTITY(1, 1),
  [schema_name] nvarchar(255),
  [table_name] nvarchar(255),
  [column_name] nvarchar(255),
  [masking_rule] nvarchar(255),
  [description] nvarchar(255)
)
GO

CREATE TABLE [PORTAL].[rls_metadata] (
  [rls_id] int PRIMARY KEY IDENTITY(1, 1),
  [schema_name] nvarchar(255),
  [table_name] nvarchar(255),
  [rls_filter_condition] nvarchar(255),
  [description] nvarchar(255)
)
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'NDG - Codice Cliente es: CDI00000001000',
@level0type = N'Schema', @level0name = 'PORTAL',
@level1type = N'Table',  @level1name = 'users',
@level2type = N'Column', @level2name = 'user_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Criptata, standard industry',
@level0type = N'Schema', @level0name = 'PORTAL',
@level1type = N'Table',  @level1name = 'users',
@level2type = N'Column', @level2name = 'password';
GO

ALTER TABLE [PORTAL].[users] ADD FOREIGN KEY ([tenant_id]) REFERENCES [PORTAL].[tenants] ([tenant_id])
GO

ALTER TABLE [PORTAL].[users] ADD FOREIGN KEY ([profile_id]) REFERENCES [PORTAL].[profiles] ([profile_id])
GO

ALTER TABLE [PORTAL].[user_notification_settings] ADD FOREIGN KEY ([user_id]) REFERENCES [PORTAL].[users] ([user_id])
GO
