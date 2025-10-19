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

## Convenzioni e struttura
- [ ] Integrare la guida “kebab-case vs snake_case” in `DOCS_CONVENTIONS.md` (con regex ed esempi buoni/cattivi)
- [ ] Aggiungere “Quick Check” con regex di verifica naming
- [ ] Creare sezioni “Ricette” per AI: `create-table`, `create-endpoint`, `create-job-etl`

## Rinomine e pulizia nomi
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
- [x] EasyWay_WebApp/01_database_architecture/best-practices-checklist.md → best-practices-checklist.md
- [x] EasyWay_WebApp/01_database_architecture/db-studio.md → db-studio.md
- [x] EasyWay_WebApp/01_database_architecture/flyway.md → flyway.md
- [x] EasyWay_WebApp/01_database_architecture/portal.md → portal.md
- [x] EasyWay_WebApp/01_database_architecture/sequence.md → sequence.md
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
- [ ] DBA: convenzioni DDL, template idempotenza, checklist vincoli/indici
- [ ] AMS/Ops: runbook, allarmi, health-check, troubleshooting
- [ ] ETL: mapping, qualità dati, schedule, monitoraggio
- [ ] Analista/BI: metriche, fonti, dashboard, glossario

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

