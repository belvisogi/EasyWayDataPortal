---
owner: team-platform
id: ew-runbook-agent-chat-retention
tags: [runbook, db, agents, audit, retention, language/it]
status: draft
title: Agent Chat Retention (SQL Server Agent Job)
summary: Purge periodica dei log agent chat (LOG_AUDIT) tramite SQL Server Agent.
updated: 2026-01-16

llm:
  include: true
  chunk_hint: 5000---

# Agent Chat Retention (SQL Server Agent Job)

## Scopo
Eseguire periodicamente la pulizia dei log chat salvati in `PORTAL.LOG_AUDIT` tramite la stored procedure `PORTAL.sp_agent_chat_purge_logs`.

## Prerequisiti
- Migrazione `db/migrations/V13__agent_chat.sql` applicata.
- Permessi SQL Server Agent per creare job.

## Parametri
- `@older_than_days`: default 90
- `@tenant_id`: NULL per tutti i tenant, oppure un tenant specifico

## Script Job (SQL Server Agent)

Template SQL: `docs/agentic/templates/docs/agent-chat-retention.job.sql`

```sql
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
```

## Verifica
- Esegui manualmente lo step e verifica `PORTAL.STATS_EXECUTION_LOG` per `sp_agent_chat_purge_logs`.
- Controlla che `PORTAL.LOG_AUDIT` diminuisca per eventi `agent_chat.*`.

## Rollback
- Disabilita o elimina il job SQL Server Agent.


