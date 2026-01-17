---
id: ew-convenzioni-rest-e-naming
title: convenzioni rest e naming
summary: 'Documento su convenzioni rest e naming.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it, api, rest, naming]
title: convenzioni rest e naming
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

## Convenzioni REST EasyWay

- **Path sempre in minuscolo**, separatore trattino
  - Es: `/api/onboarding`, `/api/users/:user_id`, `/api/profiles`
- **Verbi HTTP standard**
  - GET → lettura
  - POST → creazione
  - PUT → modifica/aggiornamento
  - DELETE → soft delete/disattivazione
- **Parametri path sempre dopo `/api/` e prima delle azioni**
  - `/api/user/:user_id/profiles`
- **Header custom sempre con “X-”**
  - `X-Tenant-Id`, `X-Request-Id`
- **Body sempre JSON**
- **Errori sempre con struttura coerente:**
  ```json
  {
    "error": "Messaggio chiaro",
    "details": [ ... ] // opzionale
  }
   ```

*   **Nessun dato sensibile nei body o log**
    
*   **Input/output tipizzato e validato con schema TypeScript/Zod**
    
*   **Ogni endpoint REST mappa direttamente una SP core**




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?









