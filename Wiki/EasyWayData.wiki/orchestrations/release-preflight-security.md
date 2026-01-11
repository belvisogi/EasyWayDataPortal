---
id: ew-orch-release-preflight-security
title: Release Preflight Security (WHAT)
summary: Checklist pre-go-live (security/compliance/audit) richiamabile via orchestrator.n8n.dispatch con output strutturato.
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, audience/ops, privacy/internal, language/it, security, compliance, audit, release]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare al workflow n8n reale e aggiungere esempi di output.
---

# Release Preflight Security (WHAT)

Scopo
- Prima di andare in produzione, restituire in modo **agent-ready** un elenco di controlli security/compliance/audit con esito e next step.

Contratto
- Intent schema: `docs/agentic/templates/intents/release.preflight.security.intent.json`
- Manifest orchestrazione: `docs/agentic/templates/orchestrations/release-preflight-security.manifest.json`
- KB recipe: `agents/kb/recipes.jsonl` -> `release.preflight.security`

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "release.preflight.security",
    "params": {
      "targetEnv": "prod",
      "changeSummary": "Release X.Y.Z - hardening API + RBAC + audit"
    },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-001"
  }
}
```

Output atteso (alto livello)
- `ok`: true/false
- `checks[]`: lista controlli con `outcome` (`pass|warn|fail|skipped`) e `evidence[]`
- `next[]`: azioni suggerite per chiudere i gap

Riferimenti
- Policy: `Wiki/EasyWayData.wiki/easyway-webapp/05_codice_easyway_portale/security-and-observability.md`
- Policy gateway/microservizi: `Wiki/EasyWayData.wiki/easyway-webapp/02_logiche_easyway/policy-di-configurazione-and-sicurezza-microservizi-e-api-gateway.md`
- QnA errori: `Wiki/EasyWayData.wiki/api/rest-errors-qna.md`


## Vedi anche

- [API RBAC Configure (WHAT)](./api-rbac-configure.md)
- [Orchestratore n8n (WHAT)](./orchestrator-n8n.md)
- [Predeploy Checklist (WHAT)](./predeploy-checklist.md)
- [Agent Security (IAM/KeyVault) - overview](../security/agent-security-iam.md)
- [n8n API Error Triage](./n8n-api-error-triage.md)

