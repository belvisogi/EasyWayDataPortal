---
id: ew-etl-dq-framework
title: ETL – Data Quality Framework
summary: Struttura di regole DQ (classi, severità, applicazione) e integrazione con pipeline e audit.
status: active
owner: team-data
tags: [etl, dq, quality, domain/datalake, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, data-quality]
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# ETL – Data Quality Framework
Breadcrumb: Home / Datalake / ETL DQ Framework

Scopo
- Definire classi di regole (completezza, formato, dominio, range, unicità, referenziale), severità e modalità di applicazione in pipeline.

Argos in EasyWay
- Per il framework completo ARGOS (Gates, DSL, Playbook, Profiling, Coach) vedi `argos/argos-overview.md` e le relative pagine.

Classi & Severità (bozza)
- Completezza (required) – mandatory
- Formato (pattern) – mandatory/advisory
- Dominio (lista valori) – mandatory/advisory
- Range (min/max) – advisory
- Unicità (chiave) – mandatory
- Referenziale (lookup) – advisory/mandatory in official

Applicazione per fase
- landing: validazioni minime (schema, campi obbligatori)
- staging: regole principali (pattern, dominio, range)
- official: controlli referenziali/finali, dedup

Esito e gestione scarti
- Esito `OK/BLOCKED` su record/file; scarti in `invalidrows/` con motivazione.
- Report DQ (conteggi/regole violate) nelle metriche di run.

Audit
- Loggare per run: regole applicate, conteggi pass/fail, top errori.
- Retention coerente (vedi Datalake – Set Retention).

Integrazione agentica
- Intent futuri: `etl-dq:validate-spec`, `etl-dq:apply` (WhatIf di default).
- Output Contract: `summary`, conteggi e `changesPreview` (lista regole aggiunte/rimosse).

Riferimenti
- ETL/ELT Inspirations (ADA Framework)
- ETL/ELT Playbook
 - ARGOS – Overview: `argos/argos-overview.md`






