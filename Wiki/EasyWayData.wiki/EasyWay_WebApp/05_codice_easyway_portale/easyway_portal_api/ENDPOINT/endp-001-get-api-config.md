---
id: ew-endp-001
title: GET /api/config
summary: Restituisce la configurazione dinamica del portale per il tenant corrente.
status: draft
owner: team-api
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - domain/webapp
  - layer/reference
  - artifact/endpoint
  - audience/dev
  - privacy/internal
  - language/it
intents:
  - ottenere configurazione portale del tenant
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: [api-config]
id: ew-endp-001-get-api-config
title: endp 001 get api config
summary: 
owner: 
---
### ENDPOINT: GET `/api/config`

**Descrizione**
> Restituisce la configurazione dinamica per il tenant corrente, leggendo dalla tabella `PORTAL.CONFIGURATION`.  
> Permette di ottenere tutti i parametri o filtrarli per sezione (`?section=nome_sezione`).

---

**Best Practice**
- Richiede header `X-Tenant-Id`
- Permette filtro opzionale via querystring (`?section=feature_toggle`, ecc.)
- Risposta 404 se nessuna config trovata per tenant/section
- Gestione chiara degli errori
- Risposta sempre JSON (`{ "config_key": "config_value", ... }`)

---

**Cosa fa tecnicamente**
1. Estrae `tenantId` dal middleware
2. Legge (opzionalmente) il parametro `section` dalla querystring
3. Interroga la tabella `PORTAL.CONFIGURATION` per quel tenant e sezione
4. Ritorna i parametri come oggetto chiave/valore

---

**Come si testa**
- Avvia il backend (`npm run dev`)
- Esegui una GET su `/api/config` con header `X-Tenant-Id: tenant01`
- (Opzionale) Aggiungi `?section=feature_toggle` alla URL
- Risposta attesa (esempio):
  ```json
  {
    "enable_data_quality": "true",
    "max_file_size": "1048576"
  }
  ```
- Risposta errore:
  ```json
  { "error": "No configuration found for this tenant/section" }
  ```
- Esempio chiamata:

  ```json
     curl -X GET "http://localhost:3000/api/config?section=feature_toggle" \
     -H "X-Tenant-Id: tenant01"
  ```

---

**Con questo hai un endpoint parametrico, dinamico e multi-tenant  
- stesso pattern riusabile per ogni futura configurazione!**






## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

