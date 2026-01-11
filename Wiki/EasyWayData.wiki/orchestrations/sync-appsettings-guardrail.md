---
id: ew-orch-sync-appsettings-guardrail
title: Sync AppSettings Guardrail (WHAT)
summary: Sincronizza App Settings con guardrail e approvazione governance obbligatoria su main/prod.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/ops, privacy/internal, language/it, deploy, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare al job CI e includere decision trace.
---

# Sync AppSettings Guardrail (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/sync-appsettings-guardrail.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/sync-appsettings-guardrail.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `sync-appsettings-guardrail`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "sync-appsettings-guardrail",
    "params": {
      "environment": "prod",
      "enableSync": true,
      "govApproved": false,
      "webAppName": "<app>",
      "resourceGroup": "<rg>"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-111"
  }
}
```



## Vedi anche

- [Apply AppSettings Starter (WHAT)](./apply-appsettings-starter.md)
- [Generate AppSettings From Env (WHAT)](./generate-appsettings-from-env.md)
- [Predeploy Checklist (WHAT)](./predeploy-checklist.md)
- [Deploy su Azure App Service – Pipeline & Variabili](../deploy-app-service.md)
- [IAM Provision Access (WHAT)](./iam-provision-access.md)

