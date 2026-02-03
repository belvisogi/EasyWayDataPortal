---
id: agent-manifest-indexing-best-practices
title: Agent Manifest & Indexing - Best Practices universali
summary: Guida per agenti su come usare manifest JSONL/CSV e ancore per cercare e aprire documenti in modo minimale e token‑friendly, indipendentemente dal progetto o dal formato.
status: active
owner: team-docs
created: '2025-10-18'
updated: '2025-10-18'
tags: [best-practices, ai-readiness, universal, domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it]
entities: []
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
next: TODO - definire next step.
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) >  > 

# Agent Manifest & Indexing - Best Practices

## Obiettivo
Permettere a qualsiasi agente di localizzare rapidamente i contenuti rilevanti senza aprire interi file, riducendo i token. Si basa su tre artefatti sempre presenti alla radice:

- `index_master.jsonl` (manifest per agenti)
- `index_master.csv` (filtri rapidi per umani/Excel)
- `anchors_master.csv` (mappe verso sezioni H2/H3)

## Manifest JSONL (consumo per agenti)
Ogni riga è un documento con campi:
- `id`, `title`, `summary` (≤50 parole), `path`, `format` (md|html|confluence|notion|gdoc|pdf)
- `owner`, `tags[]`, `entities[]`, `llm.include`, `llm.pii`, `chunk_hint`, `updated`
- `questions_answered[]` (se estratte), `anchors[]` (H2/H3: `level,text,slug`)

Strategia d’uso:
- Caricare `index_master.jsonl` all’avvio della sessione.
- Filtrare per `tags`, `entities`, `owner`, `format` per ridurre il set.
- Aprire i file solo quando serve e con deep‑link a `#slug` partendo da `anchors[]`.
- Rispettare `llm.include` e `llm.pii` quando si propagano i contenuti.

## Anchors CSV (richiami di sezione)
`anchors_master.csv` espone righe: `path,level,slug,text`. Gli agenti possono:
- Costruire URL locali o web con `path#slug`.
- Selezionare solo le sezioni richieste dall’utente (es. “IAM”, “Policy”).

## Compatibilità multi‑formato
- Markdown/Wiki: `path` relativo e `format=md`. `anchors[]` popolato.
- Confluence/Notion/GDocs/HTML/PDF: usare `url` (se disponibile) e `format`. `anchors[]` facoltativo.

## Come generare gli artefatti
- CSV + JSONL + Anchors:
  - `EasyWayData.wiki/scripts/generate-master-index.ps1 -Root EasyWayData.wiki`

## Buone pratiche
- Aggiungere sempre `summary`, `tags`, `entities` e la sezione “Domande a cui risponde”.
- Tenere `chunk_hint` tra 300–600 token per pagine generaliste.
- Evitare log e output estesi nelle pagine principali: spostarli in allegati.

## Domande a cui risponde
- Come può un agente sapere “cosa aprire” senza leggere tutto?
- Come ridurre i token usando ancore e manifest?
- Come uniformare l’accesso ai contenuti tra progetti/formati diversi?












