USE msdb;
GO

EXEC sp_add_job
  @job_name = N'EasyWay.AgentChat.Retention',
  @enabled = 1,
  @description = N'Purge log agent chat (LOG_AUDIT) older than N days';

EXEC sp_add_jobstep
  @job_name = N'EasyWay.AgentChat.Retention',
  @step_name = N'PurgeAgentChatLogs',
  @subsystem = N'TSQL',
  @database_name = N'<DB_NAME>',
  @command = N'EXEC PORTAL.sp_agent_chat_purge_logs @tenant_id = NULL, @older_than_days = 90;';

EXEC sp_add_schedule
  @schedule_name = N'EasyWay.AgentChat.Retention.Daily0200',
  @freq_type = 4,             -- daily
  @freq_interval = 1,         -- every 1 day
  @active_start_time = 020000; -- 02:00

EXEC sp_attach_schedule
  @job_name = N'EasyWay.AgentChat.Retention',
  @schedule_name = N'EasyWay.AgentChat.Retention.Daily0200';

EXEC sp_add_jobserver
  @job_name = N'EasyWay.AgentChat.Retention';
GO
