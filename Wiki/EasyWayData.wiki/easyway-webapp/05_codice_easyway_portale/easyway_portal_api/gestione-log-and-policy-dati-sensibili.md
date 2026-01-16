---
id: ew-gestione-log-and-policy-dati-sensibili
title: gestione log and policy dati sensibili
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it]
owner: team-platform
summary: Policy logging e dati sensibili: livelli, retention, mascheramento e export su Datalake.
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

# Gestione Log - EasyWay Data Portal


> _Il logging non è solo un obbligo di compliance, ma la base per la sicurezza,  
> la tracciabilità e il monitoraggio intelligente della piattaforma,  
> fino all’integrazione con agenti AI, AMS, auditing e conversational intelligence._

[Segue Policy dati sensibili, automazione export, logging conversational...]

## **Principi guida**
- **Logga solo ciò che serve**, maschera tutto il resto.
- **Mai dati sensibili in chiaro** su file, Datalake, o esportazione.
- **Documenta la policy**: scrivi sempre cosa si può loggare e come si mascherano i dati.
- Tutti i log business/audit sono in formato JSON e pronti per essere esportati su Datalake.

## **Tipi di log gestiti**

| Tipo                | Dove va                         | Livello | Retention | Destinazione finale         |
|---------------------|---------------------------------|---------|-----------|----------------------------|
| Log applicativo     | Console, file locale            | info, error, warn, debug | 7gg     | Solo DEV/Debug             |
| Log business/audit  | File JSON (`logs/business.log.json`) | info, error         | 30gg    | Datalake, BI, auditing     |
| Log tecnico/trace   | File locale, Log Analytics (solo warning/error) | warning, error | 3gg     | Log Analytics (con filtro) |

---

## **Policy dati sensibili**
- **Password, hash, CF, IBAN, dati sanitari**: **NON devono mai apparire nei log.**
- **Email, nomi**: Devono essere **mascherati** o pseudonimizzati (vedi funzione `maskEmail` in `/utils/logUtils.ts`).
- **Solo ID interni e chiavi tecniche nei log standard.**

---

## **Best practice**
- **Logging a livelli differenti** in base all’ambiente (`LOG_LEVEL` via .env/config)
- **Rotazione automatica** dei file di log (no log “giganti”)
- **Log di errore e business in file separati**
- **Esportazione dei log business/audit su Datalake** (via pipeline/script)
- **Controllo accessi**: Solo gruppi tecnici possono leggere i log completi

---

## **Snippet esempio log business**
```json
{
  "level": "info",
  "message": "User created",
  "tenantId": "tenant01",
  "userEmail": "j****e@easyway.com",  // Mascherato!
  "event": "USER_CREATE",
  "time": "2025-07-27T12:34:56.789Z"
}
```sql

**Workflow export log**
-----------------------

1.  I log business/audit vengono scritti in `logs/business.log.json`
    
2.  Una pipeline automatica copia periodicamente i file log su Datalake (`/portal-logs/`)
    
3.  Log business e audit sono pronti per analisi, compliance, auditing — e **mai contengono dati sensibili**!


**Riferimenti**
---------------

*   Policy e best practice allineate con GDPR, SOC2, DORA
    
*   Vedi anche sezione “Validazione avanzata dati in ingresso” per evitare log di dati errati o rumorosi

**Best practice e check periodico**
---------------
*    Log e policy aggiornati dopo ogni refactor
    
*    Verifica periodica di mascheramento dati su nuovi endpoint
    
*    Test export/automation sempre con dati fittizi/anonimizzati
    
*    Documentazione aggiornata su ogni nuovo tipo di log




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








