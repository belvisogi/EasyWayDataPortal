/* V13 - Agent Chat persistence (LOG_AUDIT-backed)
   - Stores chat messages and conversation tombstones in PORTAL.LOG_AUDIT
   - Provides SPs for list/get/delete without introducing new tables
*/
GO

/* Agent Chat: append message event */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_log_message
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),            -- user id (or service)
  @agent_id NVARCHAR(128),
  @conversation_id NVARCHAR(128),
  @role NVARCHAR(16),              -- user|agent|system
  @content NVARCHAR(MAX),
  @metadata_json NVARCHAR(MAX) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL,
          @rows INT = 0;

  BEGIN TRY
    DECLARE @payload NVARCHAR(MAX) =
      (SELECT
        @conversation_id AS conversationId,
        @agent_id AS agentId,
        @role AS role,
        @content AS content,
        TRY_CONVERT(NVARCHAR(MAX), @metadata_json) AS metadataJson
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    INSERT INTO PORTAL.LOG_AUDIT(event_time, tenant_id, actor, origin, category, message, payload, status)
    VALUES(SYSUTCDATETIME(), @tenant_id, @actor, 'api', 'agent_chat.message', @content, @payload, @role);

    SET @rows = 1;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_log_message',
    @tenant_id=@tenant_id,
    @rows_inserted=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='INSERT',
    @created_by=COALESCE(@actor,'sp_agent_chat_log_message');

  IF @status <> 'OK'
  BEGIN
    THROW 51000, @err, 1;
  END
END
GO

/* Agent Chat: purge old logs (retention) */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_purge_logs
  @tenant_id NVARCHAR(50) = NULL,
  @older_than_days INT = 90
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL,
          @rows INT = 0;

  BEGIN TRY
    DELETE FROM PORTAL.LOG_AUDIT
    WHERE category LIKE 'agent_chat.%'
      AND event_time < DATEADD(DAY, -@older_than_days, SYSUTCDATETIME())
      AND (@tenant_id IS NULL OR tenant_id = @tenant_id);

    SET @rows = @@ROWCOUNT;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_purge_logs',
    @tenant_id=@tenant_id,
    @rows_deleted=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='DELETE',
    @created_by='sp_agent_chat_purge_logs';

  IF @status <> 'OK'
  BEGIN
    THROW 51004, @err, 1;
  END
END
GO

/* Agent Chat: list conversations for user + agent */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_list_conversations
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),
  @agent_id NVARCHAR(128),
  @limit INT = 20,
  @offset INT = 0
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL;

  BEGIN TRY
    ;WITH Deleted AS (
      SELECT DISTINCT JSON_VALUE(payload, '$.conversationId') AS conversationId
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.conversation_deleted'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId') IS NOT NULL
    ),
    Msg AS (
      SELECT
        JSON_VALUE(payload, '$.conversationId') AS conversationId,
        MAX(event_time) AS lastEventTime
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.message'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId') IS NOT NULL
      GROUP BY JSON_VALUE(payload, '$.conversationId')
    ),
    MsgFiltered AS (
      SELECT m.*
      FROM Msg m
      LEFT JOIN Deleted d ON d.conversationId = m.conversationId
      WHERE d.conversationId IS NULL
    ),
    Ranked AS (
      SELECT
        mf.conversationId,
        mf.lastEventTime,
        ROW_NUMBER() OVER (ORDER BY mf.lastEventTime DESC) AS rn
      FROM MsgFiltered mf
    )
    SELECT
      r.conversationId,
      r.lastEventTime,
      la.message AS lastMessage
    FROM Ranked r
    OUTER APPLY (
      SELECT TOP 1 message
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.message'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId')=r.conversationId
      ORDER BY event_time DESC, id DESC
    ) la
    WHERE r.rn > @offset AND r.rn <= (@offset + @limit)
    ORDER BY r.lastEventTime DESC;

    /* total */
    SELECT COUNT(1) AS total
    FROM MsgFiltered;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_list_conversations',
    @tenant_id=@tenant_id,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='SELECT',
    @created_by=COALESCE(@actor,'sp_agent_chat_list_conversations');

  IF @status <> 'OK'
  BEGIN
    THROW 51001, @err, 1;
  END
END
GO

/* Agent Chat: get full conversation messages */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_get_conversation
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),
  @agent_id NVARCHAR(128),
  @conversation_id NVARCHAR(128)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL;

  BEGIN TRY
    IF EXISTS (
      SELECT 1
      FROM PORTAL.LOG_AUDIT
      WHERE tenant_id=@tenant_id
        AND actor=@actor
        AND category='agent_chat.conversation_deleted'
        AND JSON_VALUE(payload, '$.agentId')=@agent_id
        AND JSON_VALUE(payload, '$.conversationId')=@conversation_id
    )
    BEGIN
      SELECT CAST(1 AS BIT) AS deleted;
      RETURN;
    END

    SELECT
      event_time,
      JSON_VALUE(payload, '$.role') AS role,
      message AS content,
      payload AS payload_json
    FROM PORTAL.LOG_AUDIT
    WHERE tenant_id=@tenant_id
      AND actor=@actor
      AND category='agent_chat.message'
      AND JSON_VALUE(payload, '$.agentId')=@agent_id
      AND JSON_VALUE(payload, '$.conversationId')=@conversation_id
    ORDER BY event_time ASC, id ASC;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_get_conversation',
    @tenant_id=@tenant_id,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='SELECT',
    @created_by=COALESCE(@actor,'sp_agent_chat_get_conversation');

  IF @status <> 'OK'
  BEGIN
    THROW 51002, @err, 1;
  END
END
GO

/* Agent Chat: soft delete conversation (tombstone event) */
CREATE OR ALTER PROCEDURE PORTAL.sp_agent_chat_delete_conversation
  @tenant_id NVARCHAR(50),
  @actor NVARCHAR(255),
  @agent_id NVARCHAR(128),
  @conversation_id NVARCHAR(128)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @start DATETIME2 = SYSUTCDATETIME(),
          @status NVARCHAR(50) = 'OK',
          @err NVARCHAR(2000) = NULL,
          @rows INT = 0;

  BEGIN TRY
    DECLARE @payload NVARCHAR(MAX) =
      (SELECT
        @conversation_id AS conversationId,
        @agent_id AS agentId
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    INSERT INTO PORTAL.LOG_AUDIT(event_time, tenant_id, actor, origin, category, message, payload, status)
    VALUES(SYSUTCDATETIME(), @tenant_id, @actor, 'api', 'agent_chat.conversation_deleted', 'Conversation deleted', @payload, 'DELETED');

    SET @rows = 1;
  END TRY
  BEGIN CATCH
    SET @status='ERROR';
    SET @err=ERROR_MESSAGE();
  END CATCH

  DECLARE @end DATETIME2 = SYSUTCDATETIME();
  EXEC PORTAL.sp_log_stats_execution
    @proc_name='sp_agent_chat_delete_conversation',
    @tenant_id=@tenant_id,
    @rows_inserted=@rows,
    @status=@status,
    @error_message=@err,
    @start_time=@start,
    @end_time=@end,
    @affected_tables='PORTAL.LOG_AUDIT',
    @operation_types='INSERT',
    @created_by=COALESCE(@actor,'sp_agent_chat_delete_conversation');

  IF @status <> 'OK'
  BEGIN
    THROW 51003, @err, 1;
  END
END
GO
