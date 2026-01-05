---
id: ew-api-onboarding
title: api onboarding
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it, api, onboarding]
title: api onboarding
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
### ENDPOINT: POST `/api/onboarding`

**Descrizione**  
Permette di registrare un nuovo tenant + user in un colpo solo.  
Chiamata REST che mappa la store procedure core di onboarding (`PORTAL.sp_debug_register_tenant_and_user`).

**Best Practice**
- Input sempre validato (zod, middleware)
- Log in `PORTAL.STATS_EXECUTION_LOG` (via SP) con esito, tempi, parametri, eventuale errore
- Logging applicativo solo info chiave (mai dati sensibili)

**Come si testa**
- POST `/api/onboarding` con JSON body:
  ```json
  {
    "tenant_name": "Nuovo Cliente Srl",
    "user_email": "amministratore@nuovocliente.it",
    "display_name": "Mario Rossi",
    "profile_id": "ADMIN",
    "ext_attributes": { "source": "web", "ip": "1.2.3.4" }
  }
  ```
*   Risposta 201 OK con result.
    
*   In caso di errore: 500 + messaggio.
    

yaml

CopyEdit

`---  ### **STOP**`


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?







