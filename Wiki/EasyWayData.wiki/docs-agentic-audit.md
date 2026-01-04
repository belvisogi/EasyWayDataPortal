---
id: ew-docs-agentic-audit
title: Documentazione Agentica - Audit & Policy (Canonico)
summary: Standard e controlli per rendere la documentazione davvero “agent-ready”: metadati, tassonomia tag, WHAT-first, KB, gates e anti-allucinazioni.
status: active
owner: team-platform
tags: [docs, governance, agentic, audit, policy, domain/docs, layer/spec, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 350-550
  redaction: [email, phone]
entities: []
---

# Documentazione Agentica - Audit & Policy (Canonico)

Scopo: rendere la documentazione **facile da leggere per agenti** (LLM + tooling) e da umani non esperti, riducendo ambiguità, duplicati e token sprecati.

Questa pagina definisce:
- **Regole** (come scrivere)
- **Tassonomia** (come taggare)
- **Contratti** (WHAT-first: orchestrazioni/intents)
- **Gates** (come verificare automaticamente)
- **Definition of Done** (quando una modifica è “finita”)

## 1) Principi anti-allucinazione
- **Fonte canonica**: per ogni argomento esiste UNA pagina “canonico”. Le altre pagine sono stub con link `canonical`.
- **Path reali**: ogni istruzione operativa cita file/command reali del repo (in backtick).
- **No “vedi sopra/sotto”**: ogni pagina deve essere autonoma.
- **Esempi eseguibili**: comandi copiabili (PowerShell) e output/verify espliciti.
- **Acronimi**: la prima occorrenza spiega l’acronimo (es. ADO, SLO, DQ).

## 2) Struttura minima per pagina (RAG-first)
Target: **300–600 token** per pagina (molte pagine piccole > una enorme).

Sezione consigliata (ordine):
1. Scopo
2. Prerequisiti
3. Passi
4. Verify (cosa controllare)
5. Errori comuni / Troubleshooting
6. References (2–6 link a file/pagine correlate)
7. Domande a cui risponde (3–7)

## 3) Front matter YAML (obbligatorio)
Ogni `.md` deve avere front matter completo:
- `id, title, summary, status, owner, tags`
- `llm.include, llm.pii, llm.chunk_hint`
- `entities` (anche vuoto)

Nota: anche gli indici (`index.md`) devono essere **machine-readable** (front matter incluso).

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

## 6) KB: ricette come “entrypoints” operativi
Ogni cambiamento che introduce un comando/procedura deve aggiornare `agents/kb/recipes.jsonl` con:
- `intent` (stringa stabile)
- `steps` (comandi copiabili)
- `verify` (cosa osservare)
- `references` (file/pagine)

## 7) Gates: controlli automatici (local + CI)

### Remediation (auto-fix front matter)
Quando il lint fallisce, usa lo script di patch (non tocca il contenuto, solo il front matter):
- `pwsh scripts/wiki-frontmatter-patch.ps1 -Path "Wiki/EasyWayData.wiki" -ExcludePaths logs/reports -Apply`

Nota: `Wiki/EasyWayData.wiki/logs/reports/` contiene **report generati** e va trattato come non-canonico (escluso dai controlli “hard”).
Comandi utili:
- Doc alignment gate: `pwsh scripts/doc-alignment-check.ps1 -FailOnError`
- WHAT-first lint: `pwsh scripts/whatfirst-lint.ps1 -FailOnError`
- Wiki front matter lint: `pwsh scripts/wiki-frontmatter-lint.ps1 -FailOnError`
- Governance gates (tutto): `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent`

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

## Collegamenti
- Regole semplici: `docs-conventions.md`
- LLM readiness checklist: `llm-readiness-checklist.md`
- Start here: `start-here.md`
- Control plane: `control-plane/index.md`








