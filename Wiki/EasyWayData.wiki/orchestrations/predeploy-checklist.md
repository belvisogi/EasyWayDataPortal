---
id: ew-orch-predeploy-checklist
title: Predeploy Checklist (WHAT)
summary: Esegue la checklist operativa pre-deploy (controlli manuali e automatici) e produce un report di gating per la pipeline CI/CD.
status: active
owner: team-platform
tags: [domain/control-plane, layer/orchestration, audience/dev, audience/ops, privacy/internal, language/it, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-16'
next: Collegare all'esecuzione ewctl/checklist e includere output sample.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Orchestration|Orchestration]]

# Predeploy Checklist (WHAT)

## Domande a cui risponde
1. Come lancio la checklist pre-deploy in locale?
2. Dove viene salvato il report `checklist.json`?
3. Qual è la differenza tra runner "governance wrapper" e runner diretto?

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
```sql

## Runtime (come si esegue oggi)

### Locale (consigliato, governance wrapper)
Esegue il task di checklist dentro `scripts/agent-governance.ps1` e (se richiesto) logga un evento strutturato.

```powershell
pwsh scripts/ewctl.ps1 --engine ps --checklist --noninteractive --logevent
```sql

Output/artefatti:
- Report: `portal-api/easyway-portal-api/checklist.json`
- Event log (se `--logevent`): `agents/logs/events*.jsonl` con `artifacts[]` che include il report

Note:
- `--whatif` su `ewctl`/`agent-governance` salta l’esecuzione dei task (modalità “preview”).

### Locale (runner diretto)
Esegue `npm run check:predeploy` dentro `portal-api/easyway-portal-api` (richiede Node/npm e variabili env/`.env.local`).

```powershell
pwsh scripts/checklist.ps1 -ApiPath portal-api/easyway-portal-api
```sql

### CI/CD (gating)
In pipeline, il job `GovernanceGatesEWCTL` usa `ewctl` per eseguire Checklist/DBDrift/KBConsistency (vedi `azure-pipelines.yml`).


## Vedi anche

- [Sync AppSettings Guardrail (WHAT)](./sync-appsettings-guardrail.md)
- [Release Preflight Security (WHAT)](./release-preflight-security.md)
- [KB Assessment (WHAT)](./kb-assessment.md)
- [Generate AppSettings From Env (WHAT)](./generate-appsettings-from-env.md)
- [WHAT-first Lint (WHAT)](./whatfirst-lint.md)


