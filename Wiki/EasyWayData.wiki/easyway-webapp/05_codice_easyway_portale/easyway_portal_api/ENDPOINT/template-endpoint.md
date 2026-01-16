---
id: ew-template-endpoint
title: template endpoint
tags: [domain/frontend, layer/spec, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: Template standard per documentare endpoint: struttura, best practice, test e snippet.
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
Di seguito il **template standard** per documentare ogni endpoint parametrico in EasyWay Data Portal,  
**pronto da incollare in Wiki/README** e da seguire per ogni API “vera”.

```sql
### ENDPOINT: [HTTP_VERB] `/api/your-endpoint`

**Descrizione**
> [Breve descrizione della funzione dell’endpoint.  
Esempio: “Restituisce la configurazione di branding (colori, etichette, immagini, path) per il tenant corrente.”]

```sql

**Best Practice**
- Validazione degli input (header, parametri, body) obbligatoria
- L’header `X-Tenant-Id` deve sempre essere presente e valido
- Gestione esplicita degli errori (404 se config mancante, 400 su input errato, 500 per errori interni)
- Risposta sempre in JSON, coerente con le tipizzazioni definite in `/types/config.d.ts`
- Logging di accesso ed errori tramite logger centralizzato
- Ogni endpoint deve poter essere testato tramite Postman/cURL (testabilità garantita)

---

**Cosa fa tecnicamente**
1. Estrae il `tenantId` tramite middleware multi-tenant
2. [Esegue le operazioni specifiche — es: lettura config YAML, query DB, ecc.]
3. Restituisce la risposta JSON strutturata (o errore gestito)

---

**Come si testa**
- Avvia il backend (`npm run dev`)
- Esegui una richiesta `[HTTP_VERB]` su `/api/your-endpoint`  
  con header `X-Tenant-Id: [nome_tenant]`
- [Se necessario: aggiungi body, querystring, ecc.]
- Risposta attesa:  
  ```json
  {
    // Esempio di risposta attesa
  }

Risposta in caso di errore:
{
  "error": "Messaggio di errore"
}

Esempio chiamata (curl/Postman)
curl -X [HTTP_VERB] "http://localhost:3000/api/your-endpoint" \
  -H "X-Tenant-Id: tenant01"
  [--data '{"param": "value"}']


---

**Puoi copiarlo e riutilizzarlo identico per ogni endpoint futuro.  
Pronto a produrre subito il prossimo endpoint (es: GET `/api/config` da DB)?**

```sql

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








