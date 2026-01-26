---
id: ew-logging-audit
title: Logging & Audit
summary: 'Documento su Logging & Audit.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [policy-logging, domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, logging, audit]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[Home](../../../../docs/project-root/DEVELOPER_START_HERE.md) > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

# Logging & Audit – EasyWay Data Portal

## Lookup Logging & Audit – Microservizi & API Gateway

| Cosa vuoi                   | Cosa devi scrivere                 | Dammi il .md                          | Stato    |
|-----------------------------|------------------------------------|---------------------------------------|----------|
| Overview logging & audit    | Dammi overview logging audit       | Dammi il .md overview logging audit   | IN BOZZA |
| Tabella eventi da tracciare | Dammi tabella eventi audit         | Dammi il .md tabella eventi audit     | IN BOZZA |
| Best practice monitoring    | Dammi best practice monitoring     | Dammi il .md best practice monitoring | IN BOZZA |
| Esempio flusso log/audit    | Dammi esempio flusso audit         | Dammi il .md esempio flusso audit     | IN BOZZA |

## Tabella Eventi/Audit da Tracciare

| Ambito                   | Evento/Azione da tracciare                         | Dove si traccia         | Livello Criticità | Retention Policy     | Note Operative                                   |
|--------------------------|----------------------------------------------------|-------------------------|-------------------|----------------------|--------------------------------------------------|
| Login                    | Successo, errore, tentativi anomali                | API Gateway, Auth Svc   | Alto              | 12 mesi (min)        | Alert su 5+ tentativi falliti da stesso IP/user  |
| Accesso dati sensibili   | Query, export, download, mascheramento             | Microservizi, DB        | Alto              | 12 mesi (min)        | Masking attivo, log dettagliato                  |
| Modifica ACL/permessi    | Cambio ruolo, aggiunta/rimozione accessi           | User Mgmt, DB           | Alto              | 24 mesi (min)        | Alert a owner tenant/admin                       |
| Modifica configurazioni  | Cambi su parametri, segreti, environment           | Config Svc, Key Vault   | Medio             | 12 mesi (min)        | Notifica automatica se variazione critica        |
| Flusso onboarding        | Creazione utente, validazione, rifiuto             | User Mgmt, Notifiche    | Medio             | 6 mesi               | Log workflow step by step                        |
| Job ETL / Pipeline dati  | Avvio, successo, errore, righe scartate            | Data Quality, ETL Svc   | Alto/Medio        | 12 mesi              | Log su portal-audit e technical storage          |
| Accesso amministrativo   | Login admin, accesso via SSH/CLI/Portal            | Portal, Storage, DB     | Alto              | 24 mesi              | Accesso consentito solo a identity approvate     |
| Anomalie e alert         | Rilevazione attività anomale, superamento soglie   | Tutti i servizi         | Alto              | 24 mesi              | Alert automatico via email/Teams                 |

---

## Best Practice Monitoring & Audit

- **Log centralizzato**: tutti i log vanno su Log Analytics (Azure) o su una cartella dedicata (`portal-audit`) nello storage Datalake.
- **Retention policy**: minima di 12 mesi (24 mesi per ACL/permessi/amministrazione).
- **Alert automatici**: attivati su pattern anomali, errori di login, cambi ACL, accesso a dati sensibili.
- **Log masking**: mai salvare password/token; mascherare dati sensibili anche nei log.
- **Audit trail DB**: usare funzioni native (SQL Server Audit, triggers) per tracciare accessi e modifiche critiche.
- **Notifica owner/admin**: ogni modifica ACL, accesso admin o variazione parametri critici notifica i responsabili tenant e/o owner globale.

---

## Esempio di Flusso Audit (testuale)

[Utente] → [API Gateway] → [Microservizio] → [DB/Storage]  
|  
v  
[Logging/Audit centralizzato: evento, user_id, tenant_id, timestamp, dettaglio, outcome]  
|  
+--> [Alert se evento critico/anomalia]  
+--> [Retention e archiviazione audit trail]



---

> **Nota**: Tutte le policy di logging & audit sono “PRONTE PER CODICE” dopo validazione e saranno recepite in ogni script, template e implementazione.




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?










