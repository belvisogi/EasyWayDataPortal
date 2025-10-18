CREATE TABLE [PORTAL_TENANT] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [tenant_id] nvarchar UNIQUE NOT NULL,
  [name] nvarchar NOT NULL,
  [plan_code] nvarchar NOT NULL,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_PROFILE_DOMAINS] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [profile_code] nvarchar UNIQUE NOT NULL,
  [description] nvarchar,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_USERS] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [user_id] nvarchar UNIQUE NOT NULL,
  [tenant_id] nvarchar NOT NULL,
  [email] nvarchar NOT NULL,
  [name] nvarchar,
  [surname] nvarchar,
  [password] nvarchar,
  [provider] nvarchar,
  [provider_user_id] nvarchar,
  [status] nvarchar,
  [profile_code] nvarchar NOT NULL,
  [is_tenant_admin] bit,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_SECTION_ACCESS] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [tenant_id] nvarchar NOT NULL,
  [section_code] nvarchar,
  [is_enabled] bit,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_USER_NOTIFICATION_SETTINGS] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [tenant_id] nvarchar NOT NULL,
  [user_id] nvarchar NOT NULL,
  [notify_on_upload] bit,
  [notify_on_alert] bit,
  [notify_on_digest] bit,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_MASKING_METADATA] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [tenant_id] nvarchar,
  [schema_name] nvarchar,
  [table_name] nvarchar,
  [column_name] nvarchar,
  [mask_type] nvarchar,
  [note] nvarchar,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_RLS_METADATA] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [tenant_id] nvarchar,
  [schema_name] nvarchar,
  [table_name] nvarchar,
  [column_name] nvarchar,
  [policy_name] nvarchar,
  [predicate_function] nvarchar,
  [note] nvarchar,
  [ext_attributes] nvarchar,
  [created_by] nvarchar,
  [created_at] datetime2,
  [updated_at] datetime2
)
GO

CREATE TABLE [PORTAL_CONFIGURATION] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [tenant_id] nvarchar(255),
  [config_key] nvarchar(255) NOT NULL,
  [config_value] nvarchar(255) NOT NULL,
  [description] nvarchar(255),
  [is_active] boolean,
  [created_by] nvarchar(255),
  [created_at] datetime,
  [updated_at] datetime
)
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Codice identificativo cliente / tenant (NDG es. TEN00000001000)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Ragione sociale / nome visualizzato del tenant',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Piano commerciale (Bronze, Silver, Gold)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'plan_code';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_TENANT',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Codice profilo ACL es. TENANT_ADMIN',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_PROFILE_DOMAINS',
@level2type = N'Column', @level2name = 'profile_code';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Descrizione funzionale del profilo',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_PROFILE_DOMAINS',
@level2type = N'Column', @level2name = 'description';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_PROFILE_DOMAINS',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_PROFILE_DOMAINS',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_PROFILE_DOMAINS',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_PROFILE_DOMAINS',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Codice identificativo utente (NDG es. CDI00000001000)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'user_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Tenant di appartenenza',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Email di login',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'email';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome anagrafico',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Cognome anagrafico',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'surname';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Password criptata (NULL se login federato)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'password';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Provider federato (Google, Microsoft, SAML, NULL=locale)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'provider';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ID restituito dal provider esterno',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'provider_user_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Stato utente (attivo, sospeso, ecc.)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'status';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Codice profilo ACL',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'profile_code';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Flag amministratore del tenant',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'is_tenant_admin';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USERS',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Tenant di appartenenza',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Codice sezione es. SOSTENIBILITA, DATAQUALITY',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'section_code';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Flag abilitazione accesso',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'is_enabled';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_SECTION_ACCESS',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Tenant di appartenenza',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'FK utente',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'user_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Notifica upload attivata',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'notify_on_upload';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Notifica alert attivata',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'notify_on_alert';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Notifica periodica attivata',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'notify_on_digest';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_USER_NOTIFICATION_SETTINGS',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Tenant specifico o NULL = globale',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome schema',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'schema_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome tabella',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'table_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome colonna',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'column_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Tipo mascheramento DDM',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'mask_type';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Note operative',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'note';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_MASKING_METADATA',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Tenant specifico o NULL = globale',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome schema',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'schema_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome tabella',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'table_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Colonna tenant id',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'column_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome della policy',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'policy_name';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nome funzione RLS',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'predicate_function';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Note operative',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'note';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Estensioni JSON custom',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'ext_attributes';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_RLS_METADATA',
@level2type = N'Column', @level2name = 'updated_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'NULL = globale, valorizzato = solo per quel tenant',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'tenant_id';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Parametro configurabile, es. ''MAX_FILE_SIZE_MB'', ...',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'config_key';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Valore parametrico, supporta stringa/json/int',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'config_value';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Nota descrittiva/tecnica',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'description';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Flag attivo/disattivo',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'is_active';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Utente che ha creato il record',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'created_by';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data creazione record (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'created_at';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'Data ultima modifica (UTC)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'PORTAL_CONFIGURATION',
@level2type = N'Column', @level2name = 'updated_at';
GO

ALTER TABLE [PORTAL_USERS] ADD FOREIGN KEY ([tenant_id]) REFERENCES [PORTAL_TENANT] ([tenant_id])
GO

ALTER TABLE [PORTAL_USERS] ADD FOREIGN KEY ([profile_code]) REFERENCES [PORTAL_PROFILE_DOMAINS] ([profile_code])
GO

ALTER TABLE [PORTAL_SECTION_ACCESS] ADD FOREIGN KEY ([tenant_id]) REFERENCES [PORTAL_TENANT] ([tenant_id])
GO

ALTER TABLE [PORTAL_USER_NOTIFICATION_SETTINGS] ADD FOREIGN KEY ([tenant_id]) REFERENCES [PORTAL_TENANT] ([tenant_id])
GO

ALTER TABLE [PORTAL_USER_NOTIFICATION_SETTINGS] ADD FOREIGN KEY ([user_id]) REFERENCES [PORTAL_USERS] ([user_id])
GO

ALTER TABLE [PORTAL_CONFIGURATION] ADD FOREIGN KEY ([tenant_id]) REFERENCES [PORTAL_TENANT] ([tenant_id])
GO
