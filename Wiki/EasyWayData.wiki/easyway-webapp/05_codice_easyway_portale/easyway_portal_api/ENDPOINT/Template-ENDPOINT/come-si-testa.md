---
id: ew-come-si-testa
title: come si testa
tags: [domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it, api, testing]
owner: team-platform
summary: 'Documento su come si testa.'
status: active
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Howto|Howto]]

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


## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.


