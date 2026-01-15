/* ==========================================================
   EASYWAY DATA PORTAL - STANDARD DDL v.2025-07-20
   Schema: PORTAL
   - Notazione sempre: PORTAL.TABELLA
   - DROP completo (ordine dipendenze)
   - DDL con default 'MANUAL' su created_by
   - PK/FK sempre presenti
   - Primi esempi sp_addextendedproperty per Erwin/PowerDesigner
   ========================================================== */

--------------------------------------------------------------
-- DROP TABLES (ORDINE FK, solo se esistono)
--------------------------------------------------------------
IF OBJECT_ID('PORTAL.STATS_EXECUTION_TABLE_LOG', 'U') IS NOT NULL DROP TABLE PORTAL.STATS_EXECUTION_TABLE_LOG;
IF OBJECT_ID('PORTAL.STATS_EXECUTION_LOG', 'U') IS NOT NULL DROP TABLE PORTAL.STATS_EXECUTION_LOG;
IF OBJECT_ID('PORTAL.LOG_AUDIT', 'U') IS NOT NULL DROP TABLE PORTAL.LOG_AUDIT;
IF OBJECT_ID('PORTAL.USER_NOTIFICATION_SETTINGS', 'U') IS NOT NULL DROP TABLE PORTAL.USER_NOTIFICATION_SETTINGS;
IF OBJECT_ID('PORTAL.SECTION_ACCESS', 'U') IS NOT NULL DROP TABLE PORTAL.SECTION_ACCESS;
IF OBJECT_ID('PORTAL.USERS', 'U') IS NOT NULL DROP TABLE PORTAL.USERS;
IF OBJECT_ID('PORTAL.SUBSCRIPTION', 'U') IS NOT NULL DROP TABLE PORTAL.SUBSCRIPTION;
IF OBJECT_ID('PORTAL.PROFILE_DOMAINS', 'U') IS NOT NULL DROP TABLE PORTAL.PROFILE_DOMAINS;
IF OBJECT_ID('PORTAL.TENANT', 'U') IS NOT NULL DROP TABLE PORTAL.TENANT;
IF OBJECT_ID('PORTAL.MASKING_METADATA', 'U') IS NOT NULL DROP TABLE PORTAL.MASKING_METADATA;
IF OBJECT_ID('PORTAL.RLS_METADATA', 'U') IS NOT NULL DROP TABLE PORTAL.RLS_METADATA;
IF OBJECT_ID('PORTAL.CONFIGURATION', 'U') IS NOT NULL DROP TABLE PORTAL.CONFIGURATION;

--------------------------------------------------------------
-- DDL TABELLE (SOLO PORTAL.SCHEMA)
--------------------------------------------------------------

/* ==========================================================
   TAB: PORTAL.TENANT
   Gestione anagrafica tenant/cliente, NDG, piano, attributi custom.
   ========================================================== */
CREATE TABLE PORTAL.TENANT (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50) UNIQUE NOT NULL,
  name NVARCHAR(255) NOT NULL,
  plan_code NVARCHAR(50) NOT NULL,
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.PROFILE_DOMAINS
   Profili/ruoli ACL.
   ========================================================== */
CREATE TABLE PORTAL.PROFILE_DOMAINS (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  profile_code NVARCHAR(50) UNIQUE NOT NULL,
  description NVARCHAR(255),
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.USERS
   Anagrafica utenti multi-tenant (ACL, NDG, federato/locale).
   ========================================================== */
CREATE TABLE PORTAL.USERS (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  user_id NVARCHAR(50) UNIQUE NOT NULL,
  tenant_id NVARCHAR(50) NOT NULL,
  email NVARCHAR(255) NOT NULL,
  name NVARCHAR(100),
  surname NVARCHAR(100),
  password NVARCHAR(255),
  provider NVARCHAR(50),
  provider_user_id NVARCHAR(255),
  status NVARCHAR(50),
  profile_code NVARCHAR(50) NOT NULL,
  is_tenant_admin BIT,
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.SECTION_ACCESS
   Policy di accesso sezioni/funzionalità (tenant, profilo, utente).
   ========================================================== */
CREATE TABLE PORTAL.SECTION_ACCESS (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50) NOT NULL,
  section_code NVARCHAR(50),
  profile_code NVARCHAR(50) NULL,
  user_id NVARCHAR(50) NULL,
  is_enabled BIT,
  valid_from DATETIME2 NULL,
  valid_to DATETIME2 NULL,
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.USER_NOTIFICATION_SETTINGS
   Preferenze di notifica utente.
   ========================================================== */
CREATE TABLE PORTAL.USER_NOTIFICATION_SETTINGS (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50) NOT NULL,
  user_id NVARCHAR(50) NOT NULL,
  notify_on_upload BIT,
  notify_on_alert BIT,
  notify_on_digest BIT,
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.SUBSCRIPTION
   Stato abbonamento/scadenze per ogni tenant.
   ========================================================== */
CREATE TABLE PORTAL.SUBSCRIPTION (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50) NOT NULL,
  plan_code NVARCHAR(50) NOT NULL,
  status NVARCHAR(50) NOT NULL,
  start_date DATETIME2 NOT NULL,
  end_date DATETIME2 NOT NULL,
  external_payment_id NVARCHAR(100),
  payment_provider NVARCHAR(50),
  last_payment_date DATETIME2,
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.MASKING_METADATA
   Metadati mascheramento colonne (GDPR/SOC2).
   ========================================================== */
CREATE TABLE PORTAL.MASKING_METADATA (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50),
  schema_name NVARCHAR(50),
  table_name NVARCHAR(100),
  column_name NVARCHAR(100),
  mask_type NVARCHAR(50),
  note NVARCHAR(255),
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.RLS_METADATA
   Metadati Row-Level Security (RLS).
   ========================================================== */
CREATE TABLE PORTAL.RLS_METADATA (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50),
  schema_name NVARCHAR(50),
  table_name NVARCHAR(100),
  column_name NVARCHAR(100),
  policy_name NVARCHAR(100),
  predicate_function NVARCHAR(255),
  note NVARCHAR(255),
  ext_attributes NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.CONFIGURATION
   Parametri, flag, chiavi API, feature toggle, override per tenant.
   ========================================================== */
CREATE TABLE PORTAL.CONFIGURATION (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50),
  config_key NVARCHAR(100) NOT NULL,
  config_value NVARCHAR(MAX) NOT NULL,
  description NVARCHAR(255),
  is_active BIT DEFAULT 1,
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  UNIQUE (tenant_id, config_key)
);

/* ==========================================================
   TAB: PORTAL.LOG_AUDIT
   Log/audit centralizzato (operazioni API, job, batch).
   ========================================================== */
CREATE TABLE PORTAL.LOG_AUDIT (
  id INT IDENTITY(1, 1) PRIMARY KEY,
  tenant_id NVARCHAR(50),
  user_id NVARCHAR(50),
  event_type NVARCHAR(100) NOT NULL,
  event_status NVARCHAR(50),
  object_schema NVARCHAR(100),
  object_name NVARCHAR(100),
  object_id NVARCHAR(100),
  action NVARCHAR(100),
  message NVARCHAR(2000),
  payload NVARCHAR(MAX),
  created_by NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.STATS_EXECUTION_LOG
   Log tecnico/statistico delle store procedure (insert/update/delete).
   ========================================================== */
CREATE TABLE PORTAL.STATS_EXECUTION_LOG (
  execution_id INT IDENTITY(1,1) PRIMARY KEY,
  proc_name NVARCHAR(200) NOT NULL,
  tenant_id NVARCHAR(50) NULL,
  user_id NVARCHAR(50) NULL,
  rows_inserted INT DEFAULT 0,
  rows_updated  INT DEFAULT 0,
  rows_deleted  INT DEFAULT 0,
  rows_total    INT DEFAULT 0,
  affected_tables NVARCHAR(500),
  operation_types NVARCHAR(100),
  start_time    DATETIME2 DEFAULT SYSUTCDATETIME(),
  end_time      DATETIME2,
  duration_ms   INT,
  status        NVARCHAR(50) DEFAULT 'OK',
  error_message NVARCHAR(2000) NULL,
  payload       NVARCHAR(MAX) NULL,
  created_by    NVARCHAR(255) NOT NULL DEFAULT ('MANUAL'),
  created_at    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

/* ==========================================================
   TAB: PORTAL.STATS_EXECUTION_TABLE_LOG
   Dettaglio per ogni tabella impattata da ogni execution.
   ========================================================== */
CREATE TABLE PORTAL.STATS_EXECUTION_TABLE_LOG (
    id INT IDENTITY(1,1) PRIMARY KEY,
    execution_id INT NOT NULL,
    table_name NVARCHAR(100) NOT NULL,
    operation_type NVARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE, etc
    rows_affected INT DEFAULT 0,
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (execution_id) REFERENCES PORTAL.STATS_EXECUTION_LOG(execution_id)
);

--------------------------------------------------------------
-- FOREIGN KEYS FINALI
--------------------------------------------------------------
ALTER TABLE PORTAL.USERS ADD FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id);
ALTER TABLE PORTAL.USERS ADD FOREIGN KEY (profile_code) REFERENCES PORTAL.PROFILE_DOMAINS(profile_code);
ALTER TABLE PORTAL.SECTION_ACCESS ADD FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id);
ALTER TABLE PORTAL.USER_NOTIFICATION_SETTINGS ADD FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id);
ALTER TABLE PORTAL.USER_NOTIFICATION_SETTINGS ADD FOREIGN KEY (user_id) REFERENCES PORTAL.USERS(user_id);
ALTER TABLE PORTAL.SUBSCRIPTION ADD FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id);
ALTER TABLE PORTAL.CONFIGURATION ADD FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id);

--------------------------------------------------------------
-- ESEMPIO DI EXTENDED PROPERTY SU UNA COLONNA (PORTAL.TENANT.tenant_id)
--------------------------------------------------------------
EXEC sp_addextendedproperty
    @name = N'Column_Description',
    @value = 'Codice identificativo cliente / tenant (NDG es. TEN00000001000)',
    @level0type = N'Schema', @level0name = 'PORTAL',
    @level1type = N'Table',  @level1name = 'TENANT',
    @level2type = N'Column', @level2name = 'tenant_id';

-- (Ripeti/automatizza per tutte le altre colonne chiave delle tabelle secondo standard EasyWay)
