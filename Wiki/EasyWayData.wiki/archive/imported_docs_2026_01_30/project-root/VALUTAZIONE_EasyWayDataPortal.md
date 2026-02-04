---
id: ew-archive-imported-docs-2026-01-30-project-root-valutazione-easywaydataportal
title: Valutazione EasyWayDataPortal — Gap, Rischi e Piano di Allineamento
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# Valutazione EasyWayDataPortal — Gap, Rischi e Piano di Allineamento

## Contesto e Obiettivo
- Obiettivo: fotografare lo stato attuale (API/DB/Wiki), evidenziare i punti da sistemare e proporre un piano d'azione concreto e prioritizzato per portare EasyWay Data Portal in linea con gli standard documentati.
- Scope: repository `EasyWayDataPortal` (root), modulo `portal-api/easyway-portal-api` (API), migrazioni DB `db/migrations/` (DDL/SP canonici), Wiki `Wiki/EasyWayData.wiki` (+ archivio `old/db/` per storici).

## Fonti analizzate
- API: `portal-api/easyway-portal-api/src/...`
- DDL/SP canonici: `db/migrations/` (Git + SQL diretto)
- DDL storici (non canonici): `old/db/` (ex `DataBase/`, export `DDL_PORTAL_*`)
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

2) Config loader - colonna e filtro (PRIORITARIO)
   - Nota: questo punto risulta **già allineato** nel DDL/SP attuali: `PORTAL.CONFIGURATION` usa `enabled` e `section` e la lettura passa via `PORTAL.sp_get_config_by_tenant` con filtro su `enabled` e `section`.
   - Azione: aggiornare Wiki/KB per riflettere il contratto reale (campi supportati, fallback/default, comportamento quando `section` è null) ed evitare regressioni.

3) Notifications — route duplicate e placeholder (ALTA)
   - Problema: route `POST /subscribe` registrata più volte; import ridondanti; controller placeholder.
   - Fix: consolidare in un’unica route. Implementare una SP dedicata a registrare preferenze/subscribe e chiamarla dalla API. Aggiornare validator se necessario.

4) Query via Blob — funzione mancante (MEDIA)
   - Problema: `loadQueryWithFallback` importa `loadSqlQueryFromBlob`, ma `src/config/queryLoader.ts` è vuoto.
   - Fix: implementare stub chiaro (lancia “not configured”) o feature flag che salti la chiamata a Blob quando non configurato. In seguito integrare con Azure Blob Storage.

5) DDL duplicati/obsoleti - single source of truth (MEDIA)
   - Problema: storicamente coesistevano snapshot/export diversi (DataBase/, `DDL_PORTAL_*`) creando ambiguità.
   - Fix: fonte canonica unica = migrazioni in `db/migrations/` (Git + SQL diretto); archiviare tutto il legacy in `old/db/` e rigenerare inventari Wiki da migrations. Flyway è stato valutato e dismesso (vedi `why-not-flyway.md`).

6) Logging/Auditing — aderenza a STATS_EXECUTION_LOG (MEDIA)
   - Problema: se si usano DML diretti via API, si perde il logging standard previsto dalle SP.
   - Fix: centralizzare tutte le mutazioni su SP che scrivono sempre su `PORTAL.STATS_EXECUTION_LOG`. In API aggiungere correlation-id/header per tracing (già in parte presente nel controller di onboarding). 

7) Security & Config (MEDIA)
   - .env: migrare segreti su Azure Key Vault; caricarli via Managed Identity o pipeline.
   - Hardening del middleware `tenant`: prevedere validazione/normalizzazione del tenant, antifrode (limiti rate per tenant), e autenticazione/identità (Entra ID/AD B2C) in fase successiva.

8) CI/CD & Qualità (MEDIA)
   - Aggiungere pipeline Azure DevOps/GitHub Actions: build, lint, test, deploy su slot/stage.
   - Introdurre test minimi (REST Client/Jest) e check DB drift (migrazioni/validatore schema).

9) Documentazione & Struttura repository (COMPLETATO)
   - Doppia denominazione `EasyWayDataPortal` (root) vs `EasyWay-DataPortal` (modulo): **✅ RISOLTA**.
   - Fix implementato (2026-01-18): rinominato `EasyWay-DataPortal` → `portal-api`.
   - Struttura finale: `EasyWayDataPortal` (root) contiene `portal-api/` (modulo API), `db/`, `Wiki/`, `docs/`, `tests/`.

## Piano d’Azione (Priorità e Sequenza)
1. Users via SP + mapping colonne coerente con DDL (blocca errori funzionali)
2. Allineare documentazione `loadDbConfig` (enabled/section) e comportamento quando `section` è null
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
- DDL/SP canonici: `db/migrations/:1` (migrazioni V1..Vn, Git + SQL diretto)

## Rinomina cartelle (completata)
- ✅ Rinominato `EasyWay-DataPortal` → `portal-api` (2026-01-18).
- Struttura monorepo: `EasyWayDataPortal/` (root) con `portal-api/`, `db/`, `Wiki/`, `docs/`, `tests/` (+ `old/` per archivi).
- Eseguita in commit atomico per minimizzare impatti.
- Aggiornati ~60 file: pipeline, manifests, intents, Wiki, root docs.

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


