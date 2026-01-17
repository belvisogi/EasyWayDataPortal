---
id: ew-checklist-di-test-api
title: checklist di test api
summary: 'Documento su checklist di test api.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/howto, audience/dev, audience/ops, privacy/internal, language/it, checklist]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Howto|Howto]]

## Checklist di test API (EasyWay Data Portal)

1. **Validazione input**
   - ❑ Richiesta con dati validi restituisce 2xx e il risultato atteso
   - ❑ Richiesta con dati non validi restituisce errore 400 con dettaglio chiaro

2. **Multi-tenant enforced**
   - ❑ Senza header `X-Tenant-Id` → errore 400
   - ❑ Con tenant valido → solo dati del tenant

3. **Chiamata Store Procedure**
   - ❑ L’API chiama effettivamente la SP core (log presente su DB)
   - ❑ Parametri REST mappati 1:1 su parametri SP
   - ❑ Ogni default, NDG, validazione logica è rispettata come da DB

4. **Logging**
   - ❑ Ogni chiamata è loggata su `PORTAL.STATS_EXECUTION_LOG` (SP + errori)
   - ❑ Log in file JSON `business.log.json` (privo di dati sensibili)
   - ❑ Eventuali errori sono loggati (sia su file che su tabella)

5. **Edge case / errori**
   - ❑ Parametri mancanti, invalidi, valori ai limiti
   - ❑ Errori della SP correttamente gestiti (500 o messaggio specifico)
   - ❑ Nessuna informazione sensibile in risposta o log

6. **Sicurezza**
   - ❑ Nessun dato sensibile in chiaro nei log/esportazioni
   - ❑ Accessi e permessi sempre validati via ACL/profili

7. **Automazione**
   - ❑ Test automatici o collection Postman eseguibili e versionate
   - ❑ Pipeline DevOps verifica successo/fallimento

8. **Documentazione**
   - ❑ Endpoint, input/output, errori, logica sempre documentati nella Wiki
   - ❑ Eventuali deviazioni, workaround, edge case riportati subito in doc



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


