---
id: ew-howto-tagging
title: HOWTO — Tagging e metadati in EasyWay DataPortal
tags: [howto, tagging, onboarding, devx, discoverability, agentic, audience/dev, language/it]
summary: Guida pratica al tagging e ai metadati strutturati per doc, ricette, agent, manifest, script e knowledge base del progetto EasyWay.
status: draft
owner: team-platform
updated: '2026-01-06'
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---

[Home](./start-here.md)

# 🏷️ HOWTO: Tagging & Metadati in EasyWay DataPortal

Una buona gestione di tag/metadati rende la knowledge base EasyWay facilmente ricercabile, automabile e “semantic-friendly” per agent, developer, LLM e workflow!

---

## 1. **Destinazione tag (dove si mettono)**

- **File Markdown (Doc, FAQ, Ricette):**  
  - Sempre in cima, in un blocco YAML frontmatter tra `---` (prima di titoli/testo)
  ```markdown
  ---
  id: ew-wiki-foo
  title: Breve titolo della guida/example
  tags: [domain/db, agentic, layer/blueprint, audience/dev, privacy/internal, language/it]
  summary: Breve descrizione per ricerca/preview
  updated: '2026-01-06'
  ---
  ```
- **Manifest.json/recipe.json**  
  - Tag/keywords vanno come array stringhe (es: `"tags": ["db", "migration", "agentic", "test", "domain/core"]`)
- **Script**  
  - Puoi inserire tag/info in header comment block (per scan agent/docs_review)

---

## 2. **Standard tag e convenzioni**

- **Struttura consigliata:**  
  - Sempre minuscolo, separatore “/” tra macro-categorie (no spazi).  
    Es: `layer/howto`, `domain/db`, `audience/dev`, `language/it`.
  - Se il tag è semplice, lascia solo la parola (`agentic`, `test`, `mock`)

- **Categorie tipiche:**
  - `domain/xxx`        → area funzionale (db, security, workflow, api, frontend, ...)
  - `layer/howto|faq|blueprint|template|policy|onboarding`
  - `agentic`           → risorsa/ricetta pensata per essere usata/automatizzata da un agent
  - `audience/dev|ops|pm|security|user|admin`
  - `privacy/internal|public|restricted`
  - `language/it|en`
  - `sandbox|mock|test|zero-trust`

---

## 3. **Esempi**

**A) In doc/recipe markdown**
```markdown
---
id: ew-api-quickstart
title: Quickstart API EasyWay
tags: [domain/api, layer/howto, audience/dev, agentic, language/it]
summary: Avvia e testa rapidamente la API EasyWay in sandbox o ambiente dev.
updated: '2026-01-06'
---
```sql

**B) In manifest.json**
```json
{
  "role": "Agent_Docs_Review",
  "tags": ["agentic", "docs", "lint", "automation", "domain/doc"]
}
```sql

**C) In header script**
```powershell
<#
  Script: agent-dba.ps1
  Tags: db, agentic, migration, audit, sandbox, language/it
#>
```sql

---

## 4. **Best practice per agent, automazione e discoverability**

- Usa sempre almeno: `domain/…`, `layer/…`, `audience/…`
- Metti tag “agentic” su tutte le guide/scripts pensate per essere avviate/referenziate da agent/n8n/LLM
- Aggiorna `updated:` o data nei metadati a ogni cambiamento
- Inserisci/aggiorna i tag dopo review, PR merge o estensione recipe
- Gli agent/docs_review usano i tag per validare discoverability, completeness e ricercabilità (in repo e vector db)

---

**Collega questa guida ogni volta che crei una nuova doc, agent, script, oppure nelle review di manifest/template!**

---


## Vedi anche

- [Developer & Agent Experience Upgrades](./developer-agent-experience-upgrades.md)
- [Storyboard evolutivo - Da knowledge base classica a continuous improvement agentico (EasyWay)](./storyboard-easyway-agentic.md)
- [Proposte Cross-link, FAQ mancanti, Ricette edge-case e automazioni](./proposte-crosslink-faq-edgecase.md)
- [Documentazione - Contesto standard (obbligatorio)](./documentazione-contesto-standard.md)
- [Glossario EasyWay & FAQ Errori Tipici](../glossario-errori-faq.md)




