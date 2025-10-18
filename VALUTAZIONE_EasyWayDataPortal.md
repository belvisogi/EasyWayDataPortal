# Valutazione EasyWayDataPortal — Gap, Rischi e Piano di Allineamento

## Contesto e Obiettivo
- Obiettivo: fotografare lo stato attuale (API/DB/Wiki), evidenziare i punti da sistemare e proporre un piano d’azione concreto e prioritizzato per portare EasyWay Data Portal in linea con gli standard documentati.
- Scope: repository `EasyWayDataPortal` (root), modulo `EasyWay-DataPortal/easyway-portal-api` (API), cartella `DataBase` (DDL e SP), Wiki `Wiki/EasyWayData.wiki`.

## Fonti analizzate
- API: `EasyWay-DataPortal/easyway-portal-api/src/...`
- DDL: `DataBase/DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql`, `DataBase/DDL_EASYWAY_DATAPORTAL.sql`
- SP (documentazione): `Wiki/EasyWayData.wiki/.../PORTAL/programmability/stored-procedure.md`
- Endpoint docs: `Wiki/EasyWayData.wiki/.../easyway_portal_api/ENDPOINT/*.md`

## Sintesi Esecutiva
- Architettura API solida (Express/TS, middleware `X-Tenant-Id`, validazione Zod, routing per domini).
- Disallineamento importante tra codice e DDL/linee guida Wiki per Users e Config (nomi colonne, direct DML vs. SP). Questo blocca l’aderenza al modello EasyWay (auditing/logging unificati) e può rompere le query su DB aggiornati.
- Alcune incoerenze minori (route duplicate, stub mancanti) e necessità di consolidare i DDL.
- Azioni prioritarie: (1) Users via SP e mapping colonne allineato al DDL; (2) correzione Config loader; (3) fix Notifications; (4) implementare/stub per query da Blob; (5) single source of truth per DDL; (6) definire strategia test e pipeline.

## Dettagli — Gap e Fix Proposti
1) Users — allineamento schema e SP (PRIORITARIO)
   - Problema: le query locali usano colonne `display_name`, `profile_id`, `is_active` non presenti nel DDL standard (`name`, `surname`, `profile_code`, `status`, `is_tenant_admin`, …).
   - Problema: UPDATE/SELECT diretti dalla API su `PORTAL.USERS`; la Wiki impone uso esclusivo di Store Procedure per DML (auditing/logging centralizzati).
   - Fix:
     - Introdurre SP coerenti (esempi: `PORTAL.sp_list_users_by_tenant`, `PORTAL.sp_update_user`, `PORTAL.sp_soft_delete_user`) con logging su `PORTAL.STATS_EXECUTION_LOG`.
     - Aggiornare controller `usersController` per invocare SP (via `.execute`) e adeguare i payload a `name/surname/profile_code/status` o definire un mapping chiaro da `display_name/profile_id`.
     - Aggiornare validator Zod coerentemente.

2) Config loader — colonna e filtro (PRIORITARIO)
   - Problema: `loadDbConfig` filtra su `enabled = 1` e `section`, ma il DDL usa `is_active` e non definisce `section`.
   - Fix: usare `is_active = 1`. Gestire `section` solo se introdotta nel modello (con DDL relativo), altrimenti rimuovere il filtro.

3) Notifications — route duplicate e placeholder (ALTA)
   - Problema: route `POST /subscribe` registrata più volte; import ridondanti; controller placeholder.
   - Fix: consolidare in un’unica route. Implementare una SP dedicata a registrare preferenze/subscribe e chiamarla dalla API. Aggiornare validator se necessario.

4) Query via Blob — funzione mancante (MEDIA)
   - Problema: `loadQueryWithFallback` importa `loadSqlQueryFromBlob`, ma `src/config/queryLoader.ts` è vuoto.
   - Fix: implementare stub chiaro (lancia “not configured”) o feature flag che salti la chiamata a Blob quando non configurato. In seguito integrare con Azure Blob Storage.

5) DDL duplicati/obsoleti — single source of truth (MEDIA)
   - Problema: coesistenza di un DDL “vecchio” (`DDL_EASYWAY_DATAPORTAL.sql`) e di un DDL standard aggiornato (`DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql`).
   - Fix: dichiarare ufficiale il DDL standard; marcare l’altro come deprecato o rimuoverlo; allineare Wiki se necessario.

6) Logging/Auditing — aderenza a STATS_EXECUTION_LOG (MEDIA)
   - Problema: se si usano DML diretti via API, si perde il logging standard previsto dalle SP.
   - Fix: centralizzare tutte le mutazioni su SP che scrivono sempre su `PORTAL.STATS_EXECUTION_LOG`. In API aggiungere correlation-id/header per tracing (già in parte presente nel controller di onboarding). 

7) Security & Config (MEDIA)
   - .env: migrare segreti su Azure Key Vault; caricarli via Managed Identity o pipeline.
   - Hardening del middleware `tenant`: prevedere validazione/normalizzazione del tenant, antifrode (limiti rate per tenant), e autenticazione/identità (Entra ID/AD B2C) in fase successiva.

8) CI/CD & Qualità (MEDIA)
   - Aggiungere pipeline Azure DevOps/GitHub Actions: build, lint, test, deploy su slot/stage.
   - Introdurre test minimi (REST Client/Jest) e check DB drift (migrazioni/validatore schema).

9) Documentazione & Struttura repository (MEDIA)
   - Doppia denominazione `EasyWayDataPortal` (root) vs `EasyWay-DataPortal` (modulo): fonte di confusione.
   - Fix proposto: rinominare `EasyWay-DataPortal` in `portal-api` o `easyway-portal-api` a livello monorepo. Mantenere `EasyWayDataPortal` come “contenitore” di cosa/come/perché (Wiki/DB/docs/infra).

## Piano d’Azione (Priorità e Sequenza)
1. Users via SP + mapping colonne coerente con DDL (blocca errori funzionali)
2. Correzione `loadDbConfig` su `is_active` e rimozione/gestione `section`
3. Pulizia Notifications (route duplicate) e SP per subscribe/notifiche
4. Implementare/stub `loadSqlQueryFromBlob` (feature flag)
5. Consolidare DDL (ufficiale vs deprecato) e aggiornare riferimenti Wiki
6. Pipeline CI/CD con lint/test/build e variabili sicure da Key Vault
7. Hardening sicurezza (auth/Entra ID, rate limit per tenant, correlation id)

## Impatti su file (indicativi)
- API Users: `easyway-portal-api/src/controllers/usersController.ts:1`
- Query locali (da dismettere a favore SP): `easyway-portal-api/src/queries/*.sql:1`
- Validators: `easyway-portal-api/src/validators/userValidator.ts:1`
- Config loader: `easyway-portal-api/src/config/dbConfigLoader.ts:1`
- Notifications routes: `easyway-portal-api/src/routes/notifications.ts:1`
- Query loader Blob: `easyway-portal-api/src/config/queryLoader.ts:1`
- DDL ufficiale: `DataBase/DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql:1`

## Rinomina cartelle (proposta)
- Rinominare `EasyWay-DataPortal` in `portal-api` (o `easyway-portal-api`).
- Mantenere `EasyWayDataPortal` come monorepo con: `portal-api/`, `DataBase/`, `Wiki/`, `docs/`, `tests/`.
- Eseguire rinomina in una PR dedicata per minimizzare impatti.

## Test — Strategia iniziale
- Aggiunta cartella `tests/` (root) per centralizzare: 
  - REST Client `.http` per smoke/integration manuali.
  - In prospettiva: Jest integrazione (mocks DB o ambiente test), collezioni Postman, e test DB su SP critiche.
- Vedi `tests/README.md:1` per dettagli.

## Infrastruttura Azure (nota)
- Allegato documento con nota architetturale e prerequisiti: `docs/infra/azure-architecture.md:1`.
- Servizi chiave: Azure App Service, Azure SQL, Storage (Blob), Key Vault, App Configuration (opzionale), Application Insights, Entra ID/AD B2C, Pipelines.

---

### Rischi se non si interviene
- Query Users non compatibili con DDL standard → errori runtime.
- Assenza logging centralizzato (se DML diretti) → audit e troubleshooting deboli.
- Config non letta correttamente (enabled vs is_active) → comportamenti inattesi.
- Route duplicate → bug difficili da diagnosticare.

### Done vs To‑Do
- Done: analisi codice/API, DDL e Wiki; creata struttura `tests/` e documento infra.
- To-Do: applicare il piano d’azione in 2–3 PR incrementali partendo da Users+Config.

## Requisito “100% agentico”
- Abbiamo introdotto linee guida e template per permettere ad agenti di creare DDL/SP in modo sicuro e idempotente.
- Documentazione: `docs/agentic/AGENTIC_READINESS.md:1` con principi, guardrail, mini‑DSL JSON e percorso PR.
- Template SQL: `docs/agentic/templates/ddl/` e `docs/agentic/templates/sp/`.
- Test: `tests/agentic/README.md:1` con checklist di convalida.
- Azione: aggiornare Wiki con riferimento alle linee guida agentiche e includere esempi pratici basati sulle nostre SP reali (onboarding/users/config/notifications).
