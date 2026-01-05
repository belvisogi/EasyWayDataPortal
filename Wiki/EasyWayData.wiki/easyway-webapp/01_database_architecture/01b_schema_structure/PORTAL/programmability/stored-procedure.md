---
id: ew-stored-procedure
title: Stored Procedure
summary: 'Documento su Stored Procedure.'
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-stored-procedure, domain/db, layer/reference, audience/dba, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---

# EasyWay Data Portal - STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

### Riferimento agentico (breve)

Per supportare la creazione automatizzata da agenti (LLM/tooling) di DDL/SP conformi agli standard EasyWay:
- Linee guida agentiche: vedere `docs/agentic/AGENTIC_READINESS.md:1`
- Template SQL pronti: `docs/agentic/templates/ddl/template_table.sql:1` e `docs/agentic/templates/sp/*.sql:1`
- Esempi concreti (Users/Onboarding): `easyway-webapp/05_codice_easyway_portale/easyway_portal_api/agentic-readiness-and-examples.md:1`

Gli agenti devono usare template idempotenti (CREATE OR ALTER, IF NOT EXISTS), prevedere variante `_DEBUG`, e garantire logging su `PORTAL.STATS_EXECUTION_LOG` in ogni SP.

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


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
  # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


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
  # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


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
  # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


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
 = Ensure-Section # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


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
  # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section # EasyWay Data Portal – STORE PROCEDURE: Linee Guida, Best Practice e Template

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG, ext_attributes, auditing, logging automatico).

---

## ✅ Scopo del documento

Definire e standardizzare la **struttura, i pattern, e le best practice** delle store procedure (SP) per EasyWay Data Portal.  
Obiettivo: **nessun dato chiave inserito manualmente**, **tutto tracciato**, massima robustezza per AMS, DevOps, audit.

---

### **Principi generali EasyWay per Store Process**

- **Tutto l’onboarding, le operazioni DML, e la logica applicativa passano sempre da store procedure.**
- **Nessun insert/update diretto sulle tabelle anagrafiche e di business.**
- **Ogni store procedure aggiorna sempre i campi di auditing (`created_by`, `created_at`, `updated_at`).**
- **Tutte le SP devono scrivere SEMPRE un record su `PORTAL.STATS_EXECUTION_LOG`** con:
    - nome procedura,
    - tenant_id, user_id,
    - righe inserite/aggiornate/cancellate,
    - start_time, end_time, durata,
    - status (`OK`/`ERROR`),
    - error_message se presente,
    - tabelle impattate, tipo operazione, chi ha eseguito.
- **Ogni store procedure importante** (soprattutto quelle richiamate da API/servizi/portale) ha anche la versione `_DEBUG`:
    - Usa sequence e codici di test (es. `TENDEBUG001`)
    - Parametri di default per demo, UAT, sandbox, DevOps
    - Sempre logging su `PORTAL.STATS_EXECUTION_LOG`
- **Gestione errori atomica:** TRY/CATCH, ROLLBACK su errore, transazione sempre chiusa

---

🚦 **Roadmap Operativa Store Procedure EasyWay Data Portal**
------------------------------------------------------------

### 1️⃣ **Regole fisse**

*   Tutte le DML su tabelle principali si fanno **SOLO tramite store process**.
    
*   Ogni store process esegue **logging completo su `PORTAL.STATS_EXECUTION_LOG`** (e tabella TABLE_LOG se necessario).
    
*   **DEBUG**: ogni store ha sempre la sua versione di test (sequence e NDG separati).
    
*   La logica NDG (tenant/user) viene sempre generata dentro la store (mai lato API).
    
*   **Gestione atomica (TRY/CATCH + TRANSACTION)** sempre, rollback automatico su errore.
    
*   **`created_by` di default = nome SP** (o servizio/utente passato in input).
    

* * *

### 2️⃣ **Prossimi step e template**

Per ogni tabella chiave di PORTAL (e analoghe in altri schema), fornirò:
*   **Store di INSERT** (con NDG, auditing, logging)
    
*   **Store di UPDATE** (per scenari reali, aggiornamento sicuro e tracciato)
    
*   **Store di DELETE “safe”** (soft delete, flag, o logga tutto)
    
*   **Versione DEBUG per ogni store**
    
*   **Documentazione .md pronta per Wiki**
    

* * *

### 3️⃣ **Esempio template standard INSERT/UPDATE/DELETE**

(già pronto per pipeline, API, batch, ecc.)

#### **a) INSERT (Onboarding/Creazione)**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_insert_[TABLE]     -- parametri tabella... AS BEGIN     SET NOCOUNT ON;     -- transazione, insert, auditing, logging END GO
```sql

#### **b) UPDATE**

```sql 
CREATE OR ALTER PROCEDURE PORTAL.sp_update_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, update, auditing, logging END GO`
```sql
#### **c) DELETE / SOFT DELETE**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_delete_[TABLE]     -- parametri... AS BEGIN     SET NOCOUNT ON;     -- transazione, soft delete (flag), logging END GO
```sql
#### **d) DEBUG**

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_insert_[TABLE] AS BEGIN     -- chiama insert con parametri demo/sandbox, usa sequence debug END GO`
```sql

* * *

### 4️⃣ **Automazione della documentazione**

Tutte le SP saranno documentate in **Markdown** pronto per Azure DevOps.  
Le sezioni per ogni store sono sempre:

| Sezione | Contenuto |
| --- | --- |
| Scopo | Cosa fa la store |
| Parametri | Elenco parametri e descrizione |
| Logica Dati | Dettaglio di business (NDG, auditing, ecc.) |
| Logging | Modalità di tracking e error handling |
| Debug | Differenze rispetto alla produzione |
| Esempi | Chiamata reale/test |
| Versione | Data, autore, note AMS/DevOps |


## **Template** ##

## Template standard EasyWay (produzione)

```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255),
    @plan_code NVARCHAR(50),
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255),
    @name NVARCHAR(100),
    @surname NVARCHAR(100),
    @password NVARCHAR(255) = NULL,
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = SYSUTCDATETIME();
    DECLARE @rows_inserted INT = 0, @rows_updated INT = 0, @rows_deleted INT = 0;
    DECLARE @status NVARCHAR(50) = 'OK', @error_message NVARCHAR(2000) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- NDG tenant_id se mancante
        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
            SET @tenant_id = 'TEN' + RIGHT('000000000' + CAST(@next_seq_tenant AS NVARCHAR), 9);
        END

        -- NDG user_id se mancante
        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
            SET @user_id = 'CDI' + RIGHT('000000000' + CAST(@next_seq_user AS NVARCHAR), 9);
        END

        -- Tenant
        IF NOT EXISTS (SELECT 1 FROM PORTAL.TENANT WHERE tenant_id = @tenant_id)
        BEGIN
            INSERT INTO PORTAL.TENANT (tenant_id, name, plan_code, created_by)
            VALUES (@tenant_id, @tenant_name, @plan_code, COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Profilo admin se manca
        IF NOT EXISTS (SELECT 1 FROM PORTAL.PROFILE_DOMAINS WHERE profile_code = 'TENANT_ADMIN')
        BEGIN
            INSERT INTO PORTAL.PROFILE_DOMAINS (profile_code, description, created_by)
            VALUES ('TENANT_ADMIN', 'Amministratore Tenant', COALESCE(@created_by, 'sp_register_tenant_and_user'));
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- User admin
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USERS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USERS (
                user_id, tenant_id, email, name, surname, password,
                provider, provider_user_id, profile_code, is_tenant_admin, created_by
            )
            VALUES (
                @user_id, @tenant_id, @email, @name, @surname, @password,
                @provider, @provider_user_id, 'TENANT_ADMIN', 1, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        -- Notifiche default
        IF NOT EXISTS (SELECT 1 FROM PORTAL.USER_NOTIFICATION_SETTINGS WHERE user_id = @user_id)
        BEGIN
            INSERT INTO PORTAL.USER_NOTIFICATION_SETTINGS (
                tenant_id, user_id, notify_on_upload, notify_on_alert, notify_on_digest, created_by
            )
            VALUES (
                @tenant_id, @user_id, 1, 1, 0, COALESCE(@created_by, 'sp_register_tenant_and_user')
            );
            SET @rows_inserted = @rows_inserted + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @status = 'ERROR';
        SET @error_message = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    -- Logging obbligatorio
    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_register_tenant_and_user', @tenant_id, @user_id, @rows_inserted, @rows_updated, @rows_deleted, @status, @error_message,
        @start_time, SYSUTCDATETIME(), DATEDIFF(MILLISECOND, @start_time, SYSUTCDATETIME()),
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', COALESCE(@created_by, 'sp_register_tenant_and_user')
    );
END
```sql

3️⃣ Template DEBUG EasyWay
```sql
CREATE OR ALTER PROCEDURE PORTAL.sp_debug_register_tenant_and_user
    @tenant_id NVARCHAR(50) = NULL,
    @tenant_name NVARCHAR(255) = 'Demo Tenant Srl',
    @plan_code NVARCHAR(50) = 'BRONZE',
    @user_id NVARCHAR(50) = NULL,
    @email NVARCHAR(255) = 'debuguser+demo@easyway.it',
    @name NVARCHAR(100) = 'Mario',
    @surname NVARCHAR(100) = 'Debug',
    @password NVARCHAR(255) = 'HASHED_PASSWORD',
    @provider NVARCHAR(50) = NULL,
    @provider_user_id NVARCHAR(255) = NULL,
    @created_by NVARCHAR(255) = 'sp_debug_register_tenant_and_user'
AS
BEGIN
    SET NOCOUNT ON;
    -- Come sopra, ma sequence di debug e NDG debug
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @tenant_id IS NULL OR @tenant_id = ''
        BEGIN
            DECLARE @next_seq_tenant INT;
            SET @next_seq_tenant = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
            SET @tenant_id = 'TENDEBUG' + RIGHT('000' + CAST(@next_seq_tenant AS NVARCHAR), 3);
        END

        IF @user_id IS NULL OR @user_id = ''
        BEGIN
            DECLARE @next_seq_user INT;
            SET @next_seq_user = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
            SET @user_id = 'CDIDEBUG' + RIGHT('000' + CAST(@next_seq_user AS NVARCHAR), 3);
        END

        -- Logica identica alla store principale...

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    END CATCH

    INSERT INTO PORTAL.STATS_EXECUTION_LOG (
        proc_name, tenant_id, user_id, rows_inserted, rows_updated, rows_deleted, status, error_message,
        start_time, end_time, duration_ms, affected_tables, operation_types, created_by
    ) VALUES (
        'sp_debug_register_tenant_and_user', @tenant_id, @user_id, 1, 0, 0, 'OK', NULL,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0,
        'PORTAL.TENANT,PORTAL.PROFILE_DOMAINS,PORTAL.USERS,PORTAL.USER_NOTIFICATION_SETTINGS',
        'INSERT', 'sp_debug_register_tenant_and_user'
    );
END

```sql
4️⃣ Best practice operative
---------------------------

*   Tutte le SP usano sempre i parametri NDG e multi-tenant.
    
*   **Gestione logging/statistiche**: ogni esecuzione tracciata.
    
*   **Le versioni DEBUG** usano sempre ID e sequence separate, non “sporcano” la produzione.
    
*   **Nessuna insert manuale** sulle tabelle principali: sempre via SP.
    
*   **Modello pronto per future automazioni (CI/CD, pipeline, audit AMS, etc)**.
    

* * *

5️⃣ Esempio pratico di chiamata
-------------------------------

```sql
EXEC PORTAL.sp_register_tenant_and_user
    @tenant_name = 'Acme Srl',
    @plan_code = 'BRONZE',
    @email = 'admin@acme.it',
    @name = 'Mario',
    @surname = 'Rossi',
    @password = 'HASHED_PASSWORD',
    @created_by = 'API_GATEWAY';

```sql
```sql
EXEC PORTAL.sp_debug_register_tenant_and_user
    @tenant_name = 'Tenant Test',
    @plan_code = 'DEBUG',
    @email = 'debug@easyway.it',
    @name = 'Debug',
    @surname = 'User',
    @password = 'DEBUG_HASH',
    @created_by = 'DEBUG_TOOL';
```sql

🔒 Ogni store process nuova/futura dovrà sempre seguire queste linee guida.


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
- [Entities Index](../../../../../entities-index.md)












