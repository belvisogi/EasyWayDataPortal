---
title: Database Architecture Master
chapter: 01
tags: [database, architettura, multi-tenant, ams, chatbot, conversational, portal, gold, bronze, rls, masking, stored-procedure, ndg, sequence, domain/db, layer/spec, audience/dev, audience/dba, privacy/internal, language/it]
source: easyway-webapp/01-database-architecture.md
id: ew-01-database-architecture
title: 01 database architecture
llm:
  pii: none
  include: true
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform---
# EasyWay Data Portal – Database Architecture Master

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
> **Conversational Intelligence & AMS ready**: tutte le procedure, tabelle, funzioni e documentazione sono progettate per essere governate anche via chatbot, automation, agent e AMS.
---

## ✅ Scopo del Documento

Questa “bibbia architetturale” raccoglie **tutti i principi, regole, policy e best practice** del database EasyWay Data Portal, orientati anche all’automazione e al dialogo con bot/agent (Conversational Intelligence).
**Ogni oggetto tecnico (DDL, funzioni, sequence, store, ecc.) è sempre documentato in file `.md` dedicati e linkati da questo documento.**

---

## 👾 Conversational Intelligence & AMS Ready — Principi Base

- **Tutto è progettato per essere gestito anche da chatbot, agent, AMS, LLM e API automatiche** (non solo da DBA/operatori umani).
- **Ogni store process e funzione**:
    - Parametri chiari e documentati
    - Logging centralizzato su STATS_EXECUTION_LOG e LOG_AUDIT
    - Output strutturato e standard (OK/KO, ID, messaggio, ...), facilmente parsabile da bot o strumenti di monitoring
    - Esempi di prompt e output nei .md tecnici
- **Ogni oggetto di database** ha naming self-explained, descrizione extended property e audit.
- **Tutto è sempre testabile, monitorabile e riusabile via automation**.

---

## 📂 Schemi Database Principali

| Schema      | Scopo                              |
|-------------|------------------------------------|
| `PORTAL`    | Anagrafiche, ACL, tenant, ruoli, NDG, surrogate key, mascheramento, sequence, store |
| `BRONZE`    | Dati raw (staging tecnico)         |
| `SILVER`    | Dati validati e puliti             |
| `GOLD`      | Dati business-ready, RLS, auditing |
| `REPORTING` | Viste consolidate per BI           |
| `WORK`      | Area tecnica temporanea            |

---

## 🚩 Policy & Principi Architetturali

- Surrogate key INT (`id`) + NDG alfanumerica univoca su tutte le anagrafiche principali
- **PORTAL**: PK, FK, relazioni hard sempre obbligatorie
- **Altri schema**: FK fisiche solo se serve, logica documentata
- Campi tecnici sempre: `created_by`, `created_at`, `updated_at`, `ext_attributes`
- Sequence, function e store procedure sempre in doppia versione: PROD e DEBUG
- Mascheramento e RLS sempre previsti dove serve
- Login federata e password hashata obbligatorie per sicurezza
- **Tutto deve essere gestibile, loggabile, richiamabile da bot/chatbot/agent/AMS**
- Output strutturato in tutte le store process di business/AMS
- Documentazione e prompt di esempio per ogni oggetto
- **Ogni evoluzione architetturale va prima discussa e documentata qui**

---

## 🗂️ Struttura della documentazione tecnica

Per ogni area/oggetto di database, trovi qui il link al relativo `.md` tecnico dettagliato.

### **PORTAL**
Tabelle, PK/FK, NDG, sequence, policy, convenzioni

### **GOLD**
Business, reporting, auditing, RLS

### **STORE PROCEDURE**
Onboarding, test, ACL, automation


### **SEQUENCE**
Numeratori e gestione codici NDG (prod + debug)


### **FUNZIONI**
Funzioni di supporto (generazione NDG, masking, RLS)


### **EXCEL**
Export documentale per audit o tool di data modeling

### **dbdiagram.io**
Modello visuale sempre aggiornato per import/export ERD
- https://dbdiagram.io/d/687cf3b9f413ba3508bd95c0

### **SETUP**
- [DB-SETUP](./01_database_architecture/01a-db-setup.md)

---

## 📑 Convenzioni e comandi di progetto

| Cosa vuoi                     | Cosa devi scrivere               | Dammi il `.md`                    |
|-------------------------------|----------------------------------|------------------------------------|
| Script setup                  | `Dammi lo script SETUP`          | `Dammi il .md SETUP`               |
| Script PORTAL                 | `Dammi lo script PORTAL`         | `Dammi il .md PORTAL`              |
| Script GOLD (ecc.)            | `Dammi lo script GOLD`           | `Dammi il .md GOLD`                |
| Export dbdiagram.io           | `Export for dbdiagram.io`        | `Dammi il .md dbdiagram.io`        |
| Excel documentale             | `Genera documentale Excel`       | `Dammi il .md Excel`               |
| Script store procedure        | `Dammi lo script STOREPROCESS`   | `Dammi il .md STOREPROCESS`        |
| Script sequence               | `Dammi lo script SEQUENCE`       | `Dammi il .md SEQUENCE`            |
| Script funzione               | `Dammi lo script FUNZIONE`       | `Dammi il .md FUNZIONE`            |

---

## 📝 Linee guida operative

- Ogni nuovo oggetto tecnico, policy, convenzione, decisione va **sempre prima documentata qui**.
- I `.md` tecnici sono linkati e devono essere aggiornati a ogni evoluzione.
- Le modifiche devono essere validate e condivise prima della messa in produzione.
- **Questa Architecture Master è il riferimento vincolante per sviluppatori, DBA, revisori, auditor, project owner e… chatbot/agent di AMS!**

---

### 👾 Conversational Intelligence Checklist
Per ogni oggetto:  
- [ ] Documentazione con prompt di esempio
- [ ] Output standardizzato (resultset: stato, id, messaggio, etc.)
- [ ] Logging su tutte le operazioni
- [ ] Parametri chiari, self-explained
- [ ] Versione DEBUG/test sempre presente
- [ ] Extended property su ogni campo chiave

---



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








