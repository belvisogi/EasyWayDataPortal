---
id: ew-04-accesso-registrazione-notifiche
title: 04 accesso registrazione notifiche
summary: Flussi di Accesso, Registrazione, Onboarding Microservizi e sistema di Notifiche.
status: active
owner: team-docs
created: '2025-01-01'
updated: '2026-01-16'
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, onboarding, notifications, security]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: Implementare flow DQ.
type: guide
---
[Home](./start-here.md) >  > 

# EasyWay Data Portal - Documentazione Funzionale Completa

  

## 1️⃣ Obiettivo

EasyWay Data Portal garantisce un accesso sicuro e scalabile tramite **Microsoft Entra ID** (opzionale), assegnando fin dalla registrazione un **codice cliente (cod_cli)** anche ai prospect.

Il sistema è progettato per gestire utenti e tenant in modo isolato e sicuro, tramite il campo **tenant_id**.

L'infrastruttura è pensata per SaaS: un solo DB, più clienti, ACL e ruoli.

  

Il portale gestisce anche:

- Notifiche utente

- Integrazioni API esterne (Shopify, Amazon, Fatture in Cloud)

- Estensione futura verso flussi di Data Quality.

  

## 2️⃣ Flusso Registrazione e Accesso Utente

  

### Sequenza generale:

1. L’utente si registra con email (UPN Entra ID o normale email)

2. Il portale verifica via Microsoft Graph API se l’utente esiste in Entra ID (se previsto)

3. Se assente → crea utente su Entra ID (opzionale)

4. Genera `cod_cli` e `tenant_id` su SQL Server

5. Inserisce il nuovo utente nel database `users` associandolo a `tenant_id`

6. L’utente accede tramite OAuth2 (Entra ID) o login locale

  

### Schema semplificato - Registrazione e Accesso

```sql

[User Browser]

     │

     │─ Registrazione Email ─────┐

     │                           │

     ▼                           ▼

[Portale Backend] ─ Check Entra ID ─► [Microsoft Graph API]

     │                               │

     ├─ Genera cod_cli e tenant_id   │

     ├─ Scrive in tabella `users`    │

     │                               │

     └─ Login tramite EntraID OIDC ◄─┘

```sql

  

## 3️⃣ Architettura Generale del Portale (Microservizi / Container)

```sql

[Browser]

   │

   ▼

[Portal]

   │

   ▼

[API Gateway]

   ├──► [Auth Service] ──► [ACL, Tenant Validation]

   │       │

   │       └──► [Admin Service]

   │

   ├──► [Viewer App]

   ├──► [Scheduler]

   ├──► [Upload Service]

   ├──► [Import Service]

   ├──► [Enrichment API]

   └──► [Dashboard Service]

```sql

  

## 4️⃣ Database - SQL Server

  

### Tabelle principali:

  

**users:**

- tenant_id

- cod_cli

- email

- stato

- notify_by_email

  

**user_notification_settings:**

- tenant_id

- cod_cli

- channel (EMAIL, SMS, PUSH)

- enabled

  

## 5️⃣ Gestione Notifiche

  

**Livello Generale:**

- notify_by_email TRUE/FALSE

  

**Livello Dettaglio:**

- user_notification_settings per canale

  

**Priorità invio:**

1. notify_by_email = 0 → blocca

2. Se EMAIL ON in override → invia

3. Se non override → applica flag generale

  

## 6️⃣ Integrazione API esterne (Microsoft Graph, Shopify, Amazon, ecc.)

  

### Esempi API Graph:

```sql

GET /v1.0/users?$filter=userPrincipalName eq 'user@domain.com'

POST /v1.0/users { user data ... }

```sql

  

## 7️⃣ Gestione ACL, Tenant e Sicurezza

**Accesso:**

- JWT con tenant_id, ACL

  

**Segregazione dati:**

- WHERE tenant_id = ?

  

**ACL:**

- Tabella user_access

  

**Ruoli:**

- Viewer, Scheduler, Admin, Enrichment

  

## 8️⃣ Estensione Futuro: Data Quality Flow

**Flussi futuri:**

- Upload (Excel, CSV, JSON)

- Quality: Completezza, Formati, Business Rules

- Report anomaly & fix

  

## 9️⃣ Deployment e Tecnologie

**Componenti:**

- Frontend Docker Azure Web App

- Backend Docker Azure Web App

- DB Azure SQL (esterno)

  

## 🔑 Tenant vs Microsoft Entra ID

| Nome       | Funzione                          | Dove vive  |

|------------|----------------------------------|------------|

| tenant_id  | Isolamento logico DB               | SQL Azure  |

| Entra ID   | Federazione accessi                | Microsoft  |

  

Entrambi convivono senza conflitti.


## Domande a cui risponde
1. Qual è il flusso di registrazione di un nuovo utente?
2. Qual è la differenza tra `tenant_id` (SQL) e Entra ID?
3. Come funziona la priorità delle notifiche (email vs settings)?











