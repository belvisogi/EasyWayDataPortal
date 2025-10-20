---
id: ew-todo_checklist
title: TODO CHECKLIST
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
# TODO – Razionalizzazione Wiki (Semplice)

Scopo: elenco chiaro di cose da fare. Breve, spuntabile, capibile da tutti (anche AI).

---

## Gap e aree di miglioramento (cosa manca)
- **Allineamento API/DB:** alcune API non usano ancora solo Store Procedure e c’è mismatch tra nomi colonne e DDL standard (Users, Config). Questo è il punto più critico per la coerenza agentica e la robustezza.
- **Pipeline CI/CD:** da rafforzare con test automatici, validazione drift DB, gates agentici sempre attivi e report periodici.
- **Sicurezza avanzata:** Entra ID/AD B2C, RLS/masking su DB, export log su Datalake sono in roadmap ma non ancora pienamente implementati.
- **Automazione export AI:** export JSONL, tagging PII, e dataset per AI sono previsti ma non ancora completi.
- **Uniformamento naming e struttura:** ancora presenti file/cartelle con encoding, maiuscole, quote/backtick, e naming non uniforme (vedi TODO_CHECKLIST.md).
- **Onboarding e quickstart:** ora razionalizzati, ma serve mantenere sempre aggiornati README e Wiki per evitare dispersione futura.
- **Documentazione ruoli:** mancano guide rapide per DBA, AMS/Ops, ETL, Analisti/BI (roadmap).
- **Automazione documentale:** la documentazione è ricca ma serve maggiore uniformità (front matter, summary, indici, link checker, export AI).
- **Test e QA:** la struttura test è presente, ma va ampliata con smoke/integration test automatici e collezioni Postman/Jest complete.

## Convenzioni e struttura
- [ ] Integrare la guida “kebab-case vs snake_case” in `DOCS_CONVENTIONS.md` (con regex ed esempi buoni/cattivi)
- [ ] Aggiungere “Quick Check” con regex di verifica naming
- [ ] Creare sezioni “Ricette” per AI: `create-table`, `create-endpoint`, `create-job-etl`

## Best practice: Uniformamento naming e struttura
- Uniformare naming e struttura: ancora presenti file/cartelle con encoding, maiuscole, quote/backtick, e naming non uniforme (vedi TODO_CHECKLIST.md).

## Sicurezza avanzata (roadmap, non ancora pienamente implementata)
- Entra ID/AD B2C: autenticazione/identità non ancora integrata nelle API e nei flussi di onboarding.
- RLS/masking su DB: mancano policy Row Level Security e masking attivi su tutte le tabelle sensibili.
- Export log su Datalake: export centralizzato dei log applicativi e di audit verso Azure Datalake non ancora operativo.
- Key Vault: migrazione completa dei segreti da .env a Key Vault da finalizzare.
- Hardening middleware tenant: validazione/normalizzazione tenant, antifrode (rate limit per tenant) e tracing avanzato (correlation id) da rafforzare.
- Documentazione e checklist di sicurezza: da completare e rendere parte della pipeline di PR.

## Automazione documentale (da rafforzare)
- Documentazione ricca ma serve maggiore uniformità: front matter YAML, summary, indici automatici, link checker, export AI (JSONL).
- Uniformare la struttura e i metadati di tutte le pagine chiave.
- Automatizzare la generazione degli indici e la verifica dei link.
- Integrare export dataset AI e checklist di “LLM readiness”.

## Test e QA (da ampliare)
- Struttura test presente ma va ampliata: smoke/integration test automatici, collezioni Postman, test Jest completi.
- Centralizzare e documentare i test in `tests/` e nelle pipeline CI/CD.
- Definire una strategia di coverage e validazione per API, DB e automazioni.
- [x] Normalizzare cartella endpoint residua: `.../ENDPOINT/GET-'api%2Dconfig'/` (nomi puliti, kebab-case)
- [x] Pulizia percent-encoding e caratteri speciali in `02_logiche_easyway/`
- [ ] Pulizia percent-encoding e caratteri speciali in `03_datalake_dev/`
- [ ] Rimuovere backtick/quote nei nomi file (`quotes/backticks`)
- [ ] Uniformare maiuscole/minuscole (tutto minuscolo per file/cartelle)

### Rinomine puntuali (20251019)
- [x] EasyWayData.wiki/agents-governance.md → agents-governance.md
- [x] EasyWayData.wiki/deploy-app-service.md → deploy-app-service.md
- [x] EasyWayData.wiki/parametrization-best-practices.md → parametrization-best-practices.md
- [x] EasyWayData.wiki/roadmap.md → roadmap.md
- [x] easyway-webapp/01_database_architecture/best-practices-checklist.md → best-practices-checklist.md
- [x] easyway-webapp/01_database_architecture/db-studio.md → db-studio.md
- [x] easyway-webapp/01_database_architecture/flyway.md → flyway.md
- [x] easyway-webapp/01_database_architecture/portal.md → portal.md
- [x] easyway-webapp/01_database_architecture/sequence.md → sequence.md
- [x] EasyWay_WebApp/01_database_architecture/storeprocess.md → storeprocess.md
- [x] EasyWay_WebApp/01_database_architecture/01b_schema_structure/portal.md → portal.md
- [x] EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/dinamiche-di-manutenzione.md → dinamiche-di-manutenzione.md
- [x] EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/endpoint.md → endpoint.md
- [x] EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/index.md → index.md
- [x] EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/template-endpoint.md → template-endpoint.md
- [x] EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT/Template-ENDPOINT/come-si-testa.md → come-si-testa.md
- [ ] Valutare esclusione dal linter dei report generati: Wiki/EasyWayData.wiki/logs/reports/normalize-*.md

## Metadati e front matter
- [ ] Aggiungere front matter YAML minimo alle pagine chiave (owner, summary, tags, llm)
- [x] 02_logiche_easyway: front matter minimale aggiunto a tutti i `.md`
- [ ] Marcatura privacy/PII (`llm.include`, `llm.pii`) per aree sensibili
- [ ] Aggiungere sezione “Questions Answered” (3–7 Q&A) nei documenti lunghi

## Indici e link
- [ ] Generare `EasyWayData.wiki/INDEX.md` con H1/H2 e link
- [ ] Aggiungere `INDEX.md` per le principali sottocartelle (DB, API, flussi)
- [ ] Eseguire link checker markdown e correggere link rotti/anchor mancanti
- [x] 02_logiche_easyway: creati `INDEX.md` per cartella e sottocartelle principali

## Automazioni e controlli
- [ ] Linter naming file (ASCII/kebab-case), report settimanale
- [ ] Verifica front matter obbligatoria (campi minimi)
- [ ] Report “LLM readiness” periodico (mancano summary/tags/PII)

## Export per AI (dataset)
- [ ] Definire schema `JSONL` per export (chunk H2/H3, overlap)
- [ ] Script export con calcolo token e batch embedding
- [ ] Escludere file con `llm.include: false`

## Entità e tassonomia
- [ ] Espandere `entities.yaml` (endpoint, SP, tabelle, flussi) con 20+ voci
- [ ] Mappare entità dalle pagine a `entities:` nel front matter

## Estensioni per ruoli (guide rapide)
- [ ] **Mancano guide rapide per i ruoli chiave (roadmap):**
    - DBA: convenzioni DDL, template idempotenza, checklist vincoli/indici
    - AMS/Ops: runbook, allarmi, health-check, troubleshooting
    - ETL: mapping, qualità dati, schedule, monitoraggio
    - Analista/BI: metriche, fonti, dashboard, glossario
- [ ] Per ciascun ruolo, prevedere tanti piccoli agenti specializzati che si occupano delle attività di documentazione, automazione e supporto operativo.

## Accettazione
- [ ] Tutte le pagine hanno front matter base + summary
- [ ] Nessun file con `%2D`, backtick, `�`, spazi o maiuscole
- [ ] Indici presenti (radice + sottocartelle chiave)
- [ ] Link checker senza errori
- [ ] Export JSONL generato per subset pilota (API endpoint)


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?
