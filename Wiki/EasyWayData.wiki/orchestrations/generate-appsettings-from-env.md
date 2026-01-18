---
id: ew-orch-generate-appsettings-from-env
title: Generate AppSettings From Env (WHAT)
summary: Genera appsettings.* a partire da .env.local per flusso agentico e CI/CD.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, audience/ops, privacy/internal, language/it, deploy, appsettings]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Aggiungere esempi artifacts[] e guardrail su segreti.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Orchestration|Orchestration]]

# Generate AppSettings From Env (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/generate-appsettings-from-env.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/generate-appsettings-from-env.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `generate-appsettings-from-env`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "generate-appsettings-from-env",
    "params": {
      "apiPath": "portal-api/easyway-portal-api",
      "outDir": "out"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-110"
  }
}
```sql



## Vedi anche

- [Apply AppSettings Starter (WHAT)](./apply-appsettings-starter.md)
- [Sync AppSettings Guardrail (WHAT)](./sync-appsettings-guardrail.md)
- [Predeploy Checklist (WHAT)](./predeploy-checklist.md)
- [Release Preflight Security (WHAT)](./release-preflight-security.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)


