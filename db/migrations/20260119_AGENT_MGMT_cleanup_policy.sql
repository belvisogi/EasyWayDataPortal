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
