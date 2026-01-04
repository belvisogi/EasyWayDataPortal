---
id: ew-qa-setup-and-test-locale
title: qa setup and test locale
tags: [privacy/internal, language/it]
owner: team-platform---
# EasyWay Data Portal — Q&A Setup & Test Locale

“Esportami la Q&A aggiornata dal 2025-07-28 al 2025-07-29”

## Aggiornamenti dal 2025-07-28 al 2025-07-29

summary: TODO - aggiungere un sommario breve.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

### Errore: “npm: command not found” / “node: command not found”
- **Motivo:** Node.js non è stato aggiunto al PATH di sistema dopo l’installazione.
- **Soluzione:** Riavvia il PC, oppure aggiungi manualmente `C:\Program Files\nodejs\` alla variabile d’ambiente PATH.

---

### Errore: “Could not read package.json”
- **Motivo:** Lancio di comandi npm dalla cartella sbagliata (non contiene `package.json`).
- **Soluzione:** Spostati nella cartella giusta con `cd easyway-portal-api`.

---

### Errore: “Cannot find module 'zod'”
- **Motivo:** La dipendenza `zod` non è installata.
- **Soluzione:** Lancia `npm install zod` nella cartella giusta.

---

### Errore: “ReferenceError: validateParams is not defined” / “validateBody is not defined”
- **Motivo:** Funzione middleware usata senza importarla.
- **Soluzione:** Importa la funzione mancante, es.  
  `import { validateParams, validateBody } from "../middleware/validate";`

---

### Errore: “ReferenceError: userIdParamSchema is not defined”
- **Motivo:** Schema usato senza importarlo.
- **Soluzione:** Importa lo schema dove serve, es.  
  `import { userIdParamSchema } from "../validators/userValidator";`

---

### Errore: “ReferenceError: z is not defined”
- **Motivo:** Manca import di `z` da Zod.
- **Soluzione:**  
  `import { z } from "zod";` all’inizio del file.

---

### Errore: “ReferenceError: subscribeNotification is not defined” / “controllerFunction is not defined”
- **Motivo:** Funzione controller non importata o non creata.
- **Soluzione:**  
  - Se esiste:  
    `import { subscribeNotification } from "../controllers/notificationsController";`
  - Altrimenti, usa funzione placeholder inline per test:
    ```typescript
    router.post("/subscribe", (req, res) => {
      res.status(201).json({ message: "Notifica iscrizione ricevuta!" });
    });
    ```

---

### Errore: “Cannot POST /api/notifications/subscribe” (404 Not Found)
- **Motivo:** Route non implementata o non registrata correttamente in `app.ts`.
- **Soluzione:**  
  - Implementa la route in `routes/notifications.ts`  
  - Registra la route in `app.ts` con:  
    `app.use("/api/notifications", notificationsRoutes);`

---

### Errore: “400 Bad Request: Invalid or missing X-Tenant-Id header”
- **Motivo:** Header `X-Tenant-Id` mancante, richiesto dal middleware multi-tenant.
- **Soluzione:**  
  - Aggiungi l’header nella richiesta:
    ```
    X-Tenant-Id: tenant01
    ```

---

### Errore: “Missing script: 'dev'”
- **Motivo:** Comando lanciato dalla cartella sbagliata o manca lo script in `package.json`.
- **Soluzione:**  
  - Assicurati di essere in `easyway-portal-api`  
  - Verifica che in `package.json` ci sia:
    ```json
    "scripts": {
      "dev": "ts-node-dev --respawn --transpile-only src/server.ts"
    }
    ```

---

### Come fermare e rilanciare il backend
- **Ferma:** premi `Ctrl + C` nel terminale.
- **Rilancia:** esegui di nuovo `npm run dev`.

---

### Come testare le API senza Postman
- **Crea un file `.http`** (es: `easyway-api-test.http`)
- **Installa [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)` in VSCode**
- **Scrivi le chiamate, separa con `###`, clicca su “Send Request”**

---

## **Note generali**
- **Importa sempre tutte le funzioni/schema che usi**
- **Lancia sempre i comandi dalla cartella dove c’è `package.json`**
- **Aggiorna il file `.env` con le variabili corrette**
- **Aggiungi sempre gli header richiesti dalle tue policy/middleware**
- **Se vedi “not defined”, controlla import e percorso**

---

**Prossimi aggiornamenti: aggiungi ogni nuovo errore/soluzione con data,  
per mantenere sempre questa chat come “bibbia” di setup e debug EasyWay!**



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?






