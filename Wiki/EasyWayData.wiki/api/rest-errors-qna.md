---
id: ew-api-rest-errors-qna
title: QnA - Errori REST API (EasyWay Portal)
summary: QnA operativa sugli errori REST API piu' comuni (cause e azioni) per utenti e agenti.
status: draft
owner: team-platform
tags: [domain/api, layer/howto, audience/non-expert, audience/dev, audience/dba, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-06'
next: Allineare con OpenAPI e aggiungere esempi per ogni endpoint critico.
---

# QnA - Errori REST API (EasyWay Portal)

## Contesto (repo)
- Source-of-truth API: `EasyWay-DataPortal/easyway-portal-api/openapi/openapi.yaml`
- Implementazione API: `EasyWay-DataPortal/easyway-portal-api/src/routes/`
- Auth middleware: `EasyWay-DataPortal/easyway-portal-api/src/middleware/auth.ts`
- Tenant extraction: `EasyWay-DataPortal/easyway-portal-api/src/middleware/tenant.ts`
- Viewer DB diagram: `GET /api/db/diagram` + `GET /portal/tools/db-diagram`

## Q&A (errori ricorrenti)

### 401 Unauthorized
Q: Perche' ricevo 401?
A: Manca il token Bearer o e' scaduto. Verifica header `Authorization: Bearer <token>` e che `AUTH_ISSUER/AUTH_AUDIENCE/JWKS` siano configurati.
Azioni:
- Rifai login (MSAL) e rigenera token.
- In dev, usa `AUTH_TEST_JWK(S)` per token locali.

### 403 Forbidden
Q: Perche' ricevo 403?
A: Token valido ma senza scope/ruolo richiesto (policy o gate a livello endpoint).
Azioni:
- Controlla claim nel token (ruoli/scopes).
- Verifica le policy lato API o gateway.

### 400 Bad Request
Q: Perche' ricevo 400?
A: Payload o parametri non validi (schema/validation).
Azioni:
- Confronta request con `openapi.yaml`.
- Controlla formato JSON e campi obbligatori.

### 404 Not Found
Q: Perche' ricevo 404?
A: Endpoint o risorsa non esiste.
Azioni:
- Verifica path e base URL.
- Per `/api/db/diagram`, controlla che esista `EasyWay-DataPortal/easyway-portal-api/data/db/portal-diagram.json`.

### 429 Too Many Requests
Q: Perche' ricevo 429?
A: Rate limit attivo.
Azioni:
- Riduci il numero di richieste.
- Aumenta i limiti in `RATE_LIMIT_*` (solo se approvato).

### 500 Internal Server Error
Q: Perche' ricevo 500?
A: Errore non gestito lato server (config o bug).
Azioni:
- Verifica logs e `X-Request-Id`.
- Controlla variabili d'ambiente richieste.

### 502/503
Q: Perche' ricevo 502/503?
A: Servizio a monte non disponibile o in deploy.
Azioni:
- Ritenta dopo pochi secondi.
- Verifica stato app e health endpoint.

### CORS error (browser)
Q: Perche' ho errore CORS?
A: Origin non autorizzata.
Azioni:
- Aggiorna `ALLOWED_ORIGINS`.
- Verifica che la UI usi l'origin corretto.

### Tenant claim mancante
Q: Perche' l'API non capisce il tenant?
A: Mancano i claim previsti (es. `TENANT_CLAIM`).
Azioni:
- Controlla issuer e claim mapping.
- Verifica `TENANT_CLAIM` in env.

## Note
- In ambiente enterprise, gli errori devono essere tracciabili con `X-Request-Id`.
- Se un errore diventa ricorrente, aggiungi una KB recipe dedicata.

## Formato errore standard
Le API restituiscono un payload coerente:
```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": []
  },
  "requestId": "uuid",
  "correlationId": "uuid"
}
```
