---
id: ew-01a-db-setup
title: 01a db setup
tags: [domain/db, layer/howto, audience/dev, audience/dba, privacy/internal, language/it, setup]
owner: team-platform
summary: 'Documento su 01a db setup.'
status: active
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

[Home](.././start-here.md) > [[domains/db|db]] > [[Layer - Howto|Howto]]

# EasyWay Data Portal - Database SETUP

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

## ✅ Scopo del file

Configurazione iniziale e sicura di login, utenti, ruoli, permessi e policy a livello SQL Server e database,  
per ambiente **EASYWAY_PORTAL_DEV**.

---

## 1️⃣ **Login SQL Server (da creare su MASTER)**

```sql
CREATE LOGIN [EWPORTAL_APP_RO] 
WITH PASSWORD = 'R4nd0m!PW2024$Xx-RO@';

CREATE LOGIN [EWPORTAL_APP_RW] 
WITH PASSWORD = 'R4nd0m!PW2024$Xx-RW@';

CREATE LOGIN [EWPORTAL_ADMIN]   
WITH PASSWORD = 'R4nd0m!PW2024$Xx-AD@';


2️⃣ **Users (da creare dentro EASYWAY_PORTAL_DEV)**

```sql
USE [EASYWAY_PORTAL_DEV];

CREATE USER [EWPORTAL_APP_RO] FOR LOGIN [EWPORTAL_APP_RO];
CREATE USER [EWPORTAL_APP_RW] FOR LOGIN [EWPORTAL_APP_RW];
CREATE USER [EWPORTAL_ADMIN]   FOR LOGIN [EWPORTAL_ADMIN];
```sql

3️⃣ **Ruoli di Sicurezza**

```sql
-- Read-Only (Reporting)
CREATE ROLE EWPORTAL_RO;
ALTER ROLE EWPORTAL_RO ADD MEMBER EWPORTAL_APP_RO;

-- Read-Write (WebApp)
CREATE ROLE EWPORTAL_RW;
ALTER ROLE EWPORTAL_RW ADD MEMBER EWPORTAL_APP_RW;

-- Admin (DBA / ETL)
CREATE ROLE EWPORTAL_ADMIN_ROLE;
ALTER ROLE EWPORTAL_ADMIN_ROLE ADD MEMBER EWPORTAL_ADMIN;
```sql

4️⃣ **Permessi per Schema**

```sql
-- READ-ONLY
GRANT SELECT ON SCHEMA::REPORTING TO EWPORTAL_RO;
GRANT SELECT ON SCHEMA::BRONZE    TO EWPORTAL_RO;
GRANT SELECT ON SCHEMA::SILVER    TO EWPORTAL_RO;
GRANT SELECT ON SCHEMA::GOLD      TO EWPORTAL_RO;

-- READ-WRITE
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::PORTAL TO EWPORTAL_RW;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::BRONZE TO EWPORTAL_RW;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::SILVER TO EWPORTAL_RW;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::WORK   TO EWPORTAL_RW;
GRANT SELECT ON SCHEMA::GOLD TO EWPORTAL_RW;
GRANT SELECT ON SCHEMA::REPORTING TO EWPORTAL_RW;

-- FULL ADMIN
GRANT CONTROL ON SCHEMA::PORTAL    TO EWPORTAL_ADMIN_ROLE;
GRANT CONTROL ON SCHEMA::BRONZE    TO EWPORTAL_ADMIN_ROLE;
GRANT CONTROL ON SCHEMA::SILVER    TO EWPORTAL_ADMIN_ROLE;
GRANT CONTROL ON SCHEMA::GOLD      TO EWPORTAL_ADMIN_ROLE;
GRANT CONTROL ON SCHEMA::REPORTING TO EWPORTAL_ADMIN_ROLE;
GRANT CONTROL ON SCHEMA::WORK      TO EWPORTAL_ADMIN_ROLE;
```sql

📌 **Best practice**
*   **Nessun prefisso**: il DB è interamente dedicato a EasyWay Data Portal.
    
*   **Ruoli e permessi ben segregati** (WebApp, Reporting, Admin).
    
*   **Password complesse e uniche** per ogni login (da ruotare periodicamente).
    
*   Ogni cambiamento deve essere tracciato anche in documentazione di sicurezza aziendale.
    

* * *

🔑 **Audit & compliance**
-------------------------

*   L’assegnazione dei permessi deve essere tracciata anche nei log di change management.
    
*   I login devono essere monitorati tramite SQL Server Audit, Log Analytics o Azure Defender.



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?


## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.




