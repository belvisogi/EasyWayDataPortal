---
id: ew-api-notifiche
title: api notifiche
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [layer/reference, privacy/internal, language/it]
title: api notifiche
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
**A. Obiettivo**
----------------

*   Esporre via REST la gestione notifiche utente/tenant (es. iscrizione a notifiche, preferenze, log delle notifiche inviate)
    
*   Mappare i parametri REST alle store procedure (già definite o da aggiornare in EasyWay DB)
    
*   Loggare ogni operazione (audit & business log)
    
*   Validare e documentare tutto secondo la checklist
    

* * *

**B. Endpoints principali (Notifiche)**
---------------------------------------

*   **GET `/api/notifications`**  
    Lista notifiche inviate/pendenti per il tenant/utente
    
*   **POST `/api/notifications/subscribe`**  
    Iscrive un utente a una categoria di notifica (opt-in)
    
*   **POST `/api/notifications/send`**  
    Manda (o simula l’invio) di una notifica a uno o più utenti
    

* * *

**C. Esempio pratico: POST `/api/notifications/subscribe`**
-----------------------------------------------------------

### **1. Schema di validazione**

`src/validators/notificationValidator.ts`


```sql
import { z } from "zod";

export const subscribeSchema = z.object({
  user_id: z.string().min(6).max(64),
  category: z.string().min(3).max(32),   // es: "NEWS", "ALERT", "BILLING"
  channel: z.string().min(3).max(16)     // es: "EMAIL", "SMS", "PUSH"
});

```sql

### **2. Controller**

`src/controllers/notificationsController.ts`

```sql
import { Request, Response } from "express";
import sql from "mssql";
import { logger } from "../utils/logger";

export async function subscribeNotification(req: Request, res: Response) {
  const pool = await sql.connect(process.env.DB_CONN_STRING!);
  const { user_id, category, channel } = req.body;
  const tenantId = (req as any).tenantId;

  try {
    // Chiama la stored procedure di subscription (nome conforme a EasyWay DB)
    await pool.request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("user_id", sql.NVarChar, user_id)
      .input("category", sql.NVarChar, category)
      .input("channel", sql.NVarChar, channel)
      .execute("PORTAL.sp_subscribe_notification");

    // Log business (no dati sensibili)
    logger.info("User subscribed to notification", {
      tenantId,
      userId: user_id,
      category,
      channel,
      event: "NOTIFY_SUBSCRIBE",
      time: new Date().toISOString()
    });

    res.status(200).json({ ok: true });
  } catch (err: any) {
    logger.error("Subscription failed", {
      tenantId,
      userId: user_id,
      error: err.message,
      event: "NOTIFY_SUBSCRIBE_ERROR",
      time: new Date().toISOString()
    });
    res.status(500).json({ error: err.message });
  }
}

```sql

### **3. Rotta**

`src/routes/notifications.ts`

```sql
import { Router } from "express";
import { subscribeNotification } from "../controllers/notificationsController";
import { validateBody } from "../middleware/validate";
import { subscribeSchema } from "../validators/notificationValidator";

const router = Router();

router.post("/subscribe", validateBody(subscribeSchema), subscribeNotification);

export default router;

```sql

Aggiungi in `app.ts`:

```sql
import notificationsRoutes from "./routes/notifications";
app.use("/api/notifications", notificationsRoutes);
```sql






## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?







