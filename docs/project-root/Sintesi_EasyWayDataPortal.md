# Sintesi — EasyWay Data Portal

## Descrizione Generale

EasyWay Data Portal è una piattaforma dati multi-tenant, API-first, progettata per essere estendibile, sicura e automatizzata. È pensata per la gestione avanzata di dati in contesti enterprise, con particolare attenzione a scalabilità, sicurezza e automazione.

## Architettura e Tecnologie

- **Cloud-native**: Basata su Azure (App Service, SQL, Blob Storage, Key Vault, App Insights)
- **Backend**: Node.js/TypeScript
- **Database**: Tutte le operazioni passano tramite stored procedure con auditing/logging centralizzato
- **CI/CD**: Pipeline Azure DevOps, provisioning automatico del database
- **Sicurezza**: Gestione segreti tramite Key Vault, rate limiting, validazione input, audit log

## Punti di Forza

- Architettura agentica e modulare, facilmente estendibile
- Automazione avanzata e orchestrazione tramite agenti
- Documentazione completa e onboarding guidato
- Approccio API-first e multi-tenant
- Best practice DevOps e cloud-native

## Componenti Principali

- **Orchestratore agentico**: Gestione processi tramite manifest.json, goals.json
- **Provisioning DB**: Script automatizzati per setup e migrazione database
- **Pipeline CI/CD**: Deploy automatizzato, smoke test, gestione segreti
- **Wiki e checklist**: Documentazione ricca, template, roadmap evolutiva

### Agenti principali

- **agent_datalake**: gestione operativa e compliance del Datalake (naming, ACL, retention, export log, audit)
- **agent_dba**: gestione migrazioni DB, drift check, documentazione ERD/SP, RLS rollout
- **agent_docs_review**: normalizzazione Wiki, indici/chunk, coerenza KB, supporto ricette
- **agent_governance**: quality gates, checklist pre-deploy, DB drift, KB consistency, generazione appsettings
- *(vedi cartella agents/ per l’elenco completo e dettagli)*

## Onboarding Rapido

1. Clona la repository
2. Installa le dipendenze Node.js in `portal-api/easyway-portal-api/`
3. Provisioning database tramite wrapper Flyway in `db/provisioning/` (human-in-the-loop)
4. Avvio locale: `npm run dev` nella cartella API
5. Consulta la documentazione e la Wiki per dettagli e best practice

---

Per ulteriori dettagli, consultare la documentazione ufficiale e la Wiki del progetto.
