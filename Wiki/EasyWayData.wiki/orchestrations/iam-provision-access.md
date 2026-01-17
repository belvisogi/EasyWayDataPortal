---
id: ew-orch-iam-provision-access
title: IAM Provision Access (WHAT)
summary: Provisioning end-to-end di accessi tecnici (DB, Datalake) con integrazione Key Vault, RBAC e approvazione human-in-the-loop per ambienti sensibili.
status: active
owner: team-platform
tags: [domain/security, layer/orchestration, audience/ops, privacy/internal, language/it, iam, audit, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-16'
next: Aggiungere esempi end-to-end per target db e datalake.
---

[[start-here|Home]] > [[Domain - Security|Security]] > [[Layer - Orchestration|Orchestration]]

# IAM Provision Access (WHAT)

## Domande a cui risponde
1. Come provisioning un'utenza tecnica sul Datalake?
2. Qual è la sintassi per referenziare un secret su Key Vault?
3. Quali parametri sono obbligatori per il target `db`?

Contratto
- Intent: `docs/agentic/templates/intents/iam.provision.access.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/iam-provision-access.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `iam.provision.access`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "iam.provision.access",
    "params": {
      "target": "db",
      "environment": "prod",
      "identity_type": "sql-user",
      "identity_name": "svc_tenant01_writer",
      "scope": "repos-easyway-dev.database.windows.net/EASYWAY_PORTAL_DEV",
      "permissions": "read/write",
      "secret_ref": "kv://<vault>/<secret>"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-102"
  }
}
```sql

Riferimenti
- Operativita': `Wiki/EasyWayData.wiki/security/operativita-governance-provisioning-accessi.md`
- Segreti & accessi: `Wiki/EasyWayData.wiki/security/segreti-e-accessi.md`



## Vedi anche

- [Agent Security (IAM/KeyVault) - overview](../security/agent-security-iam.md)
- [DB User Create (WHAT)](./db-user-create.md)
- [DB User Revoke (WHAT)](./db-user-revoke.md)
- [DB User Rotate (WHAT)](./db-user-rotate.md)
- [Release Preflight Security (WHAT)](./release-preflight-security.md)


