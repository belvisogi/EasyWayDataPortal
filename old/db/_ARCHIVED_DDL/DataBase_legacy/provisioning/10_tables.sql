-- LEGACY: questo provisioning SQL può divergere da Flyway.
-- Usa `db/flyway/sql/` tramite `db/provisioning/apply-flyway.ps1`.
--
-- Idempotent tables for Azure SQL (use bit instead of boolean)

IF OBJECT_ID(N'[PORTAL].[users]', N'U') IS NULL
BEGIN
    CREATE TABLE [PORTAL].[users] (
      [user_id]               NVARCHAR(255) CONSTRAINT PK_users PRIMARY KEY,
      [tenant_id]             NVARCHAR(255) NULL,
      [profile_id]            NVARCHAR(255) NULL,
      [email]                 NVARCHAR(255) UNIQUE NOT NULL,
      [display_name]          NVARCHAR(255) NULL,
      [password]              NVARCHAR(255) NULL,
      [is_active]             BIT NOT NULL CONSTRAINT DF_users_is_active DEFAULT (1),
      [is_notify_enabled]     BIT NOT NULL CONSTRAINT DF_users_is_notify_enabled DEFAULT (1),
      [updated_at]            DATETIME2 NULL
    );
END
GO

-- Align existing table with expected columns (idempotent ALTERs)
IF COL_LENGTH('PORTAL.users', 'display_name') IS NULL
BEGIN
    ALTER TABLE [PORTAL].[users] ADD [display_name] NVARCHAR(255) NULL;
END
GO

IF COL_LENGTH('PORTAL.users', 'updated_at') IS NULL
BEGIN
    ALTER TABLE [PORTAL].[users] ADD [updated_at] DATETIME2 NULL;
END
GO

IF OBJECT_ID(N'[PORTAL].[profiles]', N'U') IS NULL
BEGIN
    CREATE TABLE [PORTAL].[profiles] (
      [profile_id]           NVARCHAR(255) CONSTRAINT PK_profiles PRIMARY KEY,
      [profile_name]         NVARCHAR(255) NOT NULL,
      [profile_description]  NVARCHAR(255) NULL
    );
END
GO

IF OBJECT_ID(N'[PORTAL].[tenants]', N'U') IS NULL
BEGIN
    CREATE TABLE [PORTAL].[tenants] (
      [tenant_id]            NVARCHAR(255) CONSTRAINT PK_tenants PRIMARY KEY,
      [tenant_name]          NVARCHAR(255) NOT NULL,
      [tenant_description]   NVARCHAR(255) NULL
    );
END
GO

IF OBJECT_ID(N'[PORTAL].[user_notification_settings]', N'U') IS NULL
BEGIN
    CREATE TABLE [PORTAL].[user_notification_settings] (
      [user_id]              NVARCHAR(255) CONSTRAINT PK_user_notification_settings PRIMARY KEY,
      [notify_email]         BIT NOT NULL CONSTRAINT DF_uns_notify_email DEFAULT (1),
      [notify_portal]        BIT NOT NULL CONSTRAINT DF_uns_notify_portal DEFAULT (1),
      [notify_sms]           BIT NOT NULL CONSTRAINT DF_uns_notify_sms DEFAULT (0)
    );
END
GO

IF OBJECT_ID(N'[PORTAL].[masking_metadata]', N'U') IS NULL
BEGIN
    CREATE TABLE [PORTAL].[masking_metadata] (
      [masking_id]           INT IDENTITY(1,1) CONSTRAINT PK_masking_metadata PRIMARY KEY,
      [schema_name]          NVARCHAR(255),
      [table_name]           NVARCHAR(255),
      [column_name]          NVARCHAR(255),
      [masking_rule]         NVARCHAR(255),
      [description]          NVARCHAR(255)
    );
END
GO

IF OBJECT_ID(N'[PORTAL].[rls_metadata]', N'U') IS NULL
BEGIN
    CREATE TABLE [PORTAL].[rls_metadata] (
      [rls_id]               INT IDENTITY(1,1) CONSTRAINT PK_rls_metadata PRIMARY KEY,
      [schema_name]          NVARCHAR(255),
      [table_name]           NVARCHAR(255),
      [rls_filter_condition] NVARCHAR(255),
      [description]          NVARCHAR(255)
    );
END
GO
