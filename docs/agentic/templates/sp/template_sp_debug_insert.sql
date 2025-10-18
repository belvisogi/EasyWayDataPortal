/* TEMPLATE SP DEBUG INSERT
Sostituire i segnaposto {{...}} prima del rilascio.
*/

CREATE OR ALTER PROCEDURE {{SCHEMA}}.sp_debug_insert_{{OBJECT}}
    -- Parametri input di test con default sicuri
    -- {{PARAMS_DEBUG}}
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Usare sequence DEBUG e NDG di test
        -- {{DEBUG_NDG_BLOCK}}

        -- Richiamare la SP di produzione o replicarne la logica
        -- {{DEBUG_CALL_OR_BODY}}
        SET @rows_inserted = @rows_inserted + 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted,
        affected_tables, operation_types, start_time, end_time, duration_ms, status, error_message, created_by
    ) VALUES (
        'sp_debug_insert_{{OBJECT}}', NULL, NULL, @rows_inserted, 0, 0,
        '{{SCHEMA}}.{{TABLE}}', 'INSERT', @start_time, SYSUTCDATETIME(), DATEDIFF(ms, @start_time, SYSUTCDATETIME()), 'OK', NULL, 'sp_debug_insert_{{OBJECT}}'
    );
END

