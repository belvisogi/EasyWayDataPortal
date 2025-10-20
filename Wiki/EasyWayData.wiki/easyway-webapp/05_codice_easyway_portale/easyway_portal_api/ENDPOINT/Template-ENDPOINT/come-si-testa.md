---
id: ew-come-si-testa
title: come si testa
summary: 
owner: 
tags:
  - 
  - privacy/internal
  - language/it
llm:
  include: true
  pii: 
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---
**Come si testa**
-----------------

1.  Avvia il backend (`npm run dev`)
    
2.  Fai una GET su `http://localhost:3000/api/branding`  
    **con header:**  
    `X-Tenant-Id: tenant01`
    
3.  Ricevi la configurazione YAML per quel tenant come JSON.
    

* * *

**Cos’hai ottenuto**
--------------------

*   API **parametrica, multi-tenant, riusabile**
    
*   Lettura config YAML per ogni tenant, subito pronta per estendere
    
*   Pattern da replicare per ogni nuova configurazione parametrica

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

