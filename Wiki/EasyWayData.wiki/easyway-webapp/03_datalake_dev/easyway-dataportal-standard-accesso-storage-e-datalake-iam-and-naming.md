---
id: ew-datalake-standard
title: Standard Accesso Storage e Datalake (IAM & Naming)
summary: 'Documento su Standard Accesso Storage e Datalake (IAM & Naming).'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/datalake, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, policy-security, iam, naming, rbac]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
# 🗂️ EasyWay DataPortal - Standard Accesso Storage e Datalake (IAM & Naming)

## 🎯 Scopo del Documento
Definire le **linee guida ufficiali** per la gestione ordinata, sicura e scalabile degli accessi allo **Storage Account Blob** e al **Datalake Gen2** in EasyWay DataPortal, inclusi:
- Utenze di servizio
- Gruppi di accesso (RBAC)
- Naming convention
- Best practice operative

## 🔎 Differenza tra Blob Storage e Datalake HNS

| Nome Utenza               | Ambito               | Scopo principale        | Tipo di accesso        |
|----------------------------|----------------------|--------------------------|-------------------------|
| `portal.storage.*`         | Blob Storage (classico)| Assets, log, template    | RBAC (IAM)               |
| `portal.datalake.*`        | Datalake Gen2 (HNS)   | Tenant data, ETL, staging| RBAC + ACL POSIX (fine-grained) |

### 📂 Esempio struttura
```sql
ew-datalakedev/
├── tenant-xxxx/
│   ├── landing/
│   ├── staging/
│   ├── official/
│   └── invalidrows/
├── portal-assets/
├── portal-audit/
```sql

---

## 🏷️ Naming Convention - Utenze di Servizio

| Nome                       | Permessi                | Scopo             |
|-----------------------------|--------------------------|-------------------|
| `portal.datalake.easyway.read`   | Lettura                 | Interno EasyWay    |
| `portal.datalake.easyway.write`  | Scrittura               | Interno EasyWay    |
| `portal.datalake.vendorA.read`   | Lettura                 | Vendor A           |
| `portal.datalake.vendorA.write`  | Scrittura               | Vendor A           |
| `portal.storage.easyway.read`    | Lettura Blob Storage     | Interno EasyWay    |
| `admin.datalake`                 | Amministrazione Datalake | ACL, gestione dati |
| `admin.storage`                  | Amministrazione Storage  | IAM, risorse Azure |

---

## 🏷️ Naming Convention - Gruppi di Accesso (RBAC)

| Nome Gruppo                     | Ambito        | Permesso             |
|----------------------------------|---------------|-----------------------|
| `grp.portal.datalake.read`       | Datalake      | Lettura               |
| `grp.portal.datalake.write`      | Datalake      | Scrittura             |
| `grp.admin.datalake`             | Datalake      | Amministrazione       |
| `grp.portal.storage.read`        | Blob Storage  | Lettura               |
| `grp.admin.storage`              | Blob Storage  | Amministrazione       |

---

## 🔐 Assegnazione Ruoli Azure RBAC (IAM)

| Ambito     | Permesso    | Ruolo Azure                         |
|------------|-------------|--------------------------------------|
| Datalake   | Read        | `Storage Blob Data Reader`           |
| Datalake   | Write       | `Storage Blob Data Contributor`      |
| Datalake   | Admin       | `Storage Account Contributor`        |
| Blob       | Read        | `Storage Blob Data Reader`           |
| Blob       | Admin       | `Storage Account Contributor`        |

---

## 📑 Best Practice Operative

### ✅ 1. **Utenze di Servizio**
- Create sempre su **Microsoft Entra ID (Azure AD)**
- Separate per ambito (Datalake vs Storage)
- Nessuna licenza necessaria (solo IAM)

### ✅ 2. **Gruppi di Accesso**
- Nessun utente diretto, solo gruppi (principio Least Privilege)
- Naming `grp.*` sempre chiaro e coerente

### ✅ 3. **Permessi e Segregazione**
- RBAC su tutto lo Storage Account (IAM Azure)
- ACL POSIX per segregare accesso a cartelle tenant specifiche su Datalake

---

## 🔒 Esempio Accesso Vendor (Datalake ACL)
| Vendor    | Path consentito            | Permesso |
|-----------|-----------------------------|----------|
| Vendor A  | `/tenant-0001/landing`       | Read     |
| Vendor B  | `/tenant-0002/landing`       | Write    |

---

## 🚀 Suggerimento Automazione (futuro)
### Tool consigliati:
- **Terraform / Bicep / ARM Template** per creare:
  - Gruppi
  - Ruoli
  - Utenze
  - Policy ACL

### Esempio naming automatizzato:
```sql
az ad group create --display-name "grp.portal.datalake.read" --mail-nickname "grp.portal.datalake.read"
```sql

---

## 🛑 Regole Fondamentali (La Bibbia)
- Nessun accesso diretto a utenti umani su Storage Prod
- Tutto segregato tramite gruppi IAM e utenze tecniche
- Ogni utenza ha uno scopo preciso e limitato
- Audit sempre attivo su accessi e permessi
- Naming chiaro, immutabile nel tempo

---

## 🔔 Prossimi Step
- Formalizzare procedure operative (joiner/mover/leaver utenti e gruppi)
- Automatizzare provisioning (Terraform/Bicep)
- Standardizzare nelle policy ISO aziendali (ISO27001, GDPR, DORA)




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?







