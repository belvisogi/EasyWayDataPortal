---
title: n8n API Error Triage
tags: [domain/control-plane, layer/orchestration, audience/dev, privacy/internal, language/it, n8n, api, errors]
status: active
updated: 2026-01-16
redaction: [email, phone, token]
id: ew-n8n-api-error-triage
chunk_hint: 200-300
entities: []
include: true
summary: Orchestrazione agentica per classificare errori REST e produrre log strutturato per n8n.
llm: 
pii: none
owner: team-platform

llm:
  include: true
  chunk_hint: 5000---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Orchestration|Orchestration]]

# n8n API Error Triage

## Domande a cui risponde
1. Cosa fare se n8n riceve un errore 401/403 dalle API?
2. Come classificare un errore come "retryable"?
3. Dove trovo lo schema dell'intent di triage?

## Contesto
Questo workflow serve quando n8n chiama le REST API del portale e incontra errori. L'obiettivo e' standardizzare il triage con un agente dedicato, produrre azioni suggerite e log strutturati per audit e miglioramento continuo.

## Source of truth (WHAT-first)
- Orchestrazione: `docs/agentic/templates/orchestrations/api-error-triage.manifest.json`
- Intent: `docs/agentic/templates/intents/api.error.triage.intent.json`

## Quando usarlo
- Errori 4xx/5xx o timeout durante chiamate REST da n8n.
- Analisi rapida per capire se l'errore e' retryable, di autenticazione o di payload.

## Input (intent JSON)
Esempio minimo:
```json
{
  "id": "api.error.triage",
  "correlationId": "corr-123",
  "decision_trace_id": "trace-001",
  "params": {
    "source": "n8n",
    "service": "easyway-portal-api",
    "environment": "dev",
    "request": {
      "method": "GET",
      "url": "https://api.example.local/api/db/diagram?schema=PORTAL",
      "headers": { "accept": "application/json", "authorization": "Bearer <token>" }
    },
    "response": {
      "status": 401,
      "duration_ms": 412
    },
    "error": {
      "code": "AUTH_MISSING",
      "message": "token missing"
    }
  }
}
```sql

## Output atteso
- `errorClass`, `severity`, `retryable`
- `recommendedActions[]`
- `normalizedEvent` con headers redatti (Authorization/Cookie/X-API-Key)
- `logPath` in `agents/logs/events.jsonl` (se `-LogEvent`)

## Esecuzione locale (manuale)
```powershell
pwsh scripts/agent-api.ps1 -Action api-error:triage -IntentPath out/api-error.intent.json -LogEvent
```sql

## Riferimenti
- Q&A errori REST: `Wiki/EasyWayData.wiki/api/rest-errors-qna.md`


## Vedi anche

- [Orchestratore n8n (WHAT)](./orchestrator-n8n.md)
- [n8n-db-ddl-inventory](./n8n-db-ddl-inventory.md)
- [n8n-db-table-create](./n8n-db-table-create.md)
- [n8n Retrieval Bundles (riduzione token)](./n8n-retrieval-bundles.md)
- [Release Preflight Security (WHAT)](./release-preflight-security.md)




