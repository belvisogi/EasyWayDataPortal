---
id: ew-function
title: function
summary: 'Documento su function.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-function, domain/db, layer/reference, audience/dba, privacy/internal, language/it]
title: function
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
-- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



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
  -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



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
  -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



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
  -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



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
 = Ensure-Section -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



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
  -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section -- Modello in uso: Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
-- Queste funzioni sono da creare nello schema PORTAL.

-- ========================
-- 1️⃣ Funzione PRODUZIONE: Generazione tenant_id (TEN00000001000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID;
    RETURN 'TEN' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql
-- ========================
-- 2️⃣ Funzione PRODUZIONE: Generazione user_id (CDI00000001000)
-- ========================

```sql
CREATE FUNCTION PORTAL.fn_next_user_id()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID;
    RETURN 'CDI' + RIGHT('000000000' + CAST(@seq AS NVARCHAR), 9);
END
GO
```sql

-- ========================
-- 3️⃣ Funzione DEBUG: Generazione tenant_id di test (TENDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_tenant_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_TENANT_ID_DEBUG;
    RETURN 'TENDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql

-- ========================
-- 4️⃣ Funzione DEBUG: Generazione user_id di test (CDIDEBUG000)
-- ========================
```sql
CREATE FUNCTION PORTAL.fn_next_user_id_debug()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @seq INT = NEXT VALUE FOR PORTAL.SEQ_USER_ID_DEBUG;
    RETURN 'CDIDEBUG' + RIGHT('000' + CAST(@seq AS NVARCHAR), 3);
END
GO
```sql



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











