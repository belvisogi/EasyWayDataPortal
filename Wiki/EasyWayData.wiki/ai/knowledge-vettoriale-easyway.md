---
id: ew-knowledge-vettoriale-easyway
title: Knowledge base vettoriale in EasyWay DataPortal (AI/RAG/LLM)
tags: [ai, vector-db, llm, rag, semantic-search, automation, n8n, onboarding, obsidian, language/it]
summary: Panoramica, valore, architettura e casi d’uso della knowledge base vettoriale per EasyWay DataPortal. Per developer e agent.
status: draft
owner: team-platform
updated: '2026-01-07'
---

[Home](../../../docs/project-root/DEVELOPER_START_HERE.md)

# 🧠 Knowledge Base Vettoriale in EasyWay DataPortal

> _Questa guida spiega cosa significa, come si realizza e perché è strategica la gestione di una knowledge base “vettoriale” per la piattaforma EasyWay DataPortal. Contiene anche esempi pratici per integration agent, n8n, e best practice di automazione/aggiornamento._

---

## Cos’è una knowledge base vettoriale?

- È una base di conoscenza in cui **ogni documento, manifest, recipe, FAQ, guida, etc.** viene rappresentato (vettorizzato/embedded) come un array di numeri.
- Questo permette **ricerche semantiche** (“similitudine di significato”) molto più potenti delle classiche keyword/cercatrova.
- Gli agent (umani o sw), strumenti LLM/copilot, e workflow n8n possono interrogare la base e ricevere risposte pertinenti e contestuali.

---

## Perché serve a EasyWay

- Tanti agent, doc e template diversi, con workflow in continua evoluzione
- Serve ricerca, discovery, automazione e supporto smart (LLM, n8n, agent runtime, Copilot, onboarding)
- Riduce la knowledge debt e collega meglio runtime, codice, doc, security e supporto

---

## Architettura e workflow consigliato

```mermaid
flowchart TD
  A[Repo EasyWay: file doc/script/recipes/manifest] --> B[Include/exclude file-list YAML]
  B --> C[Chunking & vettorializzazione]
  C --> D[Vector DB (Chroma/Weaviate/Pinecone)]
  D --> E1[n8n workflow: query semantica]
  D --> E2[Agent runtime: context on-demand]
  D --> E3[Copilot/LLM QA: suggerimenti, fix, PR stub]
  A -.update ogni merge/PR.-> C
  D ==> A
```sql
- I file “classici” restano in repo, ma il **vector DB** è la base runtime per query intelligenti agent/n8n/LLM.
- Ogni nuovo doc/manifest/recipe va in pipeline e aggiorna la knowledge base semantica subito.

---

## Cosa vettorializzare? (spec)

- Tutto ciò che serve supporto semantico rapido e aggiornato:
    - README.md, , agent docs, atomic_flows, scripts doc, tutte le FAQ pratiche
    - Manifest degli agent, template orchestrazioni, ricette tecniche
    - Troubleshooting, cronaca edge-case, errori tipici

```yaml
# ai/vettorializza.yaml : file canonico di inclusione/esclusione
include:
  - "README.md"
  - "Wiki/EasyWayData.wiki/**/*.md"
  - "agents/**/*.md"
  - "atomic_flows/**/*.md"
  - "docs/**/*.md"
exclude:
  - "old/"
  - "bin/"
  - "*.pdf"
```sql
- **Questa regola YAML** guida ogni pipeline di embedding e può essere aggiornata/estesa facilmente!

---


## Scope DBA (SQL)

Per casi d’uso DBA (stored procedure, ACL, migrazioni, query applicative) conviene includere anche sorgenti SQL “canoniche” del repo:
- Flyway migrations: `db/flyway/sql/**/*.sql`
- Query applicative: `portal-api/easyway-portal-api/src/queries/**/*.sql`

Regola canonica di include/exclude: `ai/vettorializza.yaml`.

Note
- Evitare qualunque file con segreti o `.env` (già esclusi dalla spec).
- Chunking: per SQL usare chunk per statement/procedura, non per righe arbitrarie.


- Ogni merge/commit su file inclusi triggera la (re)vettorializzazione automatica (n8n, Azure Pipeline, GitHub Actions, agent dedicato)
- Solo i file che “matchano” la regola vengono reindicizzati → nessuno scan/bloat inutile
- Agent (in repo, n8n, container) si occupa di processare, chunkare, embeddare, aggiornare vector DB

---

## Scenari di integrazione

- **Runtime**: agenti in produzione, workflow n8n e Copilot usano SOLO vectorDB
- **Dev/Maintainer**: lavorano a repo file, ogni update viene integrato anche in index vettoriale
- **Team/CI/CD**: fanno review, fix, onboarding, QA doc e policy direttamente nel repo, ma le automazioni usano chunk embedding-ready

---

## Tool e costi: cosa scegliere?

- Inizia con ChromaDB, Weaviate, Milvus (local, open, GRATIS)
- Per scaling o pro/prod: Pinecone/Qdrant/Weaviate cloud (tier free → paghi solo se/quanto superi soglia)
- Nulla vieta mix: local per dev, cloud per runtime!

---

## Strategia consigliata (dev locale → prod managed)

Obiettivo: partire economici e veloci in dev (Qdrant/Chroma locale), mantenendo una strada semplice per migrare a un backend managed (Azure AI Search) quando serve.

Dev (locale)
- Vector DB locale (Qdrant o Chroma).
- Ingestion incrementale dal repo usando la spec `ai/vettorializza.yaml` (Wiki/KB/manifest + SQL DBA quando serve).
- n8n interroga il vector DB (non legge il repo) e passa un `rag_context_bundle` ai workflow/agent.

Prod (upgrade)
- Mantieni invariati: include/exclude (`ai/vettorializza.yaml`), chunking strategy e metadati minimi (almeno `path`, `title`, `tags`, `updated`, `chunk_id`).
- Migrazione “semplice”: re-run ingestion e upsert su Azure AI Search (nessun lock-in nei documenti del repo).

Come “tenere le analisi sul vector”
- Ogni analisi/decisione utile all’agent (es. note DBA su SP/ACL, troubleshooting, mapping, policy) va salvata come pagina Wiki canonica sotto `Wiki/EasyWayData.wiki/ai/` (Markdown con front-matter e tag), così entra automaticamente in vettorializzazione.
- Evitare duplicati: una pagina canonica per tema + backlink dalle pagine secondarie.

---

## Sicurezza e zero trust

- Il file YAML di inclusion/exclusion serve anche a escludere:
  - Binari/confidenziali (old/, bin/, backup)
  - Dati sensibili/non destinati a agent o search (es.: password/segreti/config reale)
- La pipeline può lanciare solo in safe/sandbox (evita data leak, ciclo testato come tutte le altre automazioni EasyWay).
- Linka la policy “Zero Trust/Sandbox”: [Setup sandbox/Zero Trust](../onboarding/setup-playground-zero-trust.md)

---

## Come legare a Obsidian/KB

- Ogni sezione ha cross-link markdown friendly, per navigazione (anche da mobile/Obsidian vault).
- La guida suggerisce dove mettere backlink (README, onboarding, recipes, agent docs).
- Puoi aggiungere backlink a questa pagina in ogni documento chiave (“Per ricerche smart, vedi [Knowledge Base Vettoriale](knowledge-vettoriale-easyway.md)”).

---

## Prossimi step

1. Decidere se partire local, cloud, ibrido (vedi section costi/tool)
2. Pianificare agent/processo di update embedding (n8n, CI, agent runtime)
3. Pubblicare i file inclusion/exclusion YAML in repo (aggiornabili da tutti!)
4. Integrare primi query workflow n8n/Copilot/manuale, testare search semantica su doc viva
5. Prendere feedback e iterare migliorando experience

---

## Contesto (repo)
- Obiettivi e principi: `agents/goals.json`
- Orchestrazione/gates (entrypoint): `scripts/ewctl.ps1`
- Ricette operative (KB): `agents/kb/recipes.jsonl`
- Osservabilita: `agents/logs/events.jsonl`
- Export chunks Wiki: `Wiki/EasyWayData.wiki/scripts/export-chunks-jsonl.ps1` -> `Wiki/EasyWayData.wiki/chunks_master.jsonl`
- Standard contesto: `Wiki/EasyWayData.wiki/onboarding/documentazione-contesto-standard.md`

---

**See also / Cross-link:**
- [Setup sandbox/Zero Trust](../onboarding/setup-playground-zero-trust.md)
- [Scripting cross-platform](../onboarding/best-practice-scripting.md)
- [Developer & Agent Experience Upgrades](../onboarding/developer-agent-experience-upgrades.md)
- [Proposte miglioramento cross-link, FAQ, edge-case](../onboarding/proposte-crosslink-faq-edgecase.md)

---

> _Per qualsiasi dubbio, proporre miglioramenti e contributi, commenta in questa guida o tagga nei manifest “ai-friendly”._





