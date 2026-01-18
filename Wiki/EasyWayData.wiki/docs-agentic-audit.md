---
title: Documentazione Agentica - Audit & Policy (Canonico)
tags: [docs, governance, agentic, audit, policy, domain/docs, layer/spec, audience/dev, privacy/internal, language/it]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-docs-agentic-audit
chunk_hint: 350-550
entities: []
include: true
summary: Standard e controlli per rendere la documentazione davvero “agent-ready”: metadati, tassonomia tag, WHAT-first, KB, gates e anti-allucinazioni.
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000---

[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Spec|Spec]]

# Documentazione Agentica - Audit & Policy (Canonico)

Scopo: rendere la documentazione **facile da leggere per agenti** (LLM + tooling) e da umani non esperti, riducendo ambiguità, duplicati e token sprecati.

Questa pagina definisce:
- **Regole** (come scrivere)
- **Tassonomia** (come taggare)
- **Contratti** (WHAT-first: orchestrazioni/intents)
- **Gates** (come verificare automaticamente)
- **Definition of Done** (quando una modifica è “finita”)

## 1) Principi anti-allucinazione
- **Fonte canonica**: per ogni argomento esiste UNA pagina "canonico". Le altre pagine sono stub con link `canonical`.
- **Redirect/shim**: pagine duplicate (case/vecchi path) vanno marcate `status: deprecated`, `canonical: <path>`, `llm.include: false` e devono restare minimali.
- **Path reali**: ogni istruzione operativa cita file/command reali del repo (in backtick).
- **No "vedi sopra/sotto"**: ogni pagina deve essere autonoma.
- **Esempi eseguibili**: comandi copiabili (PowerShell) e output/verify espliciti.
- **Acronimi**: la prima occorrenza spiega l'acronimo (es. ADO, SLO, DQ).

## 2) Struttura minima per pagina (RAG-first)
Target: **300-600 token** per pagina (molte pagine piccole > una enorme).

Sezione consigliata (ordine):
1. Scopo
2. Prerequisiti
3. Passi
4. Verify (cosa controllare)
5. Errori comuni / Troubleshooting
6. References (2-6 link a file/pagine correlate)
7. Domande a cui risponde (3-7)

Nota: la sezione **Domande a cui risponde** è obbligatoria solo per le pagine **operative** (`layer/runbook`, `layer/howto`, `layer/orchestration`, `layer/intent`). Per le pagine di reference/spec è consigliata ma non bloccante.

### 2.1) Troubleshooting obbligatorio (best practice)
Regola: ogni volta che un test/comando fallisce, **aggiorna la pagina operativa coinvolta** con una sezione "Errori comuni / Troubleshooting" (o un mini-box) che includa:
- Sintomo (messaggio di errore reale)
- Causa probabile
- Fix (passi concreti)
- Verify (come confermare che e' risolto)

Se l'errore e' ricorrente o impatta piu' team, aggiungi anche una KB recipe in `agents/kb/recipes.jsonl`.

## Domande a cui risponde
- Come verificare la conformità dei manifest degli agenti?
- Quali sono i requisiti minimi per la documentazione agentica?
- Come eseguire l'audit manuale o automatico?

## 3) Front matter YAML (obbligatorio)
Ogni `.md` deve avere front matter completo:
- `id, title, summary, status, owner, tags`
- `llm.include, llm.pii, llm.chunk_hint`
- `entities` (anche vuoto)

Nota: anche gli indici (`index.md`) devono essere **machine-readable** (front matter incluso).
Nota: `id` deve essere **globalmente univoco** nella Wiki (evita ambiguità nei retrieval/index e collisioni di chunk/manifest).

### 3.2) Migrazione “safe” di file legacy (soluzione tecnica)
Quando devi migrare file wiki con naming non conforme (es. `STEP-*`, caratteri speciali, ecc.), usa il pattern:
- **canonical-copy**: crea la pagina canonica in `kebab-case`.
- **legacy stub**: lascia il file vecchio come redirect minimale con `status: deprecated`, `canonical: <path>` e `llm.include: false`.

Obiettivo: evitare rotture di link e ridurre rumore nel retrieval, mantenendo compatibilità con riferimenti esterni.

### 3.1) Draft hygiene (anti-rumore)
Le pagine con `status: draft` devono avere anche:
- `updated: <data>` (es. `updated: '2026-01-05'`)
- `next: <prossimo step>` **oppure** `checklist:` (lista di task)

Obiettivo: evitare pagine draft “orfane” che diventano rumore per agenti e umani.

## 4) Tagging: tassonomia (vocabolario controllato)
Obiettivo: migliorare ricerca e clustering riducendo token.

### 4.1 Tag “base” (sempre presenti)
Usare sempre almeno:
- `domain/<db|datalake|frontend|docs|control-plane|ux>`
- `layer/<howto|reference|runbook|spec|orchestration|intent|gate>`
- `audience/<non-expert|dev|dba|ops>`
- `privacy/<internal|public|restricted>`
- `language/<it|en>`

### 4.2 Tag “specifici” (facoltativi)
Esempi:
- `n8n`, `ewctl`, `argoss`, `flyway`, `terraform`, `ado`, `etl`, `data-quality`

Regole:
- Pochi tag, ma consistenti.
- Evitare sinonimi duplicati (es. scegliere `data-quality` oppure `dq`, non entrambi).


### 4.3 Tag taxonomy + lint
- Taxonomy (source of truth): `docs/agentic/templates/docs/tag-taxonomy.json`
- Pagina guida: `docs-tag-taxonomy.md`
- Lint: `pwsh scripts/wiki-tags-lint.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports` (aggiungi `-RequireFacets` per enforcement)

## 5) WHAT-first: orchestrazioni e intents
Ogni nuovo workflow/use case deve avere:
- Manifest orchestrazione (WHAT): `docs/agentic/templates/orchestrations/*.manifest.json`
- Intent schema (WHAT): `docs/agentic/templates/intents/*.intent.json`
- UX prompts (IT/EN): `docs/agentic/templates/orchestrations/ux_prompts.it.json` e `ux_prompts.en.json`
- Pagina Wiki orchestrazione: `Wiki/EasyWayData.wiki/orchestrations/<wf>.md`
- Diario di bordo (contratto output): timeline con `timestamp, stage, outcome, reason, next, decision_trace_id, artifacts[]`

### 5.1) Plan + Diario (machine-readable)
Per ogni orchestrazione/intent che deve essere eseguibile via n8n, mantenere allineati:
- Schema Plan: `docs/agentic/templates/plans/plan.schema.json`
- Schema Diario: `docs/agentic/templates/plans/diary.schema.json`
- Almeno un esempio aggiornato sotto `docs/agentic/templates/plans/samples/`
Fonte canonica: `Wiki/EasyWayData.wiki/plan-and-diary-contract.md`.

## 6) KB: ricette come "entrypoints" operativi
Ogni cambiamento che introduce un comando/procedura deve aggiornare `agents/kb/recipes.jsonl` con:
- `intent` (stringa stabile)
- `steps` (comandi copiabili)
- `verify` (cosa osservare)
- `references` (file/pagine)

Best practice (navigabilita' doc): intent machine-readable in `scripts/intents/doc-nav-improvement-001.json`.

## 7) Gates: controlli automatici (local + CI)

### Remediation (auto-fix front matter)
Quando il lint fallisce, usa lo script di patch (non tocca il contenuto, solo il front matter):
- `pwsh scripts/wiki-frontmatter-patch.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports -Apply`

Nota: `Wiki/EasyWayData.wiki/logs/reports/` contiene **report generati** e va trattato come non-canonico (escluso dai controlli “hard”).
Comandi utili:
- Naming report (non conformità + anchor issues, safe in `-DryRun`): `pwsh Wiki/EasyWayData.wiki/scripts/review-run.ps1 -Root "Wiki/EasyWayData.wiki" -Mode kebab -CheckAnchors -DryRun`
- Doc alignment gate: `pwsh scripts/doc-alignment-check.ps1 -FailOnError`
- WHAT-first lint: `pwsh scripts/whatfirst-lint.ps1 -FailOnError`
- Wiki front matter lint: `pwsh scripts/wiki-frontmatter-lint.ps1 -FailOnError`
- Wiki gap report (sezioni minime + draft hygiene + placeholder): `pwsh scripts/wiki-gap-report.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports,old,.attachments -ScopesPath "docs/agentic/templates/docs/tag-taxonomy.scopes.json" -ScopeName <SCOPE> -FailOnError -SummaryOut wiki-gap.<SCOPE>.json`
- Governance gates (tutto): `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent`

Nota CI: il gate `WikiGapReport` in `azure-pipelines.yml` esegue `wiki-gap-report` in modalità **phased** (scope per scope) o **all** (toggle `WIKI_GAP_MODE=all`) per evitare regressioni.

### Agent-ready audit (a monte)
Per evitare che “gli agenti arrivino sempre a valle”, la repo espone uno **standard verificabile** + uno script di audit aggregato:
- Rubrica machine-readable: `docs/agentic/templates/docs/agent-ready-rubric.json`
- Audit aggregato: `pwsh scripts/agent-ready-audit.ps1 -Mode all -FailOnError -SummaryOut agent-ready-audit.json`

L’audit è pensato per essere riusato anche in altri progetti: produce un report JSON con `ok`, `errors/warnings` e dettaglio per scope.

## 8) Definition of Done (Doc agentica)
Una modifica è “done” quando:
- La pagina è autonoma, corta, con esempi e verify.
- Front matter completo + tag base coerenti.
- Link funzionanti.
- KB aggiornata (se aggiunge una procedura).
- Se cambia workflow: manifest/intents/ux_prompts + pagina Wiki.
- Gates verdi (doc alignment / whatfirst / front matter / governance se rilevante).

## 9) Audit periodico (cosa misurare)
- % pagine con front matter completo
- % pagine con tag base (domain/layer/audience/privacy/language)
- Pagine troppo lunghe (oltre budget token)
- Duplicati (stesso argomento in più pagine senza canonical)
- Link rotti e placeholder
- Gap report (owner/summary/draft hygiene + sezioni minime per howto/runbook)

## Collegamenti
- Regole semplici: `docs-conventions.md`
- LLM readiness checklist: `llm-readiness-checklist.md`
- Start here: `start-here.md`
- Control plane: `control-plane/index.md`








## Vedi anche

- [Roadmap Uniformamento Wiki secondo docs-conventions](./wiki-uniformamento-roadmap.md)
- [EasyWayData Portal - Regole Semplici (La Nostra Bibbia)](./docs-conventions.md)
- [Tag Taxonomy (Controllata)](./docs-tag-taxonomy.md)
- [Best Practices & Roadmap – Token Tuning e AI-Readiness Universale](./best-practices-token-tuning-roadmap.md)
- [Visione Portale Agentico](./agentic-portal-vision.md)




