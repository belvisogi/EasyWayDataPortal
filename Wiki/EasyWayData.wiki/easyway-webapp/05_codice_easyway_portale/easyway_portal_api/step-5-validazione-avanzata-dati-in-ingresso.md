---
id: ew-step-5-validazione-avanzata-dati-in-ingresso
title: step 5 validazione avanzata dati in ingresso
tags: [domain/frontend, layer/howto, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: Validazione input con Zod: schema, middleware e best practice per API robuste.
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
[Home](../.././start-here.md) > [[domains/frontend|frontend]] > [[Layer - Howto|Howto]]

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



## Vedi anche

- [create json](./step-1-setup-ambiente/create-json.md)
- [checklist di test api](../../02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md)
- [STEP 2 - Struttura src e primi file](./STEP-2-—-Struttura-src-e-primi-file.md)
- [step 4 query dinamiche locale datalake](./step-4-query-dinamiche-locale-datalake.md)
- [validazione avanzata](./step-5-validazione-avanzata-dati-in-ingresso/validazione-avanzata.md)



