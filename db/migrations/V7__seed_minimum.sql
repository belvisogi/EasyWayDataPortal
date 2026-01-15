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

