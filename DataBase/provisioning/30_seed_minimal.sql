-- Minimal seed for local demo/test (idempotent)

-- Tenants
IF NOT EXISTS (SELECT 1 FROM [PORTAL].[tenants] WHERE tenant_id = N'dev-tenant')
    INSERT INTO [PORTAL].[tenants](tenant_id, tenant_name, tenant_description)
    VALUES (N'dev-tenant', N'Dev Tenant', N'Tenant di sviluppo');
GO

-- Profiles
IF NOT EXISTS (SELECT 1 FROM [PORTAL].[profiles] WHERE profile_id = N'admin')
    INSERT INTO [PORTAL].[profiles](profile_id, profile_name, profile_description)
    VALUES (N'admin', N'Amministratore', N'Ruolo amministrativo');
GO

-- Users
IF NOT EXISTS (SELECT 1 FROM [PORTAL].[users] WHERE user_id = N'admin@dev')
    INSERT INTO [PORTAL].[users](user_id, tenant_id, profile_id, email, [password], is_active, is_notify_enabled)
    VALUES (N'admin@dev', N'dev-tenant', N'admin', N'admin@example.com', N'REPLACE_ME', 1, 1);
GO

IF NOT EXISTS (SELECT 1 FROM [PORTAL].[user_notification_settings] WHERE user_id = N'admin@dev')
    INSERT INTO [PORTAL].[user_notification_settings](user_id, notify_email, notify_portal, notify_sms)
    VALUES (N'admin@dev', 1, 1, 0);
GO

