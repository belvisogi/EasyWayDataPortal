---
title: Orchestrations – Intents Catalog (Use Case Excel/CSV)
tags: [orchestration, intents, argos, agents, domain/control-plane, layer/intent, audience/dev, privacy/internal, language/it]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-orch-intents-catalog
chunk_hint: 200-300
entities: []
include: true
summary: Catalogo degli Intent (WHAT) per gli agenti coinvolti nel workflow Excel/CSV→Dashboard, con input/output e criteri di esito.
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000
---

[[../start-here.md|Home]] > [[../control-plane/index.md|Control-Plane]] > Intent

# Orchestrations - Intents Catalog (Use Case Excel/CSV)

## Domande a cui risponde
- Quali intent compongono `wf.excel-csv-upload` e qual è la sequenza logica degli step?
- Dove trovo per ciascun intent lo schema input/output e i criteri di esito (WHAT)?
- Cosa devo aggiornare se aggiungo/rimuovo uno step dal workflow (manifest/cataloghi/KB)?
- Quali output alimentano il diario di bordo e quali eventi ARGOS sono attesi?
- Qual è la pagina canonica che descrive l'orchestrazione e i contratti collegati?

Principio WHAT-first
- Definiamo cosa fa ogni Intent (scopo, input/output, criteri) separatamente dall’implementazione.

Intents (link agli schemi JSON)
- ingest.upload-file → docs/agentic/templates/intents/ingest.upload-file.intent.json
- dq.validate → docs/agentic/templates/intents/dq.validate.intent.json
- schema.map-suggest → docs/agentic/templates/intents/schema.map-suggest.intent.json
- schema.map-apply → docs/agentic/templates/intents/schema.map-apply.intent.json
- etl.load-staging → docs/agentic/templates/intents/etl.load-staging.intent.json
- etl.merge-target → docs/agentic/templates/intents/etl.merge-target.intent.json
- analytics.materialize-defaults → docs/agentic/templates/intents/analytics.materialize-defaults.intent.json

Uso
- L’orchestratore `wf.excel-csv-upload` compone questi Intent in sequenza secondo il manifest.
- Ogni Intent produce output strutturati che alimentano il “diario di bordo”.

Riferimenti
- Orchestrazione – wf.excel-csv-upload: orchestrations/wf-excel-csv-upload.md
- Use Case – Entrate/Uscite: use-cases/entrate-uscite.md







