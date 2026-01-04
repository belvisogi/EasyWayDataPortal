---
id: ew-stats-execution-log
title: stats execution log
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-stored-procedure, domain/db, layer/reference, audience/dba, privacy/internal, language/it]
title: stats execution log
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
* Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.

## Schema/DDL
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
`sql
-- Esempio DDL idempotente
`
"@
  * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->

## Esempi Query
`sql
-- SELECT ... FROM ...
`
"@
  * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.

## Schema/DDL
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
`sql
-- Esempio DDL idempotente
`
"@
  * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->
 = Ensure-Section * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.

## Schema/DDL
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
`sql
-- Esempio DDL idempotente
`
"@
  * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section * Abbiamo definito una SP,  `sp_log_stats_execution`, con tutti i parametri necessari (proc_name, rows, status, etc).
    
*   Nelle altre store process, al posto dell’`INSERT INTO ...` metti solo la chiamata a questa SP.
    
*   Se domani aggiungi colonne o cambi qualcosa nel log, lo cambi in una sola SP.

```sql
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
```sql

2️⃣ **Nuovo template di chiamata nelle altre SP**
-------------------------------------------------

**Esempio, nella tua SP di update:**

```sql
-- Dopo il TRY/CATCH, al posto del vecchio INSERT:
EXEC PORTAL.sp_log_stats_execution
    @proc_name = 'sp_update_profile_domain',
    @tenant_id = NULL,
    @user_id = NULL,
    @rows_updated = @rows_updated,
    @status = @status,
    @error_message = @error_message,
    @start_time = @start_time,
    @end_time = SYSUTCDATETIME(),
    @affected_tables = 'PORTAL.PROFILE_DOMAINS',
    @operation_types = 'UPDATE',
    @payload = NULL,
    @created_by = COALESCE(@updated_by, 'sp_update_profile_domain');
```sql

**PS:**
*   Puoi usare lo stesso pattern per **insert, delete, debug** (cambiando i parametri per il tipo di operazione).
    
*   Se ti serve loggare info extra (payload JSON, nome tabella, ecc.), basta passarlo nei parametri.
    
*   Se vuoi logging anche sulle tabelle di dettaglio (STATS_EXECUTION_TABLE_LOG) basta aggiungere un’ulteriore SP analoga.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->
 'Domande a cui risponde' @"
- Cosa fa?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Collegamenti
- [Entities Index](../../../../../../entities-index.md)










