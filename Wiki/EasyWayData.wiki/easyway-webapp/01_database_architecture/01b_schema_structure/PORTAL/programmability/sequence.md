---
id: ew-sequence
title: sequence
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-sequence, domain/db, layer/reference, audience/dba, privacy/internal, language/it]
title: sequence---
# EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
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
  # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
```sql


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
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
  # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
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
  # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
```sql


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
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
 = Ensure-Section # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
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
  # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
```sql


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

## Scopo
Breve descrizione dello scopo del documento.
 = Ensure-Section # EasyWay Data Portal – SEQUENCE

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Definire tutte le **sequence numeriche** utilizzate per la generazione dei codici NDG (tenant, user, ecc.)  
sia in produzione che in debug/test, garantendo tracciabilità e nessuna collisione tra dati reali e mock.

---

## 1️⃣ Sequence PRODUZIONE (NDG reali)

```sql
-- Sequence per tenant_id (NDG es. TEN00000001000)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;

-- Sequence per user_id (NDG es. CDI00000001000)
CREATE SEQUENCE PORTAL.SEQ_USER_ID
    AS INT
    START WITH 1000
    INCREMENT BY 1;
```sql

## 2️⃣ Sequence DEBUG/TEST (codici demo)

```sql
-- Sequence di debug per tenant_id (codici: TENDEBUG000 ... TENDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_TENANT_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;

-- Sequence di debug per user_id (codici: CDIDEBUG000 ... CDIDEBUG999)
CREATE SEQUENCE PORTAL.SEQ_USER_ID_DEBUG
    AS INT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 999
    CYCLE;
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









