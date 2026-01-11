---
id: ew-orch-predeploy-checklist
title: Predeploy Checklist (WHAT)
summary: Esegue la checklist pre-deploy e produce report machine-readable (gating).
status: draft
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, audience/ops, privacy/internal, language/it, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-08'
next: Collegare all'esecuzione ewctl/checklist e includere output sample.
---

# Predeploy Checklist (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/predeploy-checklist.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/predeploy-checklist.manifest.json`
- KB: `agents/kb/recipes.jsonl` (intent `predeploy-checklist`)

Entrypoint (n8n.dispatch)
```json
{
  "action": "orchestrator.n8n.dispatch",
  "params": {
    "action": "predeploy-checklist",
    "params": { "targetEnv": "prod" },
    "whatIf": true,
    "nonInteractive": true,
    "correlationId": "op-2026-01-08-112"
  }
}
```

## Runtime (come si esegue oggi)

### Locale (consigliato, governance wrapper)
Esegue il task di checklist dentro `scripts/agent-governance.ps1` e (se richiesto) logga un evento strutturato.

```powershell
pwsh scripts/ewctl.ps1 --engine ps --checklist --noninteractive --logevent
```

Output/artefatti:
- Report: `EasyWay-DataPortal/easyway-portal-api/checklist.json`
- Event log (se `--logevent`): `agents/logs/events*.jsonl` con `artifacts[]` che include il report

Note:
- `--whatif` su `ewctl`/`agent-governance` salta l’esecuzione dei task (modalità “preview”).

### Locale (runner diretto)
Esegue `npm run check:predeploy` dentro `EasyWay-DataPortal/easyway-portal-api` (richiede Node/npm e variabili env/`.env.local`).

```powershell
pwsh scripts/checklist.ps1 -ApiPath EasyWay-DataPortal/easyway-portal-api
```

### CI/CD (gating)
In pipeline, il job `GovernanceGatesEWCTL` usa `ewctl` per eseguire Checklist/DBDrift/KBConsistency (vedi `azure-pipelines.yml`).


## Vedi anche

- [Sync AppSettings Guardrail (WHAT)](./sync-appsettings-guardrail.md)
- [Release Preflight Security (WHAT)](./release-preflight-security.md)
- [KB Assessment (WHAT)](./kb-assessment.md)
- [Generate AppSettings From Env (WHAT)](./generate-appsettings-from-env.md)
- [WHAT-first Lint (WHAT)](./whatfirst-lint.md)

