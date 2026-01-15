CREATE OR ALTER PROCEDURE PORTAL.sp_log_stats_execution
    @proc_name NVARCHAR(200),
    @tenant_id NVARCHAR(50) = NULL,
    @user_id NVARCHAR(50) = NULL,
    @rows_inserted INT = 0,
    @rows_updated INT = 0,
    @rows_deleted INT = 0,
    @rows_total INT = 0,
    @status NVARCHAR(50) = 'OK',
    @error_message NVARCHAR(2000) = NULL,
    @start_time DATETIME2 = NULL,
    @end_time DATETIME2 = NULL,
    @affected_tables NVARCHAR(500) = NULL,
    @operation_types NVARCHAR(100) = NULL,
    @payload NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, rows_total,
        status, error_message, start_time, end_time, duration_ms,
        affected_tables, operation_types, payload, created_by, created_at
    )
    VALUES (
        @proc_name, @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @rows_total,
        @status, @error_message, @start_time, @end_time, 
        DATEDIFF(MILLISECOND, @start_time, @end_time),
        @affected_tables, @operation_types, @payload,
        COALESCE(@created_by, @proc_name), SYSUTCDATETIME()
    );
END
GO
