---
title: "Knowledge API — Guida GET /api/knowledge"
created: 2026-02-26
updated: 2026-02-26T00:00:00Z
status: active
category: guide
domain: api
tags: [knowledge, qdrant, rag, api, machine-to-machine, full-text-search]
priority: high
audience:
  - developers
  - agents
  - system-architects
id: ew-guide-knowledge-api
summary: >
  Guida completa all'endpoint GET /api/knowledge: cos'è, perché esiste,
  come funziona il full-text search su Qdrant senza python3,
  autenticazione machine-to-machine X-EasyWay-Key, Q&A operativi.
owner: team-platform
related:
  - [[agents/platform-operational-memory]]
  - [[api/rest-errors-qna]]
llm:
  include: true
  pii: low
  chunk_hint: 300-400
  redaction: [api_key]
type: guide
---

# Knowledge API — Guida GET /api/knowledge

## Cosa è

`GET /api/knowledge` è un endpoint REST pubblico (machine-to-machine) che espone la ricerca full-text sul knowledge base di EasyWay (collezzione Qdrant `easyway_wiki`).

Permette ad agenti, script, e tool esterni di interrogare i 121k+ chunk della wiki indicizzati in Qdrant, senza dipendenze Python o modelli ML nell'API Node.js.

### Caratteristiche principali
- **Full-text search** su campo `content` tramite Qdrant native filter (`match: {text: ...}`)
- **Autenticazione M2M** tramite header `X-EasyWay-Key` (non JWT)
- **Zero dipendenze Python** nel container API (`node:20-alpine`)
- **Timeout 20s** con gestione esplicita `AbortSignal`
- **Limite query**: max 500 caratteri, max 20 risultati per chiamata

---

## Perché esiste

### Il problema
Gli agenti L2/L3 di EasyWay usano RAG (`Invoke-RAGSearch.ps1`) che chiama `python3` sul server. Questo funziona per i runner PowerShell sul server stesso, ma:

1. Il container API (`node:20-alpine`) **non ha python3** — `execFile('python3', ...)` produce `ENOENT`
2. Non c'è modo di chiamare RAG da tool esterni (CI/CD, curl, altri servizi) senza Python
3. I team/agenti che vogliono "chiedere alla wiki" dovevano accedere direttamente a Qdrant

### La soluzione
Un endpoint REST che espone il knowledge base con autenticazione API key (non JWT), utilizzabile da qualsiasi client HTTP:
- Agenti che vogliono cross-domain RAG
- Pipeline CI/CD che controllano la documentazione
- Tool di monitoraggio e auditing
- Test E2E che validano la coerenza della conoscenza

---

## Come funziona

### Architettura

```
Client (curl/agent)
  │  X-EasyWay-Key: <key>
  │  GET /api/knowledge?q=qdrant+ingest&k=5
  ▼
Express API (/api/knowledge)
  │  auth.ts: X-EasyWay-Key check → req.user = {sub:'machine', tenantId:'system'}
  ▼
knowledgeController.ts
  │  Valida q (required, ≤500 char), k (default 5, max 20)
  ▼
qdrantTextSearch()
  │  POST http://qdrant:6333/collections/easyway_wiki/points/scroll
  │  body: { filter: { must: [{key:"content", match:{text:q}}] }, limit:k, with_payload:true }
  ▼
Qdrant (full-text index su campo 'content')
  │  Ritorna punti filtrati con payload {filename, path, content, chunk_index}
  ▼
Response JSON: {query, results:[{filename,path,content,chunk_index,score}], count}
```

### Autenticazione M2M

```typescript
// In auth.ts — PRIMA del check JWT
const apiKey = req.headers["x-easyway-key"];
const configuredKey = process.env.EASYWAY_API_KEY;
if (apiKey && configuredKey && apiKey === configuredKey) {
  req.user = { sub: "machine", ew_tenant_id: "system" };
  req.tenantId = "system";
  return next();  // bypass JWT
}
```

L'env var `EASYWAY_API_KEY` è in `/opt/easyway/.env.secrets` sul server.

### Qdrant full-text search

Qdrant supporta ricerca full-text nativa sul payload, ma **richiede un text index** esplicito sul campo:

```bash
# Creare text index (una-tantum sul server)
curl -X PUT http://localhost:6333/collections/easyway_wiki/index \
  -H "api-key: $QDRANT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"field_name":"content","field_schema":"text"}'
```

Senza l'indice, Qdrant risponde `400 Bad Request: Index required for payload search`.

### Request/Response

**Request:**
```
GET /api/knowledge?q=deploy+workflow&k=3
X-EasyWay-Key: <EASYWAY_API_KEY>
```

**Response:**
```json
{
  "query": "deploy workflow",
  "count": 3,
  "results": [
    {
      "filename": "platform-operational-memory.md",
      "path": "agents/platform-operational-memory.md",
      "content": "...(primi 800 char del chunk)...",
      "chunk_index": 12,
      "score": null
    }
  ]
}
```

> **Nota**: `score` è `null` perché la ricerca usa `scroll` (full-text filter) non la similarity search vettoriale. I risultati sono non-ranked, filtrati per match testuale.

---

## Configurazione server

| Env var | Default | Note |
|---------|---------|------|
| `QDRANT_HOST` | `localhost` | Hostname Qdrant |
| `QDRANT_PORT` | `6333` | Porta Qdrant REST |
| `QDRANT_API_KEY` | `""` | API key Qdrant (in `.env.secrets`) |
| `QDRANT_COLLECTION` | `easyway_wiki` | Nome collection |
| `EASYWAY_API_KEY` | — | Obbligatorio per M2M auth |

### Docker network (CRITICO)

Il container API deve essere connesso alla rete Qdrant:
```yaml
# docker-compose.apps.yml
networks:
  easyway-net:
    external: true
  qdrant-net:
    external: true
    name: easywaydataportal_easyway-net  # nome rete Qdrant compose stack

services:
  api:
    networks:
      - easyway-net
      - qdrant-net
```

Se il container non è sulla rete Qdrant, la chiamata REST produce `ECONNREFUSED` o `ETIMEDOUT`.

---

## Q&A Operativi

**D: Perché full-text search invece di similarity vettoriale?**
R: La similarity vettoriale richiederebbe generare l'embedding della query nel container API, il che significa aggiungere un modello ML (`all-MiniLM-L6-v2`) + Python/Node binding. Il full-text search di Qdrant è efficace per query keyword-based e non ha dipendenze esterne.

**D: python3 era nel container?**
R: **No.** `node:20-alpine` è un'immagine minimale. Solo Node.js, npm, e le utility Alpine base. La versione originale del controller usava `execFile('python3', ['rag_search.py', ...])` — questo produceva `ENOENT: spawn python3` al runtime. Fix: usare `fetch()` sulla Qdrant REST API.

**D: Come verifico che il text index esiste?**
R:
```bash
curl http://localhost:6333/collections/easyway_wiki \
  -H "api-key: $QDRANT_API_KEY" | python3 -m json.tool | grep -A5 '"payload_schema"'
```
Cerca `"content": {"data_type": "Text"}` nella risposta.

**D: Posso fare semantic search (vettoriale) invece di full-text?**
R: Con l'attuale architettura no — richiederebbe embedding nel container. Alternativa: usare `Invoke-RAGSearch.ps1` dal server PowerShell runner, che usa `python3` + `all-MiniLM-L6-v2`. Per il futuro si può aggiungere un microservizio embedding separato.

**D: Come gestisco risultati vuoti?**
R: L'endpoint restituisce `{"query":"...","count":0,"results":[]}` (200 OK). Il client deve gestire `count === 0` come "nessun documento trovato".

**D: Il rate limit si applica anche a X-EasyWay-Key?**
R: Sì. L'endpoint `/api/knowledge` passa per i limiter `tenantLimiter` e `tenantBurstLimiter` con `tenantId='system'`. Il limite è 600 req/min (steady) + 120/10s (burst) per tenant.

**D: Come testo l'endpoint in locale?**
R:
```bash
# Smoke test (richiede Qdrant in esecuzione)
curl -H "X-EasyWay-Key: test-key" \
  "http://localhost:4000/api/knowledge?q=qdrant+ingest&k=2"

# Sul server
source /opt/easyway/.env.secrets
curl -H "X-EasyWay-Key: $EASYWAY_API_KEY" \
  "http://localhost:4000/api/knowledge?q=deploy+workflow&k=3"
```

**D: Perché i risultati non sono ordinati per rilevanza?**
R: Qdrant `scroll` con filter non calcola un ranking — restituisce i punti che matchano il filter nell'ordine interno. Per il ranking, servirebbero vettori di embedding. I risultati attuali sono comunque filtrati per match testuale esatto (tokenizzato).

---

## Errori possibili

| Codice | Code | Causa | Fix |
|--------|------|-------|-----|
| 400 | `knowledge_query_required` | `q` mancante | Aggiungere `?q=...` |
| 400 | `knowledge_query_too_long` | `q` > 500 char | Ridurre query |
| 401 | `auth_missing_token` | Header `X-EasyWay-Key` assente o errato | Verificare env `EASYWAY_API_KEY` |
| 502 | `knowledge_error` | Errore Qdrant (network, index missing) | Verificare rete Docker + text index |
| 504 | `knowledge_timeout` | Qdrant non risponde in 20s | Verificare container Qdrant up |

---

## File correlati

- `portal-api/src/controllers/knowledgeController.ts` — Implementazione full-text search
- `portal-api/src/routes/knowledge.ts` — Route definition
- `portal-api/src/middleware/auth.ts` — X-EasyWay-Key check
- `portal-api/openapi/openapi.yaml` — Schema OpenAPI `/api/knowledge`
- `agents/skills/retrieval/Invoke-RAGSearch.ps1` — Alternativa lato PowerShell (usa python3)
