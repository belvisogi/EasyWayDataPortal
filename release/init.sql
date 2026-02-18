-- Baseline schema (placeholder): document here initial state if needed.
-- For existing DBs, run: flyway baseline -baselineVersion=1

/* V1 — Create logical schemas */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'PORTAL') EXEC('CREATE SCHEMA PORTAL');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'BRONZE') EXEC('CREATE SCHEMA BRONZE');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'SILVER') EXEC('CREATE SCHEMA SILVER');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'GOLD') EXEC('CREATE SCHEMA GOLD');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'REPORTING') EXEC('CREATE SCHEMA REPORTING');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'WORK') EXEC('CREATE SCHEMA WORK');

/* V2 — Core sequences for NDG codes (numeric part) */

/* Tenant */
IF NOT EXISTS (
  SELECT 1 FROM sys.sequences WHERE name = 'SEQ_TENANT_ID' AND SCHEMA_NAME(schema_id)='PORTAL'
)
BEGIN
  CREATE SEQUENCE PORTAL.SEQ_TENANT_ID AS BIGINT START WITH 1000 INCREMENT BY 1;
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.sequences WHERE name = 'SEQ_TENANT_ID_DEBUG' AND SCHEMA_NAME(schema_id)='PORTAL'
)
BEGIN
  CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG AS BIGINT START WITH 1 INCREMENT BY 1;
END;

/* Users */
IF NOT EXISTS (
  SELECT 1 FROM sys.sequences WHERE name = 'SEQ_USER_ID' AND SCHEMA_NAME(schema_id)='PORTAL'
)
BEGIN
  CREATE SEQUENCE PORTAL.SEQ_USER_ID AS BIGINT START WITH 1000 INCREMENT BY 1;
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.sequences WHERE name = 'SEQ_USER_ID_DEBUG' AND SCHEMA_NAME(schema_id)='PORTAL'
)
BEGIN
  CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG AS BIGINT START WITH 1 INCREMENT BY 1;
END;

/* V3 — Core tables in PORTAL schema (tenancy, users, configuration) */

/* TENANT */
IF OBJECT_ID('PORTAL.TENANT','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.TENANT (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id     NVARCHAR(50) NOT NULL,
    tenant_name   NVARCHAR(255) NOT NULL,
    plan_code     NVARCHAR(50) NULL,
    status        NVARCHAR(50) NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by    NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_TENANT_created_by DEFAULT ('MANUAL'),
    created_at    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_TENANT_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_TENANT_updated_at DEFAULT (SYSUTCDATETIME())
  );
  CREATE UNIQUE INDEX UX_PORTAL_TENANT_tenant_id ON PORTAL.TENANT(tenant_id);
END;

/* USERS */
IF OBJECT_ID('PORTAL.USERS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.USERS (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    user_id       NVARCHAR(50) NOT NULL,
    tenant_id     NVARCHAR(50) NOT NULL,
    email         NVARCHAR(320) NOT NULL,
    display_name  NVARCHAR(100) NULL,
    profile_id    NVARCHAR(64) NULL,
    is_active     BIT NOT NULL CONSTRAINT DF_PORTAL_USERS_is_active DEFAULT (1),
    status        NVARCHAR(50) NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by    NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_USERS_created_by DEFAULT ('MANUAL'),
    created_at    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_USERS_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_USERS_updated_at DEFAULT (SYSUTCDATETIME())
  );
  CREATE UNIQUE INDEX UX_PORTAL_USERS_user ON PORTAL.USERS(tenant_id, user_id);
  CREATE UNIQUE INDEX UX_PORTAL_USERS_email ON PORTAL.USERS(tenant_id, email);
  CREATE INDEX IX_PORTAL_USERS_tenant ON PORTAL.USERS(tenant_id);
END;

/* CONFIGURATION */
IF OBJECT_ID('PORTAL.CONFIGURATION','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.CONFIGURATION (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id     NVARCHAR(50) NOT NULL,
    section       NVARCHAR(64) NULL,
    section_normalized AS (ISNULL(section,'')) PERSISTED,
    config_key    NVARCHAR(100) NOT NULL,
    config_value  NVARCHAR(MAX) NULL,
    enabled       BIT NOT NULL CONSTRAINT DF_PORTAL_CONFIGURATION_enabled DEFAULT (1),
    created_by    NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_CONFIGURATION_created_by DEFAULT ('MANUAL'),
    created_at    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_CONFIGURATION_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_CONFIGURATION_updated_at DEFAULT (SYSUTCDATETIME())
  );
  CREATE UNIQUE INDEX UX_PORTAL_CONFIGURATION_key ON PORTAL.CONFIGURATION(tenant_id, section_normalized, config_key);
END;

/* FK logical enforcement left to application layer; future: add FK to TENANT(tenant_id) if modeled as table key */

/* V3.1 — Additional core tables in PORTAL schema */

/* PROFILE_DOMAINS */
IF OBJECT_ID('PORTAL.PROFILE_DOMAINS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.PROFILE_DOMAINS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    profile_code NVARCHAR(50) UNIQUE NOT NULL,
    description NVARCHAR(255) NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_PROFILE_DOMAINS_created_by DEFAULT('MANUAL'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_PROFILE_DOMAINS_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_PROFILE_DOMAINS_updated_at DEFAULT SYSUTCDATETIME()
  );
END;

/* SECTION_ACCESS */
IF OBJECT_ID('PORTAL.SECTION_ACCESS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.SECTION_ACCESS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,
    section_code NVARCHAR(50) NULL,
    profile_code NVARCHAR(50) NULL,
    user_id NVARCHAR(50) NULL,
    is_enabled BIT NULL,
    valid_from DATETIME2 NULL,
    valid_to DATETIME2 NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_SECTION_ACCESS_created_by DEFAULT('MANUAL'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_SECTION_ACCESS_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_SECTION_ACCESS_updated_at DEFAULT SYSUTCDATETIME()
  );
END;

/* USER_NOTIFICATION_SETTINGS */
IF OBJECT_ID('PORTAL.USER_NOTIFICATION_SETTINGS','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.USER_NOTIFICATION_SETTINGS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,
    user_id NVARCHAR(50) NOT NULL,
    notify_on_upload BIT NULL,
    notify_on_alert BIT NULL,
    notify_on_digest BIT NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_USER_NOTIF_created_by DEFAULT('MANUAL'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_USER_NOTIF_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_USER_NOTIF_updated_at DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_PORTAL_USER_NOTIF_tenant_user ON PORTAL.USER_NOTIFICATION_SETTINGS(tenant_id, user_id);
END;

/* SUBSCRIPTION */
IF OBJECT_ID('PORTAL.SUBSCRIPTION','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.SUBSCRIPTION (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,
    plan_code NVARCHAR(50) NOT NULL,
    status NVARCHAR(50) NOT NULL,
    start_date DATETIME2 NOT NULL,
    end_date DATETIME2 NOT NULL,
    external_payment_id NVARCHAR(100) NULL,
    payment_provider NVARCHAR(50) NULL,
    last_payment_date DATETIME2 NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_SUBSCRIPTION_created_by DEFAULT('MANUAL'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_SUBSCRIPTION_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_SUBSCRIPTION_updated_at DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_PORTAL_SUBSCRIPTION_tenant ON PORTAL.SUBSCRIPTION(tenant_id);
END;

/* MASKING_METADATA */
IF OBJECT_ID('PORTAL.MASKING_METADATA','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.MASKING_METADATA (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NULL,
    schema_name NVARCHAR(50) NULL,
    table_name NVARCHAR(100) NULL,
    column_name NVARCHAR(100) NULL,
    mask_type NVARCHAR(50) NULL,
    note NVARCHAR(255) NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_MASKING_created_by DEFAULT('MANUAL'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_MASKING_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_MASKING_updated_at DEFAULT SYSUTCDATETIME()
  );
END;

/* RLS_METADATA */
IF OBJECT_ID('PORTAL.RLS_METADATA','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.RLS_METADATA (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NULL,
    schema_name NVARCHAR(50) NULL,
    table_name NVARCHAR(100) NULL,
    column_name NVARCHAR(100) NULL,
    policy_name NVARCHAR(100) NULL,
    predicate_function NVARCHAR(255) NULL,
    note NVARCHAR(255) NULL,
    ext_attributes NVARCHAR(MAX) NULL,
    created_by NVARCHAR(255) NOT NULL CONSTRAINT DF_PORTAL_RLS_created_by DEFAULT('MANUAL'),
    created_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_RLS_created_at DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NOT NULL CONSTRAINT DF_PORTAL_RLS_updated_at DEFAULT SYSUTCDATETIME()
  );
END;

/* V4 — Logging & Auditing tables */

/* LOG_AUDIT */
IF OBJECT_ID('PORTAL.LOG_AUDIT','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.LOG_AUDIT (
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    event_time    DATETIME2      NOT NULL CONSTRAINT DF_PORTAL_LOG_AUDIT_event_time DEFAULT (SYSUTCDATETIME()),
    tenant_id     NVARCHAR(50)   NULL,
    actor         NVARCHAR(255)  NULL,      -- user/chatbot/service
    origin        NVARCHAR(64)   NULL,      -- api, agent, ams, job
    category      NVARCHAR(64)   NULL,      -- security, notify, config, etc.
    message       NVARCHAR(MAX)  NULL,
    payload       NVARCHAR(MAX)  NULL,      -- JSON
    status        NVARCHAR(32)   NULL
  );
  CREATE INDEX IX_PORTAL_LOG_AUDIT_tenant_time ON PORTAL.LOG_AUDIT(tenant_id, event_time);
END;

/* STATS_EXECUTION_LOG */
IF OBJECT_ID('PORTAL.STATS_EXECUTION_LOG','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.STATS_EXECUTION_LOG (
    execution_id  UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_PORTAL_STATS_EXECUTION_LOG_id DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    proc_name     NVARCHAR(255) NOT NULL,
    tenant_id     NVARCHAR(50)  NULL,
    start_time    DATETIME2     NOT NULL CONSTRAINT DF_PORTAL_STATS_EXECUTION_LOG_start DEFAULT (SYSUTCDATETIME()),
    end_time      DATETIME2     NULL,
    status        NVARCHAR(16)  NULL,       -- OK / ERROR
    error_message NVARCHAR(MAX) NULL,
    rows_inserted INT           NULL,
    rows_updated  INT           NULL,
    rows_deleted  INT           NULL,
    created_by    NVARCHAR(255) NULL
  );
  CREATE INDEX IX_PORTAL_STATS_EXECUTION_LOG_time ON PORTAL.STATS_EXECUTION_LOG(start_time);
  CREATE INDEX IX_PORTAL_STATS_EXECUTION_LOG_tenant ON PORTAL.STATS_EXECUTION_LOG(tenant_id);
END;

/* STATS_EXECUTION_TABLE_LOG */
IF OBJECT_ID('PORTAL.STATS_EXECUTION_TABLE_LOG','U') IS NULL
BEGIN
  CREATE TABLE PORTAL.STATS_EXECUTION_TABLE_LOG (
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    execution_id  UNIQUEIDENTIFIER NOT NULL,
    table_name    NVARCHAR(256) NOT NULL,   -- schema.table
    operation_types NVARCHAR(64) NULL,      -- INSERT, UPDATE, DELETE
    rows_affected INT          NULL
  );
  CREATE INDEX IX_PORTAL_STATS_EXECUTION_TABLE_LOG_exec ON PORTAL.STATS_EXECUTION_TABLE_LOG(execution_id);
  ALTER TABLE PORTAL.STATS_EXECUTION_TABLE_LOG
    ADD CONSTRAINT FK_STATS_TABLE_EXEC FOREIGN KEY (execution_id)
    REFERENCES PORTAL.STATS_EXECUTION_LOG(execution_id) ON DELETE CASCADE;
END;

/* V5 — Row-Level Security (RLS) setup
   NOTE: Requires application to set SESSION_CONTEXT('tenant_id') = <current_tenant>
   Example per-connection:
     EXEC sp_set_session_context @key = N'tenant_id', @value = @currentTenant;
*/
GO

/* Inline table-valued function used as predicate */
CREATE OR ALTER FUNCTION PORTAL.fn_rls_tenant_filter(@tenant_id NVARCHAR(50))
RETURNS TABLE
AS
RETURN (
  SELECT 1 AS fn_result
  WHERE (
    @tenant_id = CAST(SESSION_CONTEXT(N'tenant_id') AS NVARCHAR(50))
    OR IS_MEMBER(N'db_owner') = 1
  )
);
GO

/* SECURITY POLICY on USERS (disabled by default; enable after app sets session context) */
IF NOT EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'RLS_TENANT_POLICY_USERS')
BEGIN
  CREATE SECURITY POLICY PORTAL.RLS_TENANT_POLICY_USERS
  ADD FILTER PREDICATE PORTAL.fn_rls_tenant_filter(tenant_id) ON PORTAL.USERS
  WITH (STATE = OFF);
END;
GO

/* To enable RLS in environment: */
/* ALTER SECURITY POLICY PORTAL.RLS_TENANT_POLICY_USERS WITH (STATE = ON); */

/* V6 — Core Stored Procedures (logging + TENANT CRUD + debug register tenant+user + notify stub) */
GO

/* Logging: sp_log_stats_execution */
CREATE OR ALTER PROCEDURE PORTAL.sp_log_stats_execution
  @proc_name NVARCHAR(255),
  @tenant_id NVARCHAR(50) = NULL,
  @rows_inserted INT = NULL,
  @rows_updated INT = NULL,
  @rows_deleted INT = NULL,
  @status NVARCHAR(16) = NULL,
  @error_message NVARCHAR(MAX) = NULL,
  @start_time DATETIME2 = NULL,
  @end_time DATETIME2 = NULL,
  @affected_tables NVARCHAR(512) = NULL,
  @operation_types NVARCHAR(128) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @exec_id UNIQUEIDENTIFIER = NEWID();
  INSERT INTO PORTAL.STATS_EXECUTION_LOG(execution_id, proc_name, tenant_id, start_time, end_time, status, error_message, rows_inserted, rows_updated, rows_deleted, created_by)
  VALUES(@exec_id, @proc_name, @tenant_id, COALESCE(@start_time, SYSUTCDATETIME()), COALESCE(@end_time, SYSUTCDATETIME()), @status, @error_message, @rows_inserted, @rows_updated, @rows_deleted, @created_by);
  IF @affected_tables IS NOT NULL
  BEGIN
    INSERT INTO PORTAL.STATS_EXECUTION_TABLE_LOG(execution_id, table_name, operation_types, rows_affected)
    SELECT @exec_id, value, @operation_types, NULL FROM STRING_SPLIT(@affected_tables, ',');
  END
END
GO

/* Optional detail SP (not strictly required by above, but available) */
CREATE OR ALTER PROCEDURE PORTAL.sp_log_stats_table
  @execution_id UNIQUEIDENTIFIER,
  @table_name NVARCHAR(256),
  @operation_types NVARCHAR(64) = NULL,
  @rows_affected INT = NULL
AS
BEGIN
  INSERT INTO PORTAL.STATS_EXECUTION_TABLE_LOG(execution_id, table_name, operation_types, rows_affected)
  VALUES(@execution_id, @table_name, @operation_types, @rows_affected);
END
GO

/* TENANT CRUD (aligned to manifesto: tenant_name) */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
  @tenant_id NVARCHAR(50) = NULL,
  @tenant_name NVARCHAR(255),
  @plan_code NVARCHAR(50),
  @ext_attributes NVARCHAR(MAX) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT = 0, @status NVARCHAR(50) = 'OK', @err NVARCHAR(2000) = NULL;
  BEGIN TRY
    BEGIN TRAN;
    IF @tenant_id IS NULL OR @tenant_id = ''
    BEGIN
      DECLARE @seq BIGINT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
      SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
    END
    IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id=@tenant_id)
    BEGIN
      INSERT INTO PORTAL.TENANT(tenant_id, tenant_name, plan_code, status, ext_attributes, created_by)
      VALUES(@tenant_id, @tenant_name, @plan_code, 'ACTIVE', @ext_attributes, COALESCE(@created_by,'sp_insert_tenant'));
      SET @rows = 1;
    END
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_tenant', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_inserted;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_tenant
  @tenant_id NVARCHAR(50),
  @tenant_name NVARCHAR(255) = NULL,
  @plan_code NVARCHAR(50) = NULL,
  @status_in NVARCHAR(50) = NULL,
  @ext_attributes NVARCHAR(MAX) = NULL,
  @updated_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT=0, @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  BEGIN TRY
    BEGIN TRAN;
    UPDATE PORTAL.TENANT
      SET tenant_name = COALESCE(@tenant_name, tenant_name),
          plan_code = COALESCE(@plan_code, plan_code),
          status = COALESCE(@status_in, status),
          ext_attributes = COALESCE(@ext_attributes, ext_attributes),
          updated_at = SYSUTCDATETIME(),
          created_by = COALESCE(@updated_by,'sp_update_tenant')
    WHERE tenant_id=@tenant_id;
    SET @rows = @@ROWCOUNT;
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_tenant', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_updated;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_tenant
  @tenant_id NVARCHAR(50),
  @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT=0, @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  BEGIN TRY
    BEGIN TRAN;
    DELETE FROM PORTAL.TENANT WHERE tenant_id=@tenant_id;
    SET @rows = @@ROWCOUNT;
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_tenant', @tenant_id=@tenant_id, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_deleted;
END
GO

/* DEBUG combined register: tenant + user (used by API onboarding/users) */
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
  @tenant_id NVARCHAR(50) = NULL,
  @tenant_name NVARCHAR(255) = NULL,
  @user_email NVARCHAR(320) = NULL,
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @ext_attributes NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  DECLARE @rows_ins INT=0, @rows_user INT=0;
  DECLARE @user_id NVARCHAR(50) = NULL;
  BEGIN TRY
    BEGIN TRAN;
    IF (@tenant_id IS NULL OR @tenant_id='') AND @tenant_name IS NOT NULL
    BEGIN
      DECLARE @seqT BIGINT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
      SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@seqT AS NVARCHAR),3);
      IF NOT EXISTS(SELECT 1 FROM PORTAL.TENANT WHERE tenant_id=@tenant_id)
        INSERT INTO PORTAL.TENANT(tenant_id, tenant_name, plan_code, status, ext_attributes, created_by)
        VALUES(@tenant_id, @tenant_name, 'GOLD', 'ACTIVE', @ext_attributes, 'sp_debug_register_tenant_and_user');
      SET @rows_ins = 1;
    END
    /* create user if provided */
    IF @user_email IS NOT NULL
    BEGIN
      DECLARE @seqU BIGINT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
      SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@seqU AS NVARCHAR),3);
      IF NOT EXISTS(SELECT 1 FROM PORTAL.USERS WHERE tenant_id=@tenant_id AND email=@user_email)
      BEGIN
        INSERT INTO PORTAL.USERS(user_id, tenant_id, email, display_name, profile_id, is_active, status, ext_attributes, created_by)
        VALUES(@user_id, @tenant_id, @user_email, @display_name, @profile_id, 1, 'ACTIVE', @ext_attributes, 'sp_debug_register_tenant_and_user');
        SET @rows_user = 1;
      END
    END
    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH
  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_debug_register_tenant_and_user', @tenant_id=@tenant_id, @rows_inserted=@rows_user, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT,PORTAL.USERS', @operation_types='INSERT', @created_by='sp_debug_register_tenant_and_user';
  SELECT @status AS status, @tenant_id AS tenant_id, @user_id AS user_id, @err AS error_message, @rows_ins AS rows_tenant_inserted, @rows_user AS rows_user_inserted;
END
GO

/* Notifications stub used by API */
CREATE OR ALTER PROCEDURE PORTAL.sp_send_notification
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @category NVARCHAR(32),
  @channel NVARCHAR(16),
  @message NVARCHAR(MAX),
  @ext_attributes NVARCHAR(MAX) = NULL
AS
BEGIN
  INSERT INTO PORTAL.LOG_AUDIT(event_time, tenant_id, actor, origin, category, message, payload, status)
  VALUES(SYSUTCDATETIME(), @tenant_id, @user_id, 'api', @category, @message, @ext_attributes, 'SENT');
  SELECT 'OK' AS status;
END
GO

/* V7 — Seed minimum data (profiles, configuration examples) */

/* Profiles */
IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code='TENANT_ADMIN')
  INSERT INTO PORTAL.PROFILE_DOMAINS(profile_code, description, created_by) VALUES('TENANT_ADMIN','Amministratore tenant','seed');
IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code='VIEWER')
  INSERT INTO PORTAL.PROFILE_DOMAINS(profile_code, description, created_by) VALUES('VIEWER','Utente solo lettura','seed');

/* Global configuration examples (tenant_id='*' for global) */
IF NOT EXISTS (SELECT 1 FROM PORTAL.CONFIGURATION WHERE tenant_id='*' AND config_key='MAX_FILE_SIZE_MB')
  INSERT INTO PORTAL.CONFIGURATION(tenant_id, section, config_key, config_value, enabled, created_by)
  VALUES('*','upload','MAX_FILE_SIZE_MB','50',1,'seed');

/* V8 — Extended properties (descriptions/PII flags) */

/* Example: USERS table */
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Anagrafica utenti multi-tenant',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='USERS';

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Codice utente NDG (CDI...)',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='USERS', @level2type=N'COLUMN',@level2name='user_id';

EXEC sys.sp_addextendedproperty @name=N'PII', @value=N'true',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='USERS', @level2type=N'COLUMN',@level2name='email';

/* Example: TENANT table */
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Anagrafica clienti/tenant',
  @level0type=N'SCHEMA',@level0name='PORTAL', @level1type=N'TABLE',@level1name='TENANT';

/* V9 — SP CRUD for USERS, CONFIGURATION, PROFILE_DOMAINS (ACL) */
GO

/* USERS */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
  @user_id NVARCHAR(50) = NULL,
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320),
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    BEGIN TRAN;
    IF @user_id IS NULL OR @user_id=''
    BEGIN DECLARE @seq BIGINT=NEXT VALUE FOR PORTAL.SEQ_USER_ID; SET @user_id='CDI'+RIGHT('000000000'+CAST(@seq AS NVARCHAR),9); END
    IF NOT EXISTS(SELECT 1 FROM PORTAL.USERS WHERE tenant_id=@tenant_id AND email=@email)
    BEGIN
      INSERT INTO PORTAL.USERS(user_id, tenant_id, email, display_name, profile_id, is_active, status, created_by)
      VALUES(@user_id, @tenant_id, @email, @display_name, @profile_id, 1, 'ACTIVE', COALESCE(@created_by,'sp_insert_user'));
      SET @rows=1;
    END
    COMMIT;
  END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_user', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_inserted;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_user
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @email NVARCHAR(320) = NULL,
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @is_active BIT = NULL,
  @updated_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    BEGIN TRAN;
    UPDATE PORTAL.USERS SET
      email=COALESCE(@email,email), display_name=COALESCE(@display_name,display_name), profile_id=COALESCE(@profile_id,profile_id), is_active=COALESCE(@is_active,is_active), updated_at=SYSUTCDATETIME(), created_by=COALESCE(@updated_by,'sp_update_user')
    WHERE tenant_id=@tenant_id AND user_id=@user_id;
    SET @rows=@@ROWCOUNT; COMMIT;
  END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_user', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_updated;
END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_user
  @tenant_id NVARCHAR(50),
  @user_id NVARCHAR(50),
  @deleted_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY
    BEGIN TRAN;
    UPDATE PORTAL.USERS SET is_active=0, status='INACTIVE', updated_at=SYSUTCDATETIME(), created_by=COALESCE(@deleted_by,'sp_delete_user')
    WHERE tenant_id=@tenant_id AND user_id=@user_id;
    SET @rows=@@ROWCOUNT; COMMIT;
  END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_user', @tenant_id=@tenant_id, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_deleted;
END
GO

/* CONFIGURATION */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_configuration
  @tenant_id NVARCHAR(50), @section NVARCHAR(64)=NULL, @config_key NVARCHAR(100), @config_value NVARCHAR(MAX), @enabled BIT=1, @created_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN;
    IF NOT EXISTS(SELECT 1 FROM PORTAL.CONFIGURATION WHERE tenant_id=@tenant_id AND ISNULL(section,'')=ISNULL(@section,'') AND config_key=@config_key)
    BEGIN INSERT INTO PORTAL.CONFIGURATION(tenant_id, section, config_key, config_value, enabled, created_by) VALUES(@tenant_id,@section,@config_key,@config_value,@enabled,COALESCE(@created_by,'sp_insert_configuration')); SET @rows=1; END
    COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_configuration', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.CONFIGURATION', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_configuration'); SELECT @status AS status, @rows AS rows_inserted; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_configuration
  @tenant_id NVARCHAR(50), @section NVARCHAR(64)=NULL, @config_key NVARCHAR(100), @config_value NVARCHAR(MAX)=NULL, @enabled BIT=NULL, @updated_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN;
    UPDATE PORTAL.CONFIGURATION SET config_value=COALESCE(@config_value,config_value), enabled=COALESCE(@enabled,enabled), updated_at=SYSUTCDATETIME(), created_by=COALESCE(@updated_by,'sp_update_configuration')
    WHERE tenant_id=@tenant_id AND ISNULL(section,'')=ISNULL(@section,'') AND config_key=@config_key; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_configuration', @tenant_id=@tenant_id, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.CONFIGURATION', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_configuration'); SELECT @status AS status, @rows AS rows_updated; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_configuration
  @tenant_id NVARCHAR(50), @section NVARCHAR(64)=NULL, @config_key NVARCHAR(100), @deleted_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; DELETE FROM PORTAL.CONFIGURATION WHERE tenant_id=@tenant_id AND ISNULL(section,'')=ISNULL(@section,'') AND config_key=@config_key; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_configuration', @tenant_id=@tenant_id, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.CONFIGURATION', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_configuration'); SELECT @status AS status, @rows AS rows_deleted; END
GO

/* ACL: PROFILE_DOMAINS */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_profile_domain
  @profile_code NVARCHAR(50), @description NVARCHAR(255)=NULL, @created_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; IF NOT EXISTS(SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code=@profile_code) BEGIN INSERT INTO PORTAL.PROFILE_DOMAINS(profile_code,description,created_by) VALUES(@profile_code,@description,COALESCE(@created_by,'sp_insert_profile_domain')); SET @rows=1; END COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_profile_domain', @tenant_id=NULL, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.PROFILE_DOMAINS', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_profile_domain'); SELECT @status AS status, @rows AS rows_inserted; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_update_profile_domain
  @profile_code NVARCHAR(50), @description NVARCHAR(255)=NULL, @updated_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; UPDATE PORTAL.PROFILE_DOMAINS SET description=COALESCE(@description,description), updated_at=SYSUTCDATETIME(), created_by=COALESCE(@updated_by,'sp_update_profile_domain') WHERE profile_code=@profile_code; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_update_profile_domain', @tenant_id=NULL, @rows_updated=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.PROFILE_DOMAINS', @operation_types='UPDATE', @created_by=COALESCE(@updated_by,'sp_update_profile_domain'); SELECT @status AS status, @rows AS rows_updated; END
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_delete_profile_domain
  @profile_code NVARCHAR(50), @deleted_by NVARCHAR(255)=NULL
AS BEGIN
  SET NOCOUNT ON; DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  BEGIN TRY BEGIN TRAN; DELETE FROM PORTAL.PROFILE_DOMAINS WHERE profile_code=@profile_code; SET @rows=@@ROWCOUNT; COMMIT; END TRY BEGIN CATCH SET @status='ERROR'; SET @err=ERROR_MESSAGE(); IF @@TRANCOUNT>0 ROLLBACK; END CATCH
  DECLARE @end DATETIME2=SYSUTCDATETIME(); EXEC PORTAL.sp_log_stats_execution @proc_name='sp_delete_profile_domain', @tenant_id=NULL, @rows_deleted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.PROFILE_DOMAINS', @operation_types='DELETE', @created_by=COALESCE(@deleted_by,'sp_delete_profile_domain'); SELECT @status AS status, @rows AS rows_deleted; END
GO

/* V10 — RLS policy on PORTAL.CONFIGURATION (disabled by default) */
GO

IF NOT EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'RLS_TENANT_POLICY_CONFIGURATION')
BEGIN
  CREATE SECURITY POLICY PORTAL.RLS_TENANT_POLICY_CONFIGURATION
  ADD FILTER PREDICATE PORTAL.fn_rls_tenant_filter(tenant_id) ON PORTAL.CONFIGURATION
  WITH (STATE = OFF);
END;
GO

/* To enable: ALTER SECURITY POLICY PORTAL.RLS_TENANT_POLICY_CONFIGURATION WITH (STATE=ON); */

/* V11 - Users read SP (list by tenant) */
GO

CREATE OR ALTER PROCEDURE PORTAL.sp_list_users_by_tenant
  @tenant_id NVARCHAR(50),
  @include_inactive BIT = 0,
  @requested_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;

  BEGIN TRY
    SELECT user_id, tenant_id, email, display_name, profile_id, is_active, status, ext_attributes, created_at, updated_at
    FROM PORTAL.USERS
    WHERE tenant_id=@tenant_id AND (@include_inactive=1 OR is_active=1);
    SET @rows=@@ROWCOUNT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_list_users_by_tenant',
    @tenant_id=@tenant_id,
    @rows_updated=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.USERS',
    @operation_types='SELECT',
    @created_by=COALESCE(@requested_by,'sp_list_users_by_tenant');
END
GO
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
/* V13 - Agent Chat persistence (LOG_AUDIT-backed)
   - Stores chat messages and conversation tombstones in PORTAL.LOG_AUDIT
   - Provides SPs for list/get/delete without introducing new tables
*/
GO

/* Agent Chat: append message event */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_log_message
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),            -- user id (or service)
  @agent_id NVARCHAR(128),
  @conversation_id NVARCHAR(128),
  @role NVARCHAR(16),              -- user|agent|system
  @content NVARCHAR(MAX),
  @metadata_json NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL,
          @rows INT = 0;

  BEGIN TRY
    DECLARE @payload NVARCHAR(MAX) =
      (SELECT
        @conversation_id AS conversationId,
        @agent_id AS agentId,
        @role AS role,
        @content AS content,
        TRY_CONVERT(NVARCHAR(MAX), @metadata_json) AS metadataJson
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    INSERT INTO PORTAL.LOG_AUDIT(event_time, tenant_id, actor, origin, category, message, payload, status)
    VALUES(SYSUTCDATETIME(), @tenant_id, @actor, 'api', 'agent_chat.message', @content, @payload, @role);

    SET @rows = 1;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_log_message',
    @tenant_id=@tenant_id,
    @rows_inserted=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='INSERT',
    @created_by=COALESCE(@actor,'sp_agent_chat_log_message');

  IF @status <> 'OK'
  BEGIN
    THROW 51000, @err, 1;
  END
END
GO

/* Agent Chat: purge old logs (retention) */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_purge_logs
  @tenant_id NVARCHAR(50) = NULL,
  @older_than_days INT = 90
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL,
          @rows INT = 0;

  BEGIN TRY
    DELETE FROM PORTAL.LOG_AUDIT
    WHERE category LIKE 'agent_chat.%'
      AND event_time < DATEADD(DAY, -@older_than_days, SYSUTCDATETIME())
      AND (@tenant_id IS NULL OR tenant_id = @tenant_id);

    SET @rows = @@ROWCOUNT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_purge_logs',
    @tenant_id=@tenant_id,
    @rows_deleted=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='DELETE',
    @created_by='sp_agent_chat_purge_logs';

  IF @status <> 'OK'
  BEGIN
    THROW 51004, @err, 1;
  END
END
GO

/* Agent Chat: list conversations for user + agent */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_list_conversations
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),
  @agent_id NVARCHAR(128),
  @limit INT = 20,
  @offset INT = 0
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL;

  BEGIN TRY
    ;WITH Deleted AS (
      SELECT DISTINCT JSON_VALUE(payload, '$.conversationId') AS conversationId
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.conversation_deleted'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId') IS NOT NULL
    ),
    Msg AS (
      SELECT
        JSON_VALUE(payload, '$.conversationId') AS conversationId,
        MAX(event_time) AS lastEventTime
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.message'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId') IS NOT NULL
      GROUP BY JSON_VALUE(payload, '$.conversationId')
    ),
    MsgFiltered AS (
      SELECT m.*
      FROM Msg m
      LEFT JOIN Deleted d ON d.conversationId = m.conversationId
      WHERE d.conversationId IS NULL
    ),
    Ranked AS (
      SELECT
        mf.conversationId,
        mf.lastEventTime,
        ROW_NUMBER() OVER (ORDER BY mf.lastEventTime DESC) AS rn
      FROM MsgFiltered mf
    )
    SELECT
      r.conversationId,
      r.lastEventTime,
      la.message AS lastMessage
    FROM Ranked r
    OUTER APPLY (
      SELECT TOP 1 message
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.message'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId')=r.conversationId
      ORDER BY event_time DESC, id DESC
    ) la
    WHERE r.rn > @offset AND r.rn <= (@offset + @limit)
    ORDER BY r.lastEventTime DESC;

    /* total */
    SELECT COUNT(1) AS total
    FROM MsgFiltered;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_list_conversations',
    @tenant_id=@tenant_id,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='SELECT',
    @created_by=COALESCE(@actor,'sp_agent_chat_list_conversations');

  IF @status <> 'OK'
  BEGIN
    THROW 51001, @err, 1;
  END
END
GO

/* Agent Chat: get full conversation messages */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_get_conversation
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),
  @agent_id NVARCHAR(128),
  @conversation_id NVARCHAR(128)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL;

  BEGIN TRY
    IF EXISTS (
      SELECT 1
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.conversation_deleted'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId')=@conversation_id
    )
    BEGIN
      SELECT CAST(1 AS BIT) AS deleted;
      RETURN;
    END

    SELECT
      event_time,
      JSON_VALUE(payload, '$.role') AS role,
      message AS content,
      payload AS payload_json
    FROM PORTAL.LOG_AUDIT
    WHERE tenant_id=@tenant_id
      AND actor=@actor
      AND category='agent_chat.message'
      AND JSON_VALUE(payload, '$.agentId')=@agent_id
      AND JSON_VALUE(payload, '$.conversationId')=@conversation_id
    ORDER BY event_time ASC, id ASC;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_get_conversation',
    @tenant_id=@tenant_id,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='SELECT',
    @created_by=COALESCE(@actor,'sp_agent_chat_get_conversation');

  IF @status <> 'OK'
  BEGIN
    THROW 51002, @err, 1;
  END
END
GO

/* Agent Chat: soft delete conversation (tombstone event) */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_delete_conversation
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),
  @agent_id NVARCHAR(128),
  @conversation_id NVARCHAR(128)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL,
          @rows INT = 0;

  BEGIN TRY
    DECLARE @payload NVARCHAR(MAX) =
      (SELECT
        @conversation_id AS conversationId,
        @agent_id AS agentId
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    INSERT INTO PORTAL.LOG_AUDIT(event_time, tenant_id, actor, origin, category, message, payload, status)
    VALUES(SYSUTCDATETIME(), @tenant_id, @actor, 'api', 'agent_chat.conversation_deleted', 'Conversation deleted', @payload, 'DELETED');

    SET @rows = 1;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_delete_conversation',
    @tenant_id=@tenant_id,
    @rows_inserted=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='INSERT',
    @created_by=COALESCE(@actor,'sp_agent_chat_delete_conversation');

  IF @status <> 'OK'
  BEGIN
    THROW 51003, @err, 1;
  END
END
GO
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
/* V14 — Refactor Onboarding to use nested-safe SPs (DRY + Atomic) */
GO

/* 1. Make sp_insert_tenant transaction-aware (Nested Transaction Pattern) */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_tenant
  @tenant_id NVARCHAR(50) = NULL,
  @tenant_name NVARCHAR(255),
  @plan_code NVARCHAR(50),
  @ext_attributes NVARCHAR(MAX) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @rows INT = 0, @status NVARCHAR(50) = 'OK', @err NVARCHAR(2000) = NULL;
  
  /* Nested Transaction Logic */
  DECLARE @hasOuterTran BIT = 0;
  IF @@TRANCOUNT > 0 SET @hasOuterTran = 1;

  BEGIN TRY
    IF @hasOuterTran = 0 BEGIN TRAN; END
    
    IF @tenant_id IS NULL OR @tenant_id = ''
    BEGIN
      DECLARE @seq BIGINT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
      SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
    END
    
    IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id=@tenant_id)
    BEGIN
      INSERT INTO PORTAL.TENANT(tenant_id, tenant_name, plan_code, status, ext_attributes, created_by)
      VALUES(@tenant_id, @tenant_name, @plan_code, 'ACTIVE', @ext_attributes, COALESCE(@created_by,'sp_insert_tenant'));
      SET @rows = 1;
    END

    IF @hasOuterTran = 0 COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE();
    /* Only rollback if we started the transaction, OR if the error is severe enough to doom the transaction.
       Standard pattern: If outer exists, just re-throw or return error status. 
       However, simplified approach: If local, Rollback. If outer, do nothing (caller rolls back) OR commit impossible.
    */
    IF @hasOuterTran = 0 AND @@TRANCOUNT > 0 ROLLBACK;
    /* If outer exists, we do NOT rollback here, we return Error and let caller rollback. */
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_tenant', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_tenant');
  SELECT @status AS status, @tenant_id AS tenant_id, @err AS error_message, @rows AS rows_inserted;
END
GO

/* 2. Make sp_insert_user transaction-aware */
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_user
  @user_id NVARCHAR(50) = NULL,
  @tenant_id NVARCHAR(50),
  @email NVARCHAR(320),
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @created_by NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON; 
  DECLARE @start DATETIME2=SYSUTCDATETIME(), @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL, @rows INT=0;
  
  DECLARE @hasOuterTran BIT = 0;
  IF @@TRANCOUNT > 0 SET @hasOuterTran = 1;

  BEGIN TRY
    IF @hasOuterTran = 0 BEGIN TRAN; END

    IF @user_id IS NULL OR @user_id=''
    BEGIN DECLARE @seq BIGINT=NEXT VALUE FOR PORTAL.SEQ_USER_ID; SET @user_id='CDI'+RIGHT('000000000'+CAST(@seq AS NVARCHAR),9); END
    
    IF NOT EXISTS(SELECT 1 FROM PORTAL.USERS WHERE tenant_id=@tenant_id AND email=@email)
    BEGIN
      INSERT INTO PORTAL.USERS(user_id, tenant_id, email, display_name, profile_id, is_active, status, created_by)
      VALUES(@user_id, @tenant_id, @email, @display_name, @profile_id, 1, 'ACTIVE', COALESCE(@created_by,'sp_insert_user'));
      SET @rows=1;
    END
    
    IF @hasOuterTran = 0 COMMIT;
  END TRY 
  BEGIN CATCH 
    SET @status='ERROR'; SET @err=ERROR_MESSAGE(); 
    IF @hasOuterTran = 0 AND @@TRANCOUNT>0 ROLLBACK; 
  END CATCH

  DECLARE @end DATETIME2=SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_insert_user', @tenant_id=@tenant_id, @rows_inserted=@rows, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.USERS', @operation_types='INSERT', @created_by=COALESCE(@created_by,'sp_insert_user');
  SELECT @status AS status, @user_id AS user_id, @err AS error_message, @rows AS rows_inserted;
END
GO

/* 3. Create formal sp_register_tenant_and_user (Production) calling atomic SPs */
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
  @tenant_id NVARCHAR(50) = NULL,
  @tenant_name NVARCHAR(255) = NULL,
  @user_email NVARCHAR(320) = NULL,
  @display_name NVARCHAR(100) = NULL,
  @profile_id NVARCHAR(64) = NULL,
  @ext_attributes NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @start DATETIME2 = SYSUTCDATETIME();
  DECLARE @status NVARCHAR(50)='OK', @err NVARCHAR(2000)=NULL;
  DECLARE @rows_ins INT=0, @rows_user INT=0;
  DECLARE @user_id NVARCHAR(50) = NULL;
  
  /* Output table to capture results from nested calls */
  DECLARE @ResTenant TABLE (status NVARCHAR(50), tenant_id NVARCHAR(50), error_message NVARCHAR(2000), rows_inserted INT);
  DECLARE @ResUser TABLE (status NVARCHAR(50), user_id NVARCHAR(50), error_message NVARCHAR(2000), rows_inserted INT);

  BEGIN TRY
    BEGIN TRAN; /* Outer Transaction */

    /* 3.1 Insert Tenant */
    INSERT INTO @ResTenant EXEC PORTAL.sp_insert_tenant
      @tenant_id = @tenant_id,
      @tenant_name = @tenant_name,
      @plan_code = 'GOLD', /* Default plan */
      @ext_attributes = @ext_attributes,
      @created_by = 'sp_register_tenant_and_user';
      
    /* Check Tenant Result */
    DECLARE @tStatus NVARCHAR(50), @tErr NVARCHAR(2000), @tId NVARCHAR(50);
    SELECT TOP 1 @tStatus=status, @tErr=error_message, @tId=tenant_id, @rows_ins=rows_inserted FROM @ResTenant;
    
    IF @tStatus <> 'OK' THROW 50000, @tErr, 1;
    SET @tenant_id = @tId; /* In case it was auto-generated */

    /* 3.2 Insert User (optional but typical in registration) */
    IF @user_email IS NOT NULL
    BEGIN
      INSERT INTO @ResUser EXEC PORTAL.sp_insert_user
        @tenant_id = @tenant_id,
        @email = @user_email,
        @display_name = @display_name,
        @profile_id = @profile_id,
        @created_by = 'sp_register_tenant_and_user';
        
      DECLARE @uStatus NVARCHAR(50), @uErr NVARCHAR(2000), @uId NVARCHAR(50);
      SELECT TOP 1 @uStatus=status, @uErr=error_message, @uId=user_id, @rows_user=rows_inserted FROM @ResUser;

      IF @uStatus <> 'OK' THROW 50001, @uErr, 1;
      SET @user_id = @uId;
    END

    COMMIT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR'; SET @err = ERROR_MESSAGE(); 
    IF @@TRANCOUNT>0 ROLLBACK;
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution @proc_name='sp_register_tenant_and_user', @tenant_id=@tenant_id, @rows_inserted=@rows_user, @status=@status, @error_message=@err, @start_time=@start, @end_time=@end, @affected_tables='PORTAL.TENANT,PORTAL.USERS', @operation_types='INSERT', @created_by='sp_register_tenant_and_user';
  
  SELECT @status AS status, @tenant_id AS tenant_id, @user_id AS user_id, @err AS error_message, @rows_ins AS rows_tenant_inserted, @rows_user AS rows_user_inserted;
END
GO

/* 4. Drop legacy debug SP */
DROP PROCEDURE IF EXISTS PORTAL.sp_debug_register_tenant_and_user;
GO
-- cleanup_old_executions.sql
-- Retention policy for Agent Management Console
-- Run monthly to keep database size under control

CREATE PROCEDURE AGENT_MGMT.sp_cleanup_old_executions
    @RetentionDays INT = 90,
    @DryRun BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@RetentionDays, GETDATE());
    DECLARE @MetricsToDelete INT;
    DECLARE @ExecutionsToDelete INT;
    
    -- Count what would be deleted
    SELECT @MetricsToDelete = COUNT(*)
    FROM AGENT_MGMT.agent_metrics m
    INNER JOIN AGENT_MGMT.agent_executions e ON m.execution_id = e.execution_id
    WHERE e.completed_at < @CutoffDate;
    
    SELECT @ExecutionsToDelete = COUNT(*)
    FROM AGENT_MGMT.agent_executions
    WHERE completed_at < @CutoffDate;
    
    IF @DryRun = 1
    BEGIN
        -- Dry run: just report
        SELECT 
            @RetentionDays AS retention_days,
            @CutoffDate AS cutoff_date,
            @ExecutionsToDelete AS executions_to_delete,
            @MetricsToDelete AS metrics_to_delete,
            'DRY RUN - No data deleted' AS status;
        RETURN;
    END
    
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Delete old metrics first (FK constraint)
        DELETE FROM AGENT_MGMT.agent_metrics
        WHERE execution_id IN (
            SELECT execution_id 
            FROM AGENT_MGMT.agent_executions
            WHERE completed_at < @CutoffDate
        );
        
        DECLARE @MetricsDeleted INT = @@ROWCOUNT;
        
        -- Delete old executions
        DELETE FROM AGENT_MGMT.agent_executions
        WHERE completed_at < @CutoffDate;
        
        DECLARE @ExecutionsDeleted INT = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Return summary
        SELECT 
            @RetentionDays AS retention_days,
            @CutoffDate AS cutoff_date,
            @ExecutionsDeleted AS executions_deleted,
            @MetricsDeleted AS metrics_deleted,
            'SUCCESS' AS status;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Test with dry run
EXEC AGENT_MGMT.sp_cleanup_old_executions @RetentionDays = 90, @DryRun = 1;

-- Actual cleanup (run monthly)
-- EXEC AGENT_MGMT.sp_cleanup_old_executions @RetentionDays = 90, @DryRun = 0;
-- V15__agent_management_console.sql
-- Agent Management Console - Database Schema
-- Provides metadata, monitoring, and control for all agents

-- =====================================================
-- SCHEMA: AGENT_MGMT
-- =====================================================
CREATE SCHEMA IF NOT EXISTS AGENT_MGMT;
GO

-- =====================================================
-- TABLE: agent_registry
-- Master registry of all agents with metadata
-- =====================================================
CREATE TABLE AGENT_MGMT.agent_registry (
    agent_id NVARCHAR(100) PRIMARY KEY,
    agent_name NVARCHAR(255) NOT NULL,
    classification NVARCHAR(50) NOT NULL, -- brain, specialist, worker
    role NVARCHAR(100) NOT NULL,
    version NVARCHAR(20) NOT NULL,
    owner NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX),
    
    -- Control flags
    is_enabled BIT NOT NULL DEFAULT 1,
    is_active BIT NOT NULL DEFAULT 0, -- Currently running
    
    -- Configuration
    manifest_path NVARCHAR(500),
    script_path NVARCHAR(500),
    llm_model NVARCHAR(100),
    llm_temperature DECIMAL(3,2),
    context_limit_tokens INT,
    
    -- Metadata
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    created_by NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    updated_by NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    
    -- Audit
    last_sync_at DATETIME2, -- Last time manifest was synced
    manifest_hash NVARCHAR(64) -- SHA256 of manifest for change detection
);

CREATE INDEX IX_agent_registry_classification ON AGENT_MGMT.agent_registry(classification);
CREATE INDEX IX_agent_registry_enabled ON AGENT_MGMT.agent_registry(is_enabled);
CREATE INDEX IX_agent_registry_active ON AGENT_MGMT.agent_registry(is_active);

-- =====================================================
-- TABLE: agent_executions
-- Track individual agent execution instances
-- =====================================================
CREATE TABLE AGENT_MGMT.agent_executions (
    execution_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_id NVARCHAR(100) NOT NULL,
    
    -- Execution context
    action_name NVARCHAR(200), -- e.g., 'gedi:ooda.loop'
    intent_id NVARCHAR(100), -- Reference to intent if applicable
    triggered_by NVARCHAR(100) NOT NULL, -- user, system, webhook, schedule
    
    -- Status tracking (Kanban-style)
    status NVARCHAR(20) NOT NULL DEFAULT 'TODO', -- TODO, ONGOING, DONE, FAILED, CANCELLED
    status_message NVARCHAR(MAX),
    
    -- Timing
    queued_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    started_at DATETIME2,
    completed_at DATETIME2,
    duration_ms INT, -- Calculated: completed_at - started_at
    
    -- Metrics
    tokens_consumed INT DEFAULT 0,
    tokens_prompt INT DEFAULT 0,
    tokens_completion INT DEFAULT 0,
    api_calls_count INT DEFAULT 0,
    
    -- Cost tracking
    estimated_cost_usd DECIMAL(10,6) DEFAULT 0,
    
    -- Results
    success BIT,
    error_message NVARCHAR(MAX),
    output_summary NVARCHAR(MAX),
    output_path NVARCHAR(500), -- Path to detailed output file
    
    -- Metadata
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_agent_executions_agent FOREIGN KEY (agent_id) 
        REFERENCES AGENT_MGMT.agent_registry(agent_id)
);

CREATE INDEX IX_agent_executions_agent_id ON AGENT_MGMT.agent_executions(agent_id);
CREATE INDEX IX_agent_executions_status ON AGENT_MGMT.agent_executions(status);
CREATE INDEX IX_agent_executions_queued_at ON AGENT_MGMT.agent_executions(queued_at DESC);
CREATE INDEX IX_agent_executions_started_at ON AGENT_MGMT.agent_executions(started_at DESC);

-- =====================================================
-- TABLE: agent_metrics
-- Time-series metrics for agent performance
-- =====================================================
CREATE TABLE AGENT_MGMT.agent_metrics (
    metric_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_id NVARCHAR(100) NOT NULL,
    execution_id BIGINT,
    
    -- Metric details
    metric_timestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    metric_type NVARCHAR(50) NOT NULL, -- token_usage, execution_time, error_rate, etc.
    metric_value DECIMAL(18,6) NOT NULL,
    metric_unit NVARCHAR(20), -- tokens, ms, percent, count
    
    -- Dimensions
    dimension_1 NVARCHAR(100), -- e.g., model_name
    dimension_2 NVARCHAR(100), -- e.g., action_type
    
    -- Metadata
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_agent_metrics_agent FOREIGN KEY (agent_id) 
        REFERENCES AGENT_MGMT.agent_registry(agent_id),
    CONSTRAINT FK_agent_metrics_execution FOREIGN KEY (execution_id) 
        REFERENCES AGENT_MGMT.agent_executions(execution_id)
);

CREATE INDEX IX_agent_metrics_agent_timestamp ON AGENT_MGMT.agent_metrics(agent_id, metric_timestamp DESC);
CREATE INDEX IX_agent_metrics_type ON AGENT_MGMT.agent_metrics(metric_type);

-- =====================================================
-- TABLE: agent_capabilities
-- Track agent capabilities and their status
-- =====================================================
CREATE TABLE AGENT_MGMT.agent_capabilities (
    capability_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_id NVARCHAR(100) NOT NULL,
    capability_name NVARCHAR(200) NOT NULL,
    capability_description NVARCHAR(MAX),
    is_enabled BIT NOT NULL DEFAULT 1,
    
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_agent_capabilities_agent FOREIGN KEY (agent_id) 
        REFERENCES AGENT_MGMT.agent_registry(agent_id),
    CONSTRAINT UQ_agent_capability UNIQUE (agent_id, capability_name)
);

-- =====================================================
-- TABLE: agent_triggers
-- Track agent triggers and their configuration
-- =====================================================
CREATE TABLE AGENT_MGMT.agent_triggers (
    trigger_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    agent_id NVARCHAR(100) NOT NULL,
    trigger_name NVARCHAR(200) NOT NULL,
    trigger_description NVARCHAR(MAX),
    is_enabled BIT NOT NULL DEFAULT 1,
    
    -- Trigger configuration
    trigger_type NVARCHAR(50), -- event, schedule, webhook, manual
    trigger_config NVARCHAR(MAX), -- JSON configuration
    
    -- Statistics
    last_triggered_at DATETIME2,
    trigger_count INT DEFAULT 0,
    
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_agent_triggers_agent FOREIGN KEY (agent_id) 
        REFERENCES AGENT_MGMT.agent_registry(agent_id),
    CONSTRAINT UQ_agent_trigger UNIQUE (agent_id, trigger_name)
);

-- =====================================================
-- VIEW: vw_agent_dashboard
-- Real-time dashboard view for management console
-- =====================================================
CREATE VIEW AGENT_MGMT.vw_agent_dashboard AS
SELECT 
    ar.agent_id,
    ar.agent_name,
    ar.classification,
    ar.role,
    ar.is_enabled,
    ar.is_active,
    ar.llm_model,
    
    -- Current execution
    ae_current.execution_id AS current_execution_id,
    ae_current.status AS current_status,
    ae_current.started_at AS current_started_at,
    DATEDIFF(SECOND, ae_current.started_at, GETDATE()) AS current_duration_seconds,
    
    -- Statistics (last 24h)
    stats.total_executions_24h,
    stats.successful_executions_24h,
    stats.failed_executions_24h,
    stats.avg_duration_ms_24h,
    stats.total_tokens_24h,
    stats.total_cost_24h,
    
    -- Last execution
    ae_last.completed_at AS last_execution_at,
    ae_last.status AS last_execution_status,
    ae_last.duration_ms AS last_execution_duration_ms,
    
    ar.updated_at
FROM AGENT_MGMT.agent_registry ar
LEFT JOIN AGENT_MGMT.agent_executions ae_current ON ar.agent_id = ae_current.agent_id 
    AND ae_current.status = 'ONGOING'
LEFT JOIN (
    SELECT 
        agent_id,
        COUNT(*) AS total_executions_24h,
        SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) AS successful_executions_24h,
        SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS failed_executions_24h,
        AVG(duration_ms) AS avg_duration_ms_24h,
        SUM(tokens_consumed) AS total_tokens_24h,
        SUM(estimated_cost_usd) AS total_cost_24h
    FROM AGENT_MGMT.agent_executions
    WHERE queued_at >= DATEADD(HOUR, -24, GETDATE())
    GROUP BY agent_id
) stats ON ar.agent_id = stats.agent_id
OUTER APPLY (
    SELECT TOP 1 *
    FROM AGENT_MGMT.agent_executions ae
    WHERE ae.agent_id = ar.agent_id
        AND ae.status IN ('DONE', 'FAILED')
    ORDER BY ae.completed_at DESC
) ae_last;

GO

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- SP: Sync agent from manifest
CREATE PROCEDURE AGENT_MGMT.sp_sync_agent_from_manifest
    @AgentId NVARCHAR(100),
    @ManifestJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AgentName NVARCHAR(255);
    DECLARE @Classification NVARCHAR(50);
    DECLARE @Role NVARCHAR(100);
    DECLARE @Version NVARCHAR(20);
    DECLARE @Owner NVARCHAR(100);
    DECLARE @Description NVARCHAR(MAX);
    DECLARE @LlmModel NVARCHAR(100);
    DECLARE @LlmTemperature DECIMAL(3,2);
    DECLARE @ContextLimitTokens INT;
    DECLARE @ManifestHash NVARCHAR(64);
    
    -- Parse JSON (simplified - in real implementation use JSON_VALUE)
    SET @AgentName = JSON_VALUE(@ManifestJson, '$.name');
    SET @Classification = JSON_VALUE(@ManifestJson, '$.classification');
    SET @Role = JSON_VALUE(@ManifestJson, '$.role');
    SET @Version = JSON_VALUE(@ManifestJson, '$.version');
    SET @Owner = JSON_VALUE(@ManifestJson, '$.owner');
    SET @Description = JSON_VALUE(@ManifestJson, '$.description');
    SET @LlmModel = JSON_VALUE(@ManifestJson, '$.llm_config.model');
    SET @LlmTemperature = CAST(JSON_VALUE(@ManifestJson, '$.llm_config.temperature') AS DECIMAL(3,2));
    SET @ContextLimitTokens = CAST(JSON_VALUE(@ManifestJson, '$.context_config.context_limit_tokens') AS INT);
    SET @ManifestHash = CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', @ManifestJson), 2);
    
    MERGE AGENT_MGMT.agent_registry AS target
    USING (SELECT @AgentId AS agent_id) AS source
    ON target.agent_id = source.agent_id
    WHEN MATCHED THEN
        UPDATE SET
            agent_name = @AgentName,
            classification = @Classification,
            role = @Role,
            version = @Version,
            owner = @Owner,
            description = @Description,
            llm_model = @LlmModel,
            llm_temperature = @LlmTemperature,
            context_limit_tokens = @ContextLimitTokens,
            manifest_hash = @ManifestHash,
            last_sync_at = GETDATE(),
            updated_at = GETDATE(),
            updated_by = SYSTEM_USER
    WHEN NOT MATCHED THEN
        INSERT (agent_id, agent_name, classification, role, version, owner, description,
                llm_model, llm_temperature, context_limit_tokens, manifest_hash, last_sync_at)
        VALUES (@AgentId, @AgentName, @Classification, @Role, @Version, @Owner, @Description,
                @LlmModel, @LlmTemperature, @ContextLimitTokens, @ManifestHash, GETDATE());
END;
GO

-- SP: Toggle agent enabled status
CREATE PROCEDURE AGENT_MGMT.sp_toggle_agent_status
    @AgentId NVARCHAR(100),
    @IsEnabled BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE AGENT_MGMT.agent_registry
    SET is_enabled = @IsEnabled,
        updated_at = GETDATE(),
        updated_by = SYSTEM_USER
    WHERE agent_id = @AgentId;
    
    SELECT @@ROWCOUNT AS rows_affected;
END;
GO

-- SP: Start agent execution
CREATE PROCEDURE AGENT_MGMT.sp_start_execution
    @AgentId NVARCHAR(100),
    @ActionName NVARCHAR(200) = NULL,
    @IntentId NVARCHAR(100) = NULL,
    @TriggeredBy NVARCHAR(100) = 'system',
    @ExecutionId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if agent is enabled
    IF NOT EXISTS (SELECT 1 FROM AGENT_MGMT.agent_registry WHERE agent_id = @AgentId AND is_enabled = 1)
    BEGIN
        RAISERROR('Agent is not enabled', 16, 1);
        RETURN;
    END
    
    -- Create execution record
    INSERT INTO AGENT_MGMT.agent_executions (agent_id, action_name, intent_id, triggered_by, status)
    VALUES (@AgentId, @ActionName, @IntentId, @TriggeredBy, 'TODO');
    
    SET @ExecutionId = SCOPE_IDENTITY();
    
    -- Update agent as active
    UPDATE AGENT_MGMT.agent_registry
    SET is_active = 1,
        updated_at = GETDATE()
    WHERE agent_id = @AgentId;
END;
GO

-- SP: Update execution status
CREATE PROCEDURE AGENT_MGMT.sp_update_execution_status
    @ExecutionId BIGINT,
    @Status NVARCHAR(20),
    @StatusMessage NVARCHAR(MAX) = NULL,
    @TokensConsumed INT = NULL,
    @TokensPrompt INT = NULL,
    @TokensCompletion INT = NULL,
    @ApiCallsCount INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AgentId NVARCHAR(100);
    DECLARE @StartedAt DATETIME2;
    DECLARE @CompletedAt DATETIME2;
    DECLARE @DurationMs INT;
    
    -- Get current execution info
    SELECT @AgentId = agent_id, @StartedAt = started_at
    FROM AGENT_MGMT.agent_executions
    WHERE execution_id = @ExecutionId;
    
    -- Set timestamps based on status
    IF @Status = 'ONGOING' AND @StartedAt IS NULL
        SET @StartedAt = GETDATE();
    
    IF @Status IN ('DONE', 'FAILED', 'CANCELLED')
    BEGIN
        SET @CompletedAt = GETDATE();
        IF @StartedAt IS NOT NULL
            SET @DurationMs = DATEDIFF(MILLISECOND, @StartedAt, @CompletedAt);
    END
    
    -- Update execution
    UPDATE AGENT_MGMT.agent_executions
    SET status = @Status,
        status_message = COALESCE(@StatusMessage, status_message),
        started_at = COALESCE(@StartedAt, started_at),
        completed_at = COALESCE(@CompletedAt, completed_at),
        duration_ms = COALESCE(@DurationMs, duration_ms),
        tokens_consumed = COALESCE(@TokensConsumed, tokens_consumed),
        tokens_prompt = COALESCE(@TokensPrompt, tokens_prompt),
        tokens_completion = COALESCE(@TokensCompletion, tokens_completion),
        api_calls_count = COALESCE(@ApiCallsCount, api_calls_count),
        success = CASE WHEN @Status = 'DONE' THEN 1 WHEN @Status = 'FAILED' THEN 0 ELSE success END,
        updated_at = GETDATE()
    WHERE execution_id = @ExecutionId;
    
    -- If completed, update agent as inactive
    IF @Status IN ('DONE', 'FAILED', 'CANCELLED')
    BEGIN
        UPDATE AGENT_MGMT.agent_registry
        SET is_active = 0,
            updated_at = GETDATE()
        WHERE agent_id = @AgentId
            AND NOT EXISTS (
                SELECT 1 FROM AGENT_MGMT.agent_executions 
                WHERE agent_id = @AgentId AND status = 'ONGOING'
            );
    END
    
    -- Record metrics
    IF @TokensConsumed IS NOT NULL
    BEGIN
        INSERT INTO AGENT_MGMT.agent_metrics (agent_id, execution_id, metric_type, metric_value, metric_unit)
        VALUES (@AgentId, @ExecutionId, 'token_usage', @TokensConsumed, 'tokens');
    END
    
    IF @DurationMs IS NOT NULL
    BEGIN
        INSERT INTO AGENT_MGMT.agent_metrics (agent_id, execution_id, metric_type, metric_value, metric_unit)
        VALUES (@AgentId, @ExecutionId, 'execution_time', @DurationMs, 'ms');
    END
END;
GO

-- SP: Get agent dashboard
CREATE PROCEDURE AGENT_MGMT.sp_get_agent_dashboard
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM AGENT_MGMT.vw_agent_dashboard
    ORDER BY classification, agent_name;
END;
GO

-- SP: Get execution history
CREATE PROCEDURE AGENT_MGMT.sp_get_execution_history
    @AgentId NVARCHAR(100) = NULL,
    @Status NVARCHAR(20) = NULL,
    @TopN INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@TopN)
        execution_id,
        agent_id,
        action_name,
        intent_id,
        triggered_by,
        status,
        status_message,
        queued_at,
        started_at,
        completed_at,
        duration_ms,
        tokens_consumed,
        tokens_prompt,
        tokens_completion,
        api_calls_count,
        estimated_cost_usd,
        success,
        error_message,
        output_summary
    FROM AGENT_MGMT.agent_executions
    WHERE (@AgentId IS NULL OR agent_id = @AgentId)
        AND (@Status IS NULL OR status = @Status)
    ORDER BY queued_at DESC;
END;
GO

-- =====================================================
-- SEED DATA: Sync existing agents
-- =====================================================
-- This would be populated by a sync script that reads all manifest.json files
