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
