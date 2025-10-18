-- Foreign keys and indexes (idempotent)

-- FK users.tenant_id -> tenants.tenant_id
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_users_tenants')
BEGIN
    ALTER TABLE [PORTAL].[users]
        ADD CONSTRAINT FK_users_tenants FOREIGN KEY ([tenant_id])
        REFERENCES [PORTAL].[tenants] ([tenant_id]);
END
GO

-- FK users.profile_id -> profiles.profile_id
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_users_profiles')
BEGIN
    ALTER TABLE [PORTAL].[users]
        ADD CONSTRAINT FK_users_profiles FOREIGN KEY ([profile_id])
        REFERENCES [PORTAL].[profiles] ([profile_id]);
END
GO

-- FK user_notification_settings.user_id -> users.user_id
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_uns_users')
BEGIN
    ALTER TABLE [PORTAL].[user_notification_settings]
        ADD CONSTRAINT FK_uns_users FOREIGN KEY ([user_id])
        REFERENCES [PORTAL].[users] ([user_id]);
END
GO

-- Useful indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_users_email' AND object_id = OBJECT_ID(N'[PORTAL].[users]'))
    CREATE UNIQUE INDEX IX_users_email ON [PORTAL].[users]([email]);
GO

