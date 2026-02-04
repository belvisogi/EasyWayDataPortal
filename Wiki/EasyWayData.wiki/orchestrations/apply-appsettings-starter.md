---
id: ew-orch-apply-appsettings-starter
title: Apply AppSettings Starter (WHAT)
summary: Applica uno starter di App Settings su Azure App Service in modo governato (WhatIf-by-default) con audit.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/ops, privacy/internal, language/it, deploy, appsettings, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare al workflow n8n reale e aggiungere esempi settings (senza segreti).
type: guide
---

[[../start-here.md|Home]] > [[../control-plane/index.md|Control-Plane]] > Orchestration

# Apply AppSettings Starter (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/apply-appsettings-starter.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/apply-appsettings-starter.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `apply-appsettings-starter`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "apply-appsettings-starter",
    "params": {
      "resourceGroup": "<rg>",
      "webAppName": "<app>",
      "settings": { "DEFAULT_TENANT_ID": "tenant01" }
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-109"
  }
}
```sql

Riferimenti
- Deploy App Service: `Wiki/EasyWayData.wiki/deploy-app-service.md`



## Vedi anche

- [Generate AppSettings From Env (WHAT)](./generate-appsettings-from-env.md)
- [Sync AppSettings Guardrail (WHAT)](./sync-appsettings-guardrail.md)
- [Deploy su Azure App Service – Pipeline & Variabili](../deploy-app-service.md)
- [Predeploy Checklist (WHAT)](./predeploy-checklist.md)
- [Release Preflight Security (WHAT)](./release-preflight-security.md)





