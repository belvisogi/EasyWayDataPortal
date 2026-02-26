---
title: "Agent Run Dashboard — Guida POST /run + GET /runs + RUN Button"
created: 2026-02-26
updated: 2026-02-26T00:00:00Z
status: active
category: guide
domain: api
tags: [agents, dashboard, backoffice, run-history, cron, ado-issue]
priority: high
audience:
  - developers
  - operators
  - system-architects
id: ew-guide-agent-run-dashboard
summary: >
  Guida completa all'Agent Run Dashboard di Session 28: POST /api/agents/:id/run,
  GET /api/agents/:id/runs, RUN button nel backoffice, storage JSON,
  cron scheduler autonomo con ADO auto-issue su failure.
owner: team-platform
related:
  - [[agents/platform-operational-memory]]
  - [[agents/agent-roster]]
  - [[guides/knowledge-api-guide]]
llm:
  include: true
  pii: low
  chunk_hint: 300-400
  redaction: [api_key]
type: guide
---

# Agent Run Dashboard — Guida completa Session 28

## Cosa è

Il **Agent Run Dashboard** è l'insieme di tre componenti sviluppati in Session 28 per:

1. **Lanciare agenti** da backoffice UI con un click (RUN button)
2. **Tracciare la run history** di ogni agente (chi ha eseguito cosa, quando, con quale esito)
3. **Schedulare run autonomi** via cron e aprire automaticamente Bug ADO se si rilevano problemi

---

## Perché esiste

### Il problema
Prima di Session 28:
- Gli agenti erano visibili nel backoffice (`/backoffice/agents`) ma non eseguibili da UI
- Nessuna run history — impossibile sapere "quando ha girato l'ultima volta? con quale esito?"
- I run manuali richiedevano SSH al server e esecuzione PowerShell manuale
- Nessuna automazione: drift infrastrutturale o violazioni OpenAPI venivano scoperte solo reattivamente

### La soluzione
- **REST API** per lanciare e listare run: `POST /api/agents/:id/run`, `GET /api/agents/:id/runs`
- **RUN button** inline nella tabella del backoffice agenti con feedback immediato
- **Cron scheduler** node-cron che invoca agenti automaticamente a schedule fisso
- **ADO auto-issue**: se un cron job trova severity HIGH o violations > 0, apre un Bug ADO automaticamente

---

## Come funziona

### POST /api/agents/:id/run

```
POST /api/agents/agent_infra/run
Authorization: Bearer <JWT>

Response 202:
{
  "runId": "uuid-...",
  "agentId": "agent_infra",
  "action": "infra:drift-check",
  "status": "RUNNING",
  "startedAt": "2026-02-26T10:00:00.000Z",
  "triggeredBy": "manual"
}
```

**Flusso interno:**
1. Valida `agentId` (formato `/^agent_[a-z0-9_]+$/`)
2. Legge `manifest.json` dell'agente e prende la prima action
3. Risponde subito 202 (async — il run continua in background)
4. `runAgent()` in `agent-runner.service.ts`:
   - **Mock mode** (`DB_MODE=mock` o Windows): simula run SUCCESS dopo 500ms
   - **Production** (Linux + non-mock): esegue `pwsh -File agents/<id>/Invoke-Agent<PascalCase>.ps1 -Action <action>`
5. Aggiorna `data/agent-runs.json` con status finale

### GET /api/agents/:id/runs

```
GET /api/agents/agent_infra/runs?limit=10
Authorization: Bearer <JWT>

Response 200:
{
  "agentId": "agent_infra",
  "runs": [
    {
      "runId": "...",
      "agentId": "agent_infra",
      "action": "infra:drift-check",
      "status": "SUCCESS",
      "startedAt": "2026-02-26T10:00:00.000Z",
      "completedAt": "2026-02-26T10:00:02.500Z",
      "durationMs": 2500,
      "exitCode": 0,
      "triggeredBy": "manual"
    }
  ],
  "count": 1
}
```

### Storage: data/agent-runs.json

```json
[
  {
    "runId": "uuid",
    "agentId": "agent_infra",
    "action": "infra:drift-check",
    "status": "SUCCESS|FAILED|RUNNING|PENDING",
    "startedAt": "ISO",
    "completedAt": "ISO",
    "durationMs": 2500,
    "output": "...(stdout/stderr troncato a 10kb)...",
    "exitCode": 0,
    "triggeredBy": "manual|cron"
  }
]
```

- Path: `path.join(process.env.DATA_PATH || 'data', 'agent-runs.json')`
- Max 200 entry (le più vecchie vengono rimosse automaticamente)
- Il container deve avere write access: `chown -R 1000:1000 ~/EasyWayDataPortal/data/`

### RUN Button nel backoffice

Il componente `data-list` in `pages-renderer.ts` legge `rowActions` dal JSON di configurazione pagina:

```json
// backoffice-agents.json
{
  "type": "data-list",
  "dataUrl": "/api/agents",
  "columns": [...],
  "rowActions": [
    { "type": "run", "labelKey": "backoffice.agents.btn_run", "idField": "agent_id" }
  ]
}
```

**Comportamento:**
1. Per ogni riga della tabella, viene renderizzata una colonna "Azioni"
2. Il bottone "▶ Esegui" invia `POST /api/agents/<agent_id>/run`
3. Se 202: mostra "Avviato ✓" per 3 secondi, poi ripristina
4. Se errore: mostra "Errore ✗" per 3 secondi, poi ripristina
5. Il bottone è disabilitato durante l'invio per evitare doppi click

---

## Cron Scheduler Autonomo

### Architettura

```
server.ts (app.listen)
  │  CRON_ENABLED=true
  ▼
scheduler.ts (startScheduler)
  ├── "0 */6 * * *"   → infra-drift.ts → runAgent(agent_infra, infra:drift-check, cron)
  │                                         └── se severity=HIGH → createAdoIssue(Bug)
  ├── "0 9 * * 1"     → openapi-validate.ts → runAgent(agent_backend, api:openapi-validate, cron)
  │                                             └── se violations>0 → createAdoIssue(Bug)
  └── "0 8 * * 1"     → sprint-report.ts → runAgent(agent_scrummaster, sprint:report, cron)
                                             └── solo log (nessun ADO issue)
```

### Schedule

| Job | Schedule | Agente | Action | ADO Issue |
|-----|----------|--------|--------|-----------|
| Infra Drift Check | ogni 6h | `agent_infra` | `infra:drift-check` | Sì, se HIGH |
| OpenAPI Validate | Lunedì 09:00 | `agent_backend` | `api:openapi-validate` | Sì, se violations>0 |
| Sprint Report | Lunedì 08:00 | `agent_scrummaster` | `sprint:report` | No (solo log) |

### ADO Auto-Issue

Quando un cron job rileva un problema:

```typescript
await createAdoIssue(
  "[CRON] Infra Drift Alert — 2026-02-26T10:00:00Z",
  `Severity: HIGH\nOutput:\n${output?.substring(0, 2000)}`
);
```

Chiama `POST https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/wit/workitems/$Bug?api-version=7.0` con:
- `System.Title` — titolo con timestamp
- `System.Description` — output agente (troncato)
- Auth: `Basic base64(":PAT")`

**Env vars necessari:**
- `ADO_ORG=EasyWayData`
- `ADO_PROJECT=EasyWay-DataPortal`
- `AZURE_DEVOPS_EXT_PAT=<PAT con Work Items R/W>`
- `CRON_ENABLED=true` (default: false)

### Attivazione

In `docker-compose.apps.yml`:
```yaml
services:
  api:
    environment:
      - CRON_ENABLED=true
      - ADO_ORG=EasyWayData
      - ADO_PROJECT=EasyWay-DataPortal
      - AZURE_DEVOPS_EXT_PAT=${AZURE_DEVOPS_EXT_PAT}
```

> **Nota**: `CRON_ENABLED=false` in locale/mock (default) per evitare run accidentali in sviluppo.

---

## Q&A Operativi

**D: Cosa succede se premo RUN su un agente già in esecuzione?**
R: Viene creato un nuovo run indipendente. Non c'è lock/mutex a livello API. Se il runner PS è già attivo per lo stesso agente, i due processi girano in parallelo. Per il futuro si può aggiungere un check "already running" sul storage.

**D: Mock mode gira sul server in produzione?**
R: Sì, attualmente `DB_MODE=mock` è impostato nel container API del server perché non è presente SQL Server. In mock mode, `runAgent()` aspetta 500ms e risponde SUCCESS con output fittizio. I run vengono comunque registrati in `agent-runs.json`, quindi la UI funziona correttamente.

**D: Come verifico che il cron è attivo?**
R:
```bash
# Guarda i log del container (cerca "Scheduler started" e i log dei run)
docker logs easyway-api --tail=100 | grep -i "cron\|scheduler\|drift"

# Trigger manuale per test
curl -X POST http://localhost/api/agents/agent_infra/run \
  -H "Authorization: Bearer <JWT>"
```

**D: Perché `triggeredBy` è `'manual'|'cron'`?**
R: Permette di distinguere nel log/dashboard i run avviati da un utente vs run autonomi. Utile per audit e per filtrare la run history nel futuro.

**D: Perché il RUN button non aggiorna la lista automaticamente?**
R: Il bottone invia una richiesta async (202 Accepted). Il run non è completato istantaneamente. Per vedere il risultato bisogna fare `GET /api/agents/:id/runs` manualmente o implementare polling/SSE (futuro).

**D: Come aggiungo un nuovo cron job?**
R:
1. Creare `portal-api/src/cron/jobs/<nome>.ts` seguendo il pattern di `infra-drift.ts`
2. Aggiungere `cron.schedule("* * * * *", runNomeJob, {timezone: TIMEZONE})` in `scheduler.ts`
3. Se il job deve aprire ADO issue, usare `createAdoIssue()` da `ado-issue.ts`
4. Committare, PR, deploy

**D: Cosa succede se ADO PAT scade e il cron prova ad aprire un issue?**
R: `createAdoIssue()` logga l'errore ma non fa throw — il cron job continua. Il messaggio appare nei log container: `[cron] Failed to create ADO issue: 401`.

**D: Come testo il RUN button in locale?**
R:
```bash
# Avvia API locale
cd portal-api && npm run dev

# Testa endpoint
curl -X POST http://localhost:4000/api/agents/agent_infra/run \
  -H "Authorization: Bearer <JWT>"

# Lista runs
curl http://localhost:4000/api/agents/agent_infra/runs \
  -H "Authorization: Bearer <JWT>"
```

---

## Errori possibili

| Codice | Code | Causa | Fix |
|--------|------|-------|-----|
| 400 | `invalid_agent_id` | ID non segue pattern `agent_*` | Usare ID corretto da `/api/agents` |
| 400 | `no_action` | manifest.json senza actions | Verificare manifest agente |
| 401 | `auth_missing_token` | JWT mancante o scaduto | Ri-autenticarsi |
| 500 | `internal_error` | Errore lettura/scrittura `agent-runs.json` | Verificare permessi `/app/data/` |

---

## File correlati

- `portal-api/src/services/agent-runner.service.ts` — Core service: runAgent(), listRuns()
- `portal-api/src/routes/agentRuns.ts` — Route POST /:id/run + GET /:id/runs
- `portal-api/src/controllers/agentRunsController.ts` — Handler validazione + response
- `portal-api/src/cron/scheduler.ts` — node-cron scheduler
- `portal-api/src/cron/ado-issue.ts` — ADO Bug creation
- `portal-api/src/cron/jobs/` — 3 job files (infra-drift, openapi-validate, sprint-report)
- `portal-api/src/repositories/types.ts` — AgentRun interface
- `apps/portal-frontend/src/utils/pages-renderer.ts` — renderDataList + rowActions
- `apps/portal-frontend/public/pages/backoffice-agents.json` — Config pagina con rowActions
