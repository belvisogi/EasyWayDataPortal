---
id: ew-esempio-integrazione-shopify
title: esempio integrazione shopify
summary: 'Documento su esempio integrazione shopify.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it, api, integration, shopify]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

# Integrazione Shopify – Dettaglio & Esempio Pratico

## Overview

L’integrazione Shopify permette di:
- Sincronizzare ordini, prodotti e clienti dal marketplace Shopify al portale (analisi, arricchimento, dashboard)
- Automatizzare workflow (import dati, notifiche, arricchimento profili)
- Supportare più negozi/tenant, mantenendo separazione logica tra clienti

## Tabella Integrazione Shopify

| Aspetto            | Descrizione                                                      |
|--------------------|------------------------------------------------------------------|
| Endpoint principali| /admin/api/2024-04/orders.json, /products.json, /customers.json  |
| Autenticazione     | OAuth2 (consigliato), oppure API Key e password (solo legacy)    |
| Modalità           | Batch sync (periodico), real-time via Webhook, manual trigger    |
| Mapping tenant     | Ogni chiamata è legata a tenant_id/negozio specifico             |
| Policy sicurezza   | Token/API key solo in Key Vault, logging chiamate e errori       |
| Rate limit         | 2 requests/sec per endpoint (Shopify), backoff su errore 429     |
| Sandbox            | Usare dev store Shopify per test, mai fare prove su shop reale   |

---

## Esempio Pratico – Recupero Ordini (API)

### 1. **Chiamata GET ordini da Shopify**

**Endpoint:**  
`GET https://<shop>.myshopify.com/admin/api/2024-04/orders.json?status=any&limit=5`

**Header:**  

X-Shopify-Access-Token: <token_sicuro_salvato_in_KeyVault>  
Content-Type: application/json



### 2. **Esempio request (pseudo-codice Node.js/JS)**

```js
const axios = require('axios');
const accessToken = process.env.SHOPIFY_TOKEN; // Recuperato da Key Vault in produzione

const shop = 'nome-shop';
const url = `https://${shop}.myshopify.com/admin/api/2024-04/orders.json?status=any&limit=5`;

const response = await axios.get(url, {
  headers: {
    'X-Shopify-Access-Token': accessToken,
    'Content-Type': 'application/json'
  }
});
// Esempio logging:
console.log({
  event: 'shopify_fetch_orders',
  shop,
  tenant_id: 'CDI000001234',
  count: response.data.orders.length,
  status: response.status,
  timestamp: new Date().toISOString()
});
```sql

3. **Esempio risposta JSON (semplificata)**
```sql
{
  "orders": [
    {
      "id": 123456789,
      "created_at": "2025-07-21T10:20:00+02:00",
      "total_price": "39.99",
      "customer": {
        "id": 99887766,
        "email": "cliente@email.it",
        "first_name": "Mario",
        "last_name": "Rossi"
      },
      "line_items": [
        { "name": "T-Shirt Blu", "quantity": 2 }
      ],
      "financial_status": "paid"
    }
    // ...
  ]
}
```sql
4. **Mapping dati e logica applicativa**

| Campo Shopify | Campo EasyWay Data Portal | Note mapping |
| --- | --- | --- |
| id (ordine) | order_id | Unico per shop/tenant |
| created_at | order_date | UTC standard |
| total_price | total_price | Converte in formato standard |
| customer.email | customer_email | Email masking per privacy |
| line_items | prodotti | Mapping prodotti con codice interno |
| financial_status | payment_status | Mapping dominio valori interno |

### 5. **Logging e gestione errori**
*   Loggare **ogni sync**: esito, count ordini, tenant/shop, timestamp, eventuali errori (es. 401, 429).
    
*   **Gestione errori:**
    *   401/403 → alert admin e blocco sync su tenant
        
    *   429 → retry con backoff esponenziale
        
    *   Qualsiasi errore fatale: log in `portal-audit`, alert, e chiusura batch
        

### 6. **Best practice security**

*   **Token sempre in Key Vault,** mai in codice/config file.
    
*   **Ogni chiamata API deve portare anche il tenant_id** (per logging e separazione).
    
*   **Abilitare Webhook Shopify** per sync real-time di ordini/eventi rilevanti.
    

### 7. **Flusso sintesi (testuale)**
```sql
[EasyWay Portal] → [Microservizio Shopify] → [Shopify API]
      |
      v
[Recupera token sicuro] → [Effettua chiamata GET] → [Valida e mappa dati] → [Logga evento] → [Aggiorna DB]
      |
      +--> [Se errore → logga, allerta admin, gestisce retry]
```sql

Nota operativa
--------------

*   **Per ogni nuovo shop/tenant**, va generato token OAuth dedicato e salvato in Key Vault associato al tenant_id.
    
*   Prima di andare in produzione, testare tutte le chiamate in ambiente Shopify dev/store di prova.
    
*   Tieni traccia dei mapping tra campi Shopify e DB del portale, aggiornando documentazione a ogni nuova release API.



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








