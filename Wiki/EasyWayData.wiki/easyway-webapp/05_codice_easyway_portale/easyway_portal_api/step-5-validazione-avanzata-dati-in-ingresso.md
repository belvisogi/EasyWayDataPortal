---
id: ew-step-5-validazione-avanzata-dati-in-ingresso
title: step 5 validazione avanzata dati in ingresso
tags: [domain/frontend, layer/howto, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: TODO - aggiungere un sommario breve.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
### **Perché serve**

*   **Blocca subito i dati errati o “sporchi”** prima che arrivino al database.
    
*   **Evita bug e log inutili** (meno errori sulle API e meno dati da gestire nei log).
    
*   **Obbliga a rispettare le regole di business** su formato, presenza, coerenza dei dati.
    
*   **Aiuta a mantenere i log DB “puliti” e comprensibili**.

validazione completa su:
- Body (POST/PUT)
- Querystring (GET con filtri, paginazione…)
- Parametri route (`:user_id`)
- Header (`X-Tenant-Id`)
    

* * *

### **A. Tecnologia consigliata: Zod (alternativa: Joi)**

*   **Zod** è una libreria TypeScript, perfetta per progetti moderni e typed.
    
*   Definisci “schemi” per ogni entità/endpoint: se i dati non rispettano lo schema, la richiesta viene bloccata (errore 400).
    

* * *

### **B. Esempio di validazione per utenti (create e update)**

#### **1. Installa Zod**
```sql
npm install zod
```sql
#### **2. Crea schema di validazione**

`src/validators/userValidator.ts`

```sql
import { z } from "zod";

export const userCreateSchema = z.object({
  email: z.string().email(),
  display_name: z.string().min(3).max(100),
  profile_id: z.string().min(1),
});

export const userUpdateSchema = z.object({
  email: z.string().email().optional(),
  display_name: z.string().min(3).max(100).optional(),
  profile_id: z.string().min(1).optional(),
  is_active: z.boolean().optional()
});

```sql

#### **3. Middleware generico di validazione**

`src/middleware/validate.ts`

```sql
import { Request, Response, NextFunction } from "express";
import { ZodSchema } from "zod";

export function validateBody(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ error: "Validation failed", details: result.error.errors });
    }
    req.body = result.data; // eventuale sanitizzazione
    next();
  };
}
```sql

#### **4. Usa il middleware nelle route utenti**

`src/routes/users.ts`

```sql
import { Router } from "express";
import { getUsers, createUser, updateUser, deleteUser } from "../controllers/usersController";
import { validateBody } from "../middleware/validate";
import { userCreateSchema, userUpdateSchema } from "../validators/userValidator";

const router = Router();

router.get("/", getUsers);
router.post("/", validateBody(userCreateSchema), createUser);
router.put("/:user_id", validateBody(userUpdateSchema), updateUser);
router.delete("/:user_id", deleteUser);

export default router;

```sql




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








