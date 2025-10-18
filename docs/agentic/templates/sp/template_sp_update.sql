/* TEMPLATE SP UPDATE (produzione)
Sostituire i segnaposto {{...}} prima del rilascio.
*/

CREATE OR ALTER PROCEDURE {{SCHEMA}}.sp_update_{{OBJECT}}
    -- Parametri input (chiave + campi aggiornabili)
    -- {{PARAMS}}
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDATE business
        -- {{UPDATE_BLOCK}}
        SET @rows_updated = @rows_updated + @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted,
        affected_tables, operation_types, start_time, end_time, duration_ms, status, error_message, created_by
    ) VALUES (
        'sp_update_{{OBJECT}}', NULL, NULL, @rows_inserted, @rows_updated, @rows_deleted,
        '{{SCHEMA}}.{{TABLE}}', 'UPDATE', @start_time, SYSUTCDATETIME(), DATEDIFF(ms, @start_time, SYSUTCDATETIME()), @status, @error_message, 'sp_update_{{OBJECT}}'
    );
END

