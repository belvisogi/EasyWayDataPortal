---
id: ew-easyway-webapp-02-logiche-easyway-logging-and-audit-readme
title: readme
summary: 'Documento su readme.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/reference, audience/dev, audience/ops, privacy/internal, language/it, logging, audit]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
# Checklist Operativa – Logging & Audit
EasyWay Data Portal

## Obiettivo
Garantire che tutti i servizi, microservizi, pipeline e infrastrutture rispettino policy di logging, auditing e compliance, minimizzando i rischi e facilitando troubleshooting e auditing normativo.

## Checklist Logging & Audit

| ID   | Policy/Controllo                                    | Azione da eseguire                                              | Obbligatorio | Note/Best Practice                                      | Stato  |
|------|-----------------------------------------------------|-----------------------------------------------------------------|--------------|---------------------------------------------------------|--------|
| 1    | Log centralizzato                                   | Tutti i log inviati a Log Analytics o `portal-audit` su Datalake| Sì           | Evitare file log sparsi o solo su disco locale           |        |
| 2    | Retention policy >=12 mesi (>=24 ACL/admin)         | Impostare retention minima 12 mesi (24 per security/admin)       | Sì           | Anche in ambiente DEV                                    |        |
| 3    | Alert automatici                                    | Attivare alert automatici su errori login, ACL, dati sensibili   | Sì           | Email/Teams/Monitor                                      |        |
| 4    | Audit trail su DB                                   | Abilitare SQL Audit/trigger su tabelle sensibili                 | Sì           | Anche accesso diretto a DB                               |        |
| 5    | Log masking                                         | Mascherare password, token, dati personali nei log               | Sì           | Mai loggare secret in chiaro                             |        |
| 6    | Log ETL/batch separati                              | Pipeline ETL scrivono log separati in `technical/`               | Sì           | Separare dai log funzionali                              |        |
| 7    | Notifica owner/admin eventi critici                  | Invio notifica su ACL, accesso admin, variazione config          | Sì           | Sempre notificare responsabile tenant/global             |        |
| 8    | Doc/README policy logging audit                     | Ogni script/template cita questa policy in README/doc            | Sì           | Policy sempre in evidenza per dev/team                   |        |
| 9    | Log compliance GDPR/SOC2/DORA                       | Loggati solo eventi previsti e con masking conforme              | Sì           | Seguire policy masking, no dati sensibili in chiaro      |        |
| 10   | Logging sempre attivo anche in test                  | Mai disabilitare logging neanche in DEV/test                     | Sì           | Catch incidenti prima del go-live                        |        |

---

## Template di commento/README da includere in ogni script/codice

> ⚠️ **Policy Logging & Audit EasyWay Data Portal:**  
> - Centralizza tutti i log su Log Analytics o cartella `portal-audit`
> - Maschera SEMPRE dati sensibili nei log  
> - Mantieni retention minima 12 mesi (24 per security/admin)  
> - Attiva alert automatici su eventi critici  
> - Documenta questa policy in ogni README/script/template

---

## Note operative

- Il rispetto di questa checklist è richiesto **anche per sviluppatori esterni, fornitori, o dev temporanei**
- Ogni pull request/cambio infrastruttura deve includere validazione di questa checklist
- In caso di dubbi, chiedere conferma a security/data owner o architetto progetto

---




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








