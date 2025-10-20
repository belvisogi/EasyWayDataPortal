---
id: ew-portal
title: portal
summary: 
owner: 
tags:
  - 
  - privacy/internal
  - language/it
llm:
  include: true
  pii: 
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---
# EasyWay Data Portal – PORTAL.md

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).

---

## ✅ Scopo del file

Questo documento descrive tutte le tabelle anagrafiche, di ACL, di configurazione e di subscription dello schema `PORTAL` di EasyWay Data Portal, secondo le best practice multi-tenant SaaS.

---

## 📋 **Riepilogo tabelle principali schema PORTAL**

| Tabella                    | Scopo/Funzione                                      | Note Chiave                              |
|----------------------------|-----------------------------------------------------|-------------------------------------------|
| TENANT                     | Anagrafica clienti/tenant SaaS                      | Un tenant = un’azienda o cliente          |
| SUBSCRIPTION               | Stato abbonamento, scadenze, pagamenti              | Stripe/PayPal/Nexi, nessun dato carta     |
| PROFILE_DOMAINS            | Profili/ruoli utente (ACL, permessi)                | Gestione ruoli e autorizzazioni           |
| USERS                      | Utenti registrati (multi-tenant, NDG)               | Login locale/federato, tenant_id, ACL     |
| SECTION_ACCESS             | Accesso sezioni portale per tenant                  | Sostenibilità, Data Quality, Ecommerce    |
| USER_NOTIFICATION_SETTINGS | Preferenze di notifica utente                       | Email, alert, digest                      |
| MASKING_METADATA           | Colonne soggette a mascheramento dati sensibili     | Compliance GDPR/SOC2, metadata masking    |
| RLS_METADATA               | Row-Level Security, filtri per tenant su tabelle    | Sicurezza, filtri multi-tenant            |
| CONFIGURATION              | Parametri, flag, chiavi, feature toggle             | Override per tenant/globali, API config   |

---

### 1️⃣ **Tenant (Cliente)**

> **Gestisce tutte le aziende/tenant che accedono alla piattaforma EasyWay.  
Ogni record corrisponde a un cliente (azienda, organizzazione, partita IVA, ecc).  
Il campo `plan_code` definisce il piano commerciale attivo (BASE, BRONZE, SILVER, GOLD).  
Contiene estensioni custom JSON per dati aggiuntivi.**

```sql
-- Anagrafica Tenant (Cliente/azienda)
CREATE TABLE PORTAL.TENANT (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL UNIQUE,      -- Codice NDG es. TEN00000001000
    name NVARCHAR(255) NOT NULL,                 -- Ragione sociale/nome visualizzato
    plan_code NVARCHAR(50) NOT NULL,             -- BASE, BRONZE, SILVER, GOLD
    ext_attributes NVARCHAR(MAX),                -- Estensioni JSON custom
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
```sql

### 2️⃣ **Abbonamenti / Subscription**
Tiene traccia degli abbonamenti attivi, delle scadenze, e del provider di pagamento esterno (Stripe, PayPal, Nexi).  
Mai salvare dati carta, solo ID/token transazione!  
Permette logica di rinnovo, scadenza, upgrade/downgrade piani.

```sql
-- Gestione abbonamenti, scadenze, stato pagamento
CREATE TABLE PORTAL.SUBSCRIPTION (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,                 -- FK PORTAL.TENANT.tenant_id
    plan_code NVARCHAR(50) NOT NULL,                 -- Piano commerciale scelto
    status NVARCHAR(50) NOT NULL,                    -- ACTIVE, EXPIRED, SUSPENDED, ecc.
    start_date DATETIME2 NOT NULL,
    end_date DATETIME2 NOT NULL,
    external_payment_id NVARCHAR(100),               -- ID Stripe/PayPal/Nexi
    payment_provider NVARCHAR(50),                   -- Stripe, PayPal, Nexi, ecc.
    last_payment_date DATETIME2,
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id)
);
```sql

### 3️⃣ **Profili utente (ACL)**
Elenco dei profili ACL/ruoli disponibili nel portale.  
Ogni utente avrà un profilo associato (es: TENANT_ADMIN, VIEWER, SCHEDULER).  
Le descrizioni e le estensioni JSON permettono di personalizzare permessi e visibilità.

```SQL
-- Domini di profilo ACL
CREATE TABLE PORTAL.PROFILE_DOMAINS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    profile_code NVARCHAR(50) NOT NULL UNIQUE,        -- Es. TENANT_ADMIN, VIEWER
    description NVARCHAR(255),
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
```sql

### 4️⃣ **Anagrafica Utenti**
Tutti gli utenti abilitati al portale, con login locale o federato (Microsoft, Google, SAML, ecc).  
Include info su ACL, stato, e dati anagrafici minimi.  
Nessuna password in chiaro, solo hash lato app.

```SQL
-- Utenti multi-tenant
CREATE TABLE PORTAL.USERS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(50) NOT NULL UNIQUE,             -- Codice NDG es. CDI00000001000
    tenant_id NVARCHAR(50) NOT NULL,                  -- FK PORTAL.TENANT.tenant_id
    email NVARCHAR(255) NOT NULL,
    name NVARCHAR(100),
    surname NVARCHAR(100),
    password NVARCHAR(255),                           -- Password hashata (NULL se federato)
    provider NVARCHAR(50),                            -- Provider federato, NULL=locale
    provider_user_id NVARCHAR(255),
    status NVARCHAR(50),
    profile_code NVARCHAR(50) NOT NULL,               -- FK PROFILE_DOMAINS
    is_tenant_admin BIT,
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id),
    FOREIGN KEY (profile_code) REFERENCES PORTAL.PROFILE_DOMAINS(profile_code)
);
```sql

### 5️⃣ **Accesso sezioni Portale**
Gestione dell’abilitazione/disabilitazione di specifiche sezioni (Sostenibilità, Data Quality, Ecommerce, ecc.) per ogni tenant.  
Permette la visibilità granulare delle funzioni offerte a ciascun cliente.

```SQL
-- Gestione abilitazione sezioni portale per tenant
CREATE TABLE PORTAL.SECTION_ACCESS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,              -- FK PORTAL.TENANT.tenant_id
    section_code NVARCHAR(50),                    -- Es. SOSTENIBILITA, DATAQUALITY
    is_enabled BIT,
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id)
);
```sql

## 5️⃣ **Accesso sezioni Portale** (Policy Section Access custom)

Gestione avanzata e flessibile di quali sezioni/funzionalità (Sostenibilità, Data Quality, Ecommerce, ecc.)  
sono abilitate/disabilitate per ogni tenant, profilo ACL, o singolo utente, con supporto per accessi temporanei, permessi premium, override granulari.

**La tabella PORTAL.SECTION_ACCESS consente policy custom con questa logica:**

### 📑 **Tabellina campi chiave**
| Campo        | Uso/Funzione                                    | Note                                  |
|--------------|-------------------------------------------------|---------------------------------------|
| tenant_id    | Tenant destinatario della policy                | FK obbligatoria                       |
| section_code | Codice sezione (es. SOSTENIBILITA, ECOMMERCE)   |                                       |
| profile_code | (opzionale) Profilo ACL per granularità         | Per controllare su ruoli specifici     |
| user_id      | (opzionale) Utente specifico per override       | Per abilitare/disabilitare singolo     |
| is_enabled   | Flag abilitazione/disabilitazione               | 1 = abilitato, 0 = disabilitato        |
| valid_from/to| Periodo validità policy (accesso temporaneo)    | Per “feature a scadenza”               |
| ext_attributes| JSON con permessi extra, note, motivazioni     | Audit, motivazioni override, tag       |

### 🏗️ **DDL con estensioni**
```sql
CREATE TABLE PORTAL.SECTION_ACCESS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,              -- FK PORTAL.TENANT.tenant_id
    section_code NVARCHAR(50),                    -- Es: SOSTENIBILITA, DATAQUALITY, ECOMMERCE
    profile_code NVARCHAR(50) NULL,               -- (opzionale) FK PROFILE_DOMAINS per granularità su profilo
    user_id NVARCHAR(50) NULL,                    -- (opzionale) FK USERS per override singolo utente
    is_enabled BIT,                               -- Flag attiva/disattiva
    valid_from DATETIME2 NULL,                    -- Periodo di validità (custom access temporanei)
    valid_to DATETIME2 NULL,
    ext_attributes NVARCHAR(MAX),                 -- Campi custom (es. JSON con note o permessi extra)
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id)
    -- FK opzionali su profile_code, user_id se vuoi enforcement SQL
);
```sql
Esempi pratici di policy custom:
| tenant_id | section_code | profile_code | user_id | is_enabled | valid_from | valid_to | ext_attributes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TEN0000000100 | SOSTENIBILITA | NULL | NULL | 1 | NULL | NULL | NULL |
| TEN0000000100 | ECOMMERCE | VIEWER | NULL | 0 | NULL | NULL | NULL |
| TEN0000000101 | DATAQUALITY | NULL | CDI0000002 | 1 | 2025-01-01 | 2025-12-31 | {"note":"accesso premium"} |


**Best practice:**
*   Usa ext_attributes per motivazioni di override, permessi temporanei, note audit
    
*   Audit ogni modifica tramite LOG_AUDIT
    
*   Mantieni la granularità solo dove necessario (tenant > profilo > utente > periodo > custom)
    
*   Struttura sempre pronta a essere estesa per nuove sezioni/funzioni
### 6️⃣ **Preferenze Notifica Utente**

Configurazione delle preferenze di notifica per ogni utente (upload, alert, digest).  
La tabella permette la gestione avanzata di notifiche personalizzate per utente/tenant.

```SQL
-- Preferenze notifica granulari per utente
CREATE TABLE PORTAL.USER_NOTIFICATION_SETTINGS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50) NOT NULL,                  -- FK PORTAL.TENANT.tenant_id
    user_id NVARCHAR(50) NOT NULL,                    -- FK PORTAL.USERS.user_id
    notify_on_upload BIT,
    notify_on_alert BIT,
    notify_on_digest BIT,
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    FOREIGN KEY (tenant_id) REFERENCES PORTAL.TENANT(tenant_id),
    FOREIGN KEY (user_id) REFERENCES PORTAL.USERS(user_id)
);
```sql

### 7️⃣ **Mascheramento dati sensibili (GDPR, SOC2, ISO27001, DORA)**
Registra tutte le colonne soggette a mascheramento (Dynamic Data Masking),  
con regole, note e dettagli per compliance e audit.  
Usata da funzioni e policy di sicurezza.

```SQL
-- Metadata colonne da mascherare (GDPR/SOC2)
CREATE TABLE PORTAL.MASKING_METADATA (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50),                         -- NULL = globale, valorizzato = per tenant
    schema_name NVARCHAR(50),
    table_name NVARCHAR(100),
    column_name NVARCHAR(100),
    mask_type NVARCHAR(50),
    note NVARCHAR(255),
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
```sql

### 8️⃣ **Row-Level Security (RLS) Metadata**
Traccia le policy di Row-Level Security applicate alle tabelle per filtraggio automatico  
sui dati per tenant, garantendo isolamento dati, sicurezza multi-tenant, auditing.
```SQL
-- Metadata Row-Level Security
CREATE TABLE PORTAL.RLS_METADATA (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50),                         -- NULL = globale, valorizzato = per tenant
    schema_name NVARCHAR(50),
    table_name NVARCHAR(100),
    column_name NVARCHAR(100),
    policy_name NVARCHAR(100),
    predicate_function NVARCHAR(255),
    note NVARCHAR(255),
    ext_attributes NVARCHAR(MAX),
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
```sql

### 9️⃣ **Configurazione globale/tenant**
Gestione centralizzata dei parametri di configurazione della piattaforma,  
flag, feature toggle, chiavi API, limiti, soglie, override per tenant e parametri globali.  
Estensibile e auditabile.

```SQL
-- Parametri di configurazione e flag globali/per-tenant
CREATE TABLE PORTAL.CONFIGURATION (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tenant_id NVARCHAR(50),                              -- NULL = globale, valorizzato = per tenant
    config_key NVARCHAR(100) NOT NULL,
    config_value NVARCHAR(MAX) NOT NULL,
    description NVARCHAR(255),
    is_active BIT DEFAULT 1,
    created_by NVARCHAR(255),
    created_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    UNIQUE (tenant_id, config_key)
);
```sql

📝 **Best practice & note operative**
-------------------------------------

*   Ogni tabella preceduta da commento descrittivo
    
*   Tabellina riepilogativa delle tabelle all’inizio della sezione
    
*   PK/FK obbligatorie in tutte le anagrafiche principali
    
*   Surrogate key INT (`id`) + chiave NDG (`tenant_id`, `user_id`) sempre
    
*   `ext_attributes` come JSON per campi custom per tenant/utente
    
*   NO dati sensibili (carta, CVC, ecc.) in alcuna tabella: solo ID/token forniti da provider
    
*   Audit e compliance: tutti i cambiamenti devono essere tracciati
    
*   Configurazione: parametri e flag in PORTAL.CONFIGURATION, override per tenant
    
*   Abbonamento: stato abilitato/disabilitato sempre verificato via SUBSCRIPTION



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

