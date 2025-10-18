---
id: ew-api-invio-notifica
title: api invio notifica
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - layer/reference
  - privacy/internal
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
id: ew-api-invio-notifica
title: api invio notifica
summary: 
owner: 
---
**A. Obiettivo**
----------------

*   Esporre un endpoint REST per inviare (o simulare l’invio) di una notifica a uno o più utenti
    
*   Mappare la chiamata alla stored procedure (core o debug, secondo ambiente)
    
*   Loggare ogni azione (audit & business log), senza mai scrivere dati sensibili
    

* * *

**B. Endpoint POST `/api/notifications/send`**
----------------------------------------------

* * *

### **1. Schema di validazione**

`src/validators/notificationValidator.ts`

```sql
export const sendNotificationSchema = z.object({
  recipients: z.array(z.string().min(6).max(64)), // array di user_id
  category: z.string().min(3).max(32),   // es: "ALERT"
  channel: z.string().min(3).max(16),    // es: "EMAIL", "SMS"
  message: z.string().min(1).max(1024),
  ext_attributes: z.record(z.any()).optional()
});

```sql
### **2. Controller**

`src/controllers/notificationsController.ts`

```sql
import { Request, Response } from "express";
import sql from "mssql";
import { logger } from "../utils/logger";

export async function sendNotification(req: Request, res: Response) {
  const pool = await sql.connect(process.env.DB_CONN_STRING!);
  const tenantId = (req as any).tenantId;
  const { recipients, category, channel, message, ext_attributes = {} } = req.body;

  try {
    // Per ogni destinatario, chiama la SP (o batch, secondo design DB)
    for (const user_id of recipients) {
      await pool.request()
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("user_id", sql.NVarChar, user_id)
        .input("category", sql.NVarChar, category)
        .input("channel", sql.NVarChar, channel)
        .input("message", sql.NVarChar, message)
        .input("ext_attributes", sql.NVarChar, JSON.stringify(ext_attributes))
        .execute("PORTAL.sp_send_notification");
    }

    logger.info("Notification sent", {
      tenantId,
      recipientsCount: recipients.length,
      category,
      channel,
      event: "NOTIFY_SEND",
      time: new Date().toISOString()
    });

    res.status(200).json({ ok: true, sent: recipients.length });

  } catch (err: any) {
    logger.error("Send notification failed", {
      tenantId,
      error: err.message,
      event: "NOTIFY_SEND_ERROR",
      time: new Date().toISOString()
    });
    res.status(500).json({ error: err.message });
  }
}

```sql

### **3. Rotta**

`src/routes/notifications.ts`  
_(aggiungi accanto a subscribe)_

```sql
import { sendNotification } from "../controllers/notificationsController";
import { sendNotificationSchema } from "../validators/notificationValidator";

router.post("/send", validateBody(sendNotificationSchema), sendNotification);

```sql


### ENDPOINT: POST `/api/notifications/send`

**Descrizione**  
Invia (o simula l’invio) una notifica a uno o più utenti,  
mappando la chiamata alla store procedure `PORTAL.sp_send_notification`.

**Validazione**  
- recipients: array di user_id, obbligatorio
- category, channel, message: obbligatori, validati per lunghezza/formato

**Logging**
- Log business su file/console (event: NOTIFY_SEND)
- Errori loggati, mai dati sensibili

**Test**
- POST `/api/notifications/send`  
  Body:
  ```json
  {
    "recipients": ["USR000001", "USR000002"],
    "category": "ALERT",
    "channel": "EMAIL",
    "message": "Messaggio di esempio",
    "ext_attributes": { "source": "system" }
  }
  ```
Risposta 200 OK, o 500 in caso di errore



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

