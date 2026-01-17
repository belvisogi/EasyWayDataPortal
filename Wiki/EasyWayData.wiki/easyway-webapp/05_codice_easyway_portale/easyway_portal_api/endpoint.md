---
id: ew-endpoint-overview
title: Endpoint – Introduzione
summary: Primo endpoint parametrico: collega multi-tenant, config e API REST in un esempio completo.
status: active
owner: team-api
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/frontend, layer/reference, audience/dev, privacy/internal, language/it]
title: endpoint
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/frontend|frontend]] > [[Layer - Reference|Reference]]

È il **primo vero endpoint parametrico** del backend EasyWay.  
Mette insieme TUTTO quello che hai preparato finora (multi-tenant, lettura YAML, API REST) e lo espone come servizio.
**Perché è il risultato degli step precedenti:**
*   Senza la struttura standard (step 1), non potresti gestire il progetto e le dipendenze
    
*   Senza la struttura src e i middleware (step 2), non potresti essere multi-tenant o avere logging/monitoring robusti
    
*   Senza i loader di config (step 3), non potresti mai leggere i parametri dinamici di branding o label
    
**Dove va nell’indice/funzionalità?**
*   **È la PRIMA API “vera”** e rappresenta **l’inizio della business logic** parametrica di EasyWay
    
*   Puoi considerarla una **appendice pratica** agli step di configurazione  
    oppure come **“Step 4: Primo endpoint parametrico multi-tenant”**


## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?










