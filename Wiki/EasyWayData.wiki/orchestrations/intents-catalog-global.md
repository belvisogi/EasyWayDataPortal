---
id: ew-orch-intents-catalog-global
title: Orchestrations - Intents Catalog (Globale)
summary: Catalogo globale degli intent WHAT-first disponibili o pianificati (cross-domain), con link agli schemi.
status: active
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
- api.rbac.configure -> `docs/agentic/templates/intents/api.rbac.configure.intent.json`
- orchestrator.n8n.dispatch -> `docs/agentic/templates/intents/orchestrator.n8n.dispatch.intent.json`
- api.error.triage -> `docs/agentic/templates/intents/api.error.triage.intent.json`
- apply-appsettings-starter -> `docs/agentic/templates/intents/apply-appsettings-starter.intent.json`
- db-drift-check -> `docs/agentic/templates/intents/db-drift-check.intent.json`
- db-generate-docs -> `docs/agentic/templates/intents/db-generate-docs.intent.json`
- db-migrate -> `docs/agentic/templates/intents/db-migrate.intent.json`
- db-user-create -> `docs/agentic/templates/intents/db-user-create.intent.json`
- db-user-revoke -> `docs/agentic/templates/intents/db-user-revoke.intent.json`
- db-user-rotate -> `docs/agentic/templates/intents/db-user-rotate.intent.json`
- generate-appsettings-from-env -> `docs/agentic/templates/intents/generate-appsettings-from-env.intent.json`
- iam.provision.access -> `docs/agentic/templates/intents/iam.provision.access.intent.json`
- kb.assessment -> `docs/agentic/templates/intents/kb.assessment.intent.json`
- release.preflight.security -> `docs/agentic/templates/intents/release.preflight.security.intent.json`
- predeploy-checklist -> `docs/agentic/templates/intents/predeploy-checklist.intent.json`
- sync-appsettings-guardrail -> `docs/agentic/templates/intents/sync-appsettings-guardrail.intent.json`
- whatfirst-lint -> `docs/agentic/templates/intents/whatfirst-lint.intent.json`
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
- release-preflight-security -> `orchestrations/release-preflight-security.md`
- api-rbac-configure -> `orchestrations/api-rbac-configure.md`
- iam-provision-access -> `orchestrations/iam-provision-access.md`
- db-migrate -> `orchestrations/db-migrate.md`
- db-drift-check -> `orchestrations/db-drift-check.md`
- db-generate-docs -> `orchestrations/db-generate-docs.md`
- db-user-create -> `orchestrations/db-user-create.md`
- db-user-rotate -> `orchestrations/db-user-rotate.md`
- db-user-revoke -> `orchestrations/db-user-revoke.md`
- apply-appsettings-starter -> `orchestrations/apply-appsettings-starter.md`
- generate-appsettings-from-env -> `orchestrations/generate-appsettings-from-env.md`
- sync-appsettings-guardrail -> `orchestrations/sync-appsettings-guardrail.md`
- predeploy-checklist -> `orchestrations/predeploy-checklist.md`
- kb-assessment -> `orchestrations/kb-assessment.md`
- whatfirst-lint -> `orchestrations/whatfirst-lint.md`

Da definire (skeleton cross-domain)
- db.migrate (Flyway)
- datalake.ensure-structure / datalake.apply-acl / datalake.set-retention
- frontend.scaffold-view
- docs.review / governance.gates

Nota
- Ogni nuovo intent deve avere: schema in `docs/agentic/templates/intents/` + ricetta KB + pagina Wiki.
- Tutti i nuovi intent devono essere dispatchati via `orchestrator.n8n.dispatch` (entrypoint unico).




## Vedi anche

- [Orchestrations – Intents Catalog (Use Case Excel/CSV)](./intents-catalog.md)
- [Orchestratore n8n (WHAT)](./orchestrator-n8n.md)
- [Mapping Matrix - Workflow → Intent → Implementazione](./mapping-matrix.md)
- [Orchestrazione – wf.excel-csv-upload (WHAT)](./wf-excel-csv-upload.md)
- [Agents Registry (owner, domini, intent)](../control-plane/agents-registry.md)

