---
id: ew-validazione-avanzata
title: validazione avanzata
tags: [domain/control-plane, layer/spec, audience/dev, privacy/internal, language/it, validation, security]
owner: team-platform
summary: 'Documento su validazione avanzata.'
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
Dopo aver validato il **body** delle richieste (POST/PUT),  
è **best practice** validare anche:
*   **Querystring** (ad esempio, filtri/paginazione)
    
*   **Parametri di route** (ad esempio, `:user_id`)
    
*   **Header** (ad esempio, `X-Tenant-Id`)

### **A. Middleware di validazione per parametri e querystring**

#### **1. Middleware generico per parametri route e query**

`src/middleware/validate.ts`  
_(aggiungi queste funzioni accanto a `validateBody`)_

```sql
import { ZodSchema } from "zod";
import { Request, Response, NextFunction } from "express";

// Body già visto prima
export function validateBody(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ error: "Validation failed", details: result.error.errors });
    }
    req.body = result.data;
    next();
  };
}

// Querystring
export function validateQuery(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      return res.status(400).json({ error: "Invalid query parameters", details: result.error.errors });
    }
    req.query = result.data;
    next();
  };
}

// Parametri di route (es: /api/users/:user_id)
export function validateParams(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.params);
    if (!result.success) {
      return res.status(400).json({ error: "Invalid route parameters", details: result.error.errors });
    }
    req.params = result.data;
    next();
  };
}

```sql

#### **2. Schema di validazione per parametri**

Esempio per `user_id` (NDG alfanumerico):
`src/validators/userValidator.ts`  
_(aggiungi accanto agli altri schema)_

```sql
export const userIdParamSchema = z.object({
  user_id: z.string().min(6).max(32), // adatta a come hai impostato NDG
});

```sql

#### **3. Schema di validazione per header**

Per `X-Tenant-Id` puoi validare direttamente nel middleware  
(oppure, se vuoi modularizzare, usa zod).

### **B. Esempio di applicazione nelle rotte**

`src/routes/users.ts`

```sql
import { Router } from "express";
import { getUsers, createUser, updateUser, deleteUser } from "../controllers/usersController";
import { validateBody, validateParams } from "../middleware/validate";
import { userCreateSchema, userUpdateSchema, userIdParamSchema } from "../validators/userValidator";

const router = Router();

router.get("/", getUsers);

router.post("/", validateBody(userCreateSchema), createUser);

router.put(
  "/:user_id",
  validateParams(userIdParamSchema),
  validateBody(userUpdateSchema),
  updateUser
);

router.delete(
  "/:user_id",
  validateParams(userIdParamSchema),
  deleteUser
);

export default router;

```sql

### **C. Validazione header (X-Tenant-Id)**

Nel middleware tenant, puoi aggiungere controllo più robusto:
`src/middleware/tenant.ts`

```sql
import { Request, Response, NextFunction } from "express";

export function extractTenantId(req: Request, res: Response, next: NextFunction) {
  const tenantId = req.header("X-Tenant-Id");
  if (!tenantId || tenantId.length < 3 || tenantId.length > 32) {
    return res.status(400).json({ error: "Invalid or missing X-Tenant-Id header" });
  }
  (req as any).tenantId = tenantId;
  next();
}

```sql

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








