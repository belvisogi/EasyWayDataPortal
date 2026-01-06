-- LEGACY: questo provisioning SQL può divergere da Flyway.
-- Usa `db/flyway/sql/` tramite `db/provisioning/apply-flyway.ps1`.
--
-- Idempotent schema creation for Azure SQL Server
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'PORTAL')
    EXEC('CREATE SCHEMA [PORTAL]');
GO
