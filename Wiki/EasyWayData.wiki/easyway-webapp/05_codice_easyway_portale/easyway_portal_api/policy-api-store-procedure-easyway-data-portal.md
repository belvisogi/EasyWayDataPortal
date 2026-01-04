---
id: ew-policy-api-store-procedure-easyway-data-portal
title: policy api store procedure easyway data portal
tags: [privacy/internal, language/it]
owner: team-platform---
# Policy API/Store Procedure — EasyWay Data Portal

## Principio Guida

Tutta la business logic principale di EasyWay Data Portal risiede **nelle Store Procedure (SP) del database**.  
Le API backend **non contengono regole o logiche complesse**:  
si limitano a **orchestrare le chiamate alle SP**, validare l’input, gestire autenticazione e logging conversazionale.

summary: TODO - aggiungere un sommario breve.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

## Vantaggi del modello

- **Centralizzazione delle regole**:  
  Ogni logica (onboarding, ACL, auditing, preferenze, notifica, ecc.) vive solo su una SP,  
  evitando duplicazioni o divergenze tra codice e dati.
- **Evoluzione rapida**:  
  Modifiche a una SP sono subito attive per tutte le API che la chiamano,  
  senza bisogno di deployare di nuovo il backend.
- **Audit e compliance**:  
  Tutte le operazioni critiche sono tracciate dal DB,  
  con logging, auditing e security policy definite una volta sola.
- **Chiarezza e onboarding**:  
  Gli sviluppatori backend si concentrano su orchestrazione, validazione e logging,  
  chi lavora sul DB può evolvere la logica senza impattare le API.

---

## Pattern operativo

1. **Chiamata API**:  
   L’utente (o agent) invia una richiesta REST all’endpoint (es: `/api/onboarding`).
2. **Validazione e logging**:  
   Il backend verifica l’input (middleware, validator), logga l’azione (conversational/agent-aware).
3. **Chiamata Store Procedure**:  
   Il controller esegue la SP di riferimento (`PORTAL.sp_debug_register_tenant_and_user` e simili),  
   passando tutti i parametri richiesti dal modello dati.
4. **Risposta e logging**:  
   Il risultato della SP viene restituito all’API e loggato secondo policy di auditing/conversational.
5. **Modifiche alla logica**:  
   Tutto ciò che riguarda la business rule si aggiorna solo a livello di SP.

---

## Esempio pratico

```ts
// Chiamata API (controller)
await pool.request()
  .input("tenant_id", sql.NVarChar, tenantId)
  .input("user_email", sql.NVarChar, user_email)
  .input("profile_id", sql.NVarChar, profile_id)
  .execute("PORTAL.sp_debug_register_tenant_and_user");
```sql

_La SP si occupa di tutte le regole: validazione, insert, auditing, ACL, logging su DB…_

* * *

Best Practice
-------------

*   **Ogni endpoint API deve chiamare solo la SP di riferimento,**  
    senza replicare logiche di business lato Node.js.
    
*   **Documenta sempre la relazione “API → Store Procedure”** in modo chiaro (Wiki, codice, README).
    
*   **Le evoluzioni di business rule avvengono a livello di SP:**  
    le API backend restano leggere, manutenibili, sicure.
    
*   **Tutti i controller devono gestire errori SP e logging in modo conversational/agent-aware.**

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?







