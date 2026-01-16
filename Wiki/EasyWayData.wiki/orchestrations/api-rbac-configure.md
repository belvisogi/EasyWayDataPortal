---
id: ew-orch-api-rbac-configure
title: API RBAC Configure (WHAT)
summary: Configura e verifica RBAC/scopes per endpoint API sensibili (docs/db/notifications) in modo governato.
status: draft
owner: team-platform
tags: [domain/api, layer/orchestration, audience/dev, audience/ops, privacy/internal, language/it, security, rbac]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare al workflow n8n reale e aggiungere output sample.
---

# API RBAC Configure (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/api.rbac.configure.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/api-rbac-configure.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `api.rbac.configure`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "api.rbac.configure",
    "params": {
      "targetEnv": "prod",
      "docsRoles": ["portal_admin", "portal_governance"],
      "dbRoles": ["portal_admin", "portal_ops"]
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-101"
  }
}
```sql

Riferimenti
- Policy security/observability: `Wiki/EasyWayData.wiki/easyway-webapp/05_codice_easyway_portale/security-and-observability.md`
- Release preflight: `Wiki/EasyWayData.wiki/orchestrations/release-preflight-security.md`



## Vedi anche

- [Release Preflight Security (WHAT)](./release-preflight-security.md)
- [DB Generate Docs (WHAT)](./db-generate-docs.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [DB User Rotate (WHAT)](./db-user-rotate.md)

