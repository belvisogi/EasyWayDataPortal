---
id: ew-best-practice-naming-&-scalabilità
title: Best Practice Naming & Scalabilità
summary: 'Documento su Best Practice Naming & Scalabilità.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/docs, layer/reference, audience/dev, privacy/internal, language/it, best-practices, naming, scalability]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Reference|Reference]]

# Lookup – Best Practice Naming & Scalabilità

| Cosa vuoi                      | Cosa devi scrivere                 | Dammi il .md                              | Stato    |
|---------------------------------|------------------------------------|-------------------------------------------|----------|
| Tabella naming convention       | Dammi tabella naming convention    | Dammi il .md tabella naming convention    | IN BOZZA |
| Naming microservizi/container   | Dammi naming microservizi          | Dammi il .md naming microservizi          | IN BOZZA |
| Naming risorse Azure            | Dammi naming risorse Azure         | Dammi il .md naming risorse Azure         | IN BOZZA |
| Best practice scaling           | Dammi best practice scaling        | Dammi il .md best practice scaling        | IN BOZZA |
| Checklist naming/scalabilità    | Dammi checklist naming scaling     | Dammi il .md checklist naming scaling     | IN BOZZA |



Best Practice Naming & Scalabilità – EasyWay Data Portal

# Best Practice Naming & Scalabilità – EasyWay Data Portal

## Tabella Naming Convention (macro overview)

| Oggetto             | Esempio                               | Regola/Base                                   | Note Operative                            |
|---------------------|---------------------------------------|-----------------------------------------------|-------------------------------------------|
| Resource Group      | ew-rg-portal-dev                      | ew-rg-[modulo]-[env]                          | Un RG per ogni ambiente/app principale    |
| Storage Account     | ewdatalakedev                         | ew[datalake][env] (no caratteri speciali)     | Massimo 24 caratteri                      |
| App Service         | ew-app-portal-dev                     | ew-app-[modulo]-[env]                         | Unica entrypoint web/app per microservizi |
| Container/Microserv.| ew-user-mgmt-svc-dev                  | ew-[dominio]-svc-[env]                        | Nome breve, chiaro, dominio funzione      |
| Key Vault           | ew-kv-portal-dev                      | ew-kv-[modulo]-[env]                          | Un vault per ogni ambiente/app            |
| SQL DB              | easyway_portal_dev                    | easyway_portal_[env]                          | Senza trattini/breve/descrittivo          |
| Datalake Folder     | landing/, staging/, official/         | landing/, staging/, official/, ...            | Come da schema dati                       |
| API endpoint        | /api/users, /api/notifications        | /api/[dominio]                                | Seguire naming RESTful                    |
| Service Principal   | portal.datalake.read                  | [modulo].[ambito].[permesso]                  | Come da policy sicurezza                  |
| Slot Azure          | ew-app-portal-dev-slot                | ew-app-[modulo]-[env]-slot                    | Usare solo per test/blue-green            |

## Best Practice Scalabilità

- **Scalabilità orizzontale:**  
  Ogni microservizio/container va deployato per supportare scaling orizzontale (più istanze), anche in App Service Plan Basic.
- **No monoliti:**  
  Ogni dominio funzionale separato (user, notifiche, DQ, e-commerce…).
- **API Gateway unico:**  
  Tutte le chiamate passano da Gateway, che può scalare indipendentemente dai servizi.
- **Slot di staging/blue-green deploy:**  
  Usa slot per zero downtime deploy, rollback rapido, ambienti test/prod separati.
- **Resource group per ambiente:**  
  Un RG per dev, test, prod: facilita cleanup, governance e gestione costi.
- **Naming standard uniforme:**  
  Tutte le risorse devono seguire lo standard tabellare per evitare conflitti e automatizzare script/pipeline.

---

## Checklist Naming & Scalabilità

| ID   | Controllo                                | Obbligatorio | Note/Best Practice                                       | Stato  |
|------|------------------------------------------|--------------|----------------------------------------------------------|--------|
| 1    | Tutte le risorse seguono naming standard | Sì           | Consultare tabella naming prima di creare risorse        |        |
| 2    | Scaling microservizi/slot                | Sì           | Minimo 2 istanze per servizi core, usare slot per deploy |        |
| 3    | Un RG per ogni ambiente                  | Sì           | Facilita gestione costi/policy e clean-up                |        |
| 4    | Naming chiaro su API/endpoint            | Sì           | /api/[dominio], no ambiguità nei percorsi                |        |
| 5    | Service Principal chiari e segregati     | Sì           | Uno per dominio/permesso, niente permessi eccessivi      |        |
| 6    | Naming versionato in pipeline/script     | Sì           | Variabili/env/nome parametrici in ogni script            |        |

---

## Nota operativa

- **La tabella naming va aggiornata e consultata prima di creare qualunque risorsa, script o pipeline.**
- **Le pipeline di provisioning (IaC) devono sempre applicare queste regole.**
- **Eventuali eccezioni/naming legacy vanno documentate in README di progetto.**

---




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








