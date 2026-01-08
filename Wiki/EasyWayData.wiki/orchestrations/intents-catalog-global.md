---
id: ew-orch-intents-catalog-global
title: Orchestrations - Intents Catalog (Globale)
summary: Catalogo globale degli intent WHAT-first disponibili o pianificati (cross-domain), con link agli schemi.
status: draft
owner: team-platform
tags: [orchestration, intents, agents, domain/control-plane, layer/intent, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# Orchestrations - Intents Catalog (Globale)

## Domande a cui risponde
- Quali intent cross-domain sono già definiti e dove si trovano i rispettivi schemi?
- Qual è il pattern di naming per un nuovo intent e in quale path va creato il JSON?
- Quali altri artefatti devo aggiornare quando aggiungo un intent (Wiki, KB, orchestrazioni/manifest)?
- Come distinguo intent attivi da intent “da definire” e quale owner li presidia?
- Qual è l'orchestrazione che li dispatcha (es. n8n) e con quale contratto?

Attivi (con schema)
- agent.scaffold -> `docs/agentic/templates/intents/agent.scaffold.intent.json`
- orchestrator.n8n.dispatch -> `docs/agentic/templates/intents/orchestrator.n8n.dispatch.intent.json`
- api.error.triage -> `docs/agentic/templates/intents/api.error.triage.intent.json`
- ingest.upload-file -> `docs/agentic/templates/intents/ingest.upload-file.intent.json`
- dq.validate -> `docs/agentic/templates/intents/dq.validate.intent.json`
- schema.map-suggest -> `docs/agentic/templates/intents/schema.map-suggest.intent.json`
- schema.map-apply -> `docs/agentic/templates/intents/schema.map-apply.intent.json`
- etl.load-staging -> `docs/agentic/templates/intents/etl.load-staging.intent.json`
- etl.merge-target -> `docs/agentic/templates/intents/etl.merge-target.intent.json`
- analytics.materialize-defaults -> `docs/agentic/templates/intents/analytics.materialize-defaults.intent.json`

Orchestrazioni (WHAT)
- wf.excel-csv-upload -> `orchestrations/wf-excel-csv-upload.md`
- orchestrator (n8n) -> `orchestrations/orchestrator-n8n.md`
- n8n-api-error-triage -> `orchestrations/n8n-api-error-triage.md`

Da definire (skeleton cross-domain)
- db.migrate (Flyway)
- datalake.ensure-structure / datalake.apply-acl / datalake.set-retention
- frontend.scaffold-view
- docs.review / governance.gates

Nota
- Ogni nuovo intent deve avere: schema in `docs/agentic/templates/intents/` + ricetta KB + pagina Wiki.
- Tutti i nuovi intent devono essere dispatchati via `orchestrator.n8n.dispatch` (entrypoint unico).


