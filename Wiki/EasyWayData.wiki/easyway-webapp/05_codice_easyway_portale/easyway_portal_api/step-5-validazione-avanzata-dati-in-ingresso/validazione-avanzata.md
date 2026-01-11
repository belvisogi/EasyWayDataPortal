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

## Checklist per considerare lo step COMPLETO

> Questa sezione serve agli agenti (umani o LLM) per verificare se lo step è davvero completato.
> Tutte le checkbox devono risultare vere al termine dell’esecuzione.

### Template (best practice)

### A. Struttura del documento

- [ ] Il documento ha:
  - [ ] frontmatter completo (id, title, tags, owner, summary, status, updated, next).
  - [ ] sezione **"Perché serve"** o equivalente che spiega lo scopo dello step.
  - [ ] sezione **"Prerequisiti"** con:
    - [ ] repo/branch o contesto tecnico.
    - [ ] tool richiesti (es. Node, pnpm, pwsh, az, sqlcmd…).
    - [ ] permessi minimi (read/write) e scope (tenant/subscription).
  - [ ] sezione **"Passi"** con indicazioni passo-passo o macro-step numerati.
  - [ ] sezione **"Verify"** che spiega come controllare che lo step sia andato a buon fine.
  - [ ] sezione **"Vedi anche"** con i link principali agli step/pagine correlate.

### B. Output tecnici attesi

- [ ] Sono stati creati/aggiornati tutti i file/cartelle previsti da questo step.
- [ ] Gli script o comandi indicati (se presenti) sono stati eseguiti:
  - [ ] prima in modalità **whatIf / dry-run** quando disponibile.
  - [ ] poi in modalità applicativa, solo dopo approvazione (se richiesto).
- [ ] Gli artifact generati (file, tabelle, risorse cloud, log) sono:
  - [ ] presenti.
  - [ ] coerenti con gli esempi/descrizioni della pagina.

### C. Navigazione e collegamenti

- [ ] La sezione **"Vedi anche"** contiene almeno:
  - [ ] link allo **step precedente** (quando esiste).
  - [ ] link allo **step successivo** (se già definito).
  - [ ] link ad eventuali **documenti di dettaglio** (es. validazione avanzata, checklist di test).
- [ ] Tutti i link in **"Vedi anche"**:
  - [ ] usano percorsi relativi corretti.
  - [ ] puntano a pagine esistenti nel Wiki.

### D. Gate di qualità

- [ ] Se sono previsti gate (Checklist/Drift/KB):
  - [ ] la pagina specifica chiaramente quali sono.
  - [ ] è indicato dove vedere lo stato dei gate (es. pagina wiki, dashboard, output script).
- [ ] In caso di errori:
  - [ ] la pagina spiega quali **informazioni minime** raccogliere (command line, parametri, correlationId, log principali).

### Specifica (validazione avanzata)

> Checklist operativa per questo step: validazione di querystring, parametri di route e header `X-Tenant-Id`.

#### 1) Output tecnici attesi

- [ ] Nel progetto API esiste il file `src/middleware/validate.ts` con:
  - [ ] funzione `validateBody` che valida il body della richiesta.
  - [ ] funzione `validateQuery` che valida `req.query`.
  - [ ] funzione `validateParams` che valida `req.params`.
- [ ] Nel progetto API esiste il file `src/validators/userValidator.ts` con:
  - [ ] lo schema `userIdParamSchema` (o schema equivalente) per validare `user_id` nei parametri di route.
- [ ] Nel file `src/routes/users.ts` (o equivalente):
  - [ ] la rotta `PUT /:user_id` usa `validateParams(userIdParamSchema)` prima del controller `updateUser`.
  - [ ] la rotta `DELETE /:user_id` usa `validateParams(userIdParamSchema)` prima del controller `deleteUser`.
  - [ ] le rotte che usano il body (es. `POST /`) usano `validateBody` con lo schema zod corretto.
- [ ] Nel progetto API esiste il file `src/middleware/tenant.ts` con:
  - [ ] middleware `extractTenantId` che:
    - [ ] legge l’header `X-Tenant-Id`.
    - [ ] verifica che sia presente.
    - [ ] verifica che la lunghezza sia nel range atteso (es. 3–32 caratteri).
    - [ ] in caso di errore restituisce `400` con un messaggio chiaro.

#### 2) Verify (test minimi)

- [ ] **Parametri di route (`user_id`):**
  - [ ] richiesta `PUT /users/:user_id` con `user_id` valido → risposta OK (2xx).
  - [ ] richiesta `PUT /users/:user_id` con `user_id` troppo corto o troppo lungo → risposta `400` con dettagli di validazione.
  - [ ] richiesta `DELETE /users/:user_id` con `user_id` non valido → risposta `400` con dettagli di validazione.
- [ ] **Header `X-Tenant-Id`:**
  - [ ] richiesta senza header `X-Tenant-Id` → risposta `400` con messaggio tipo `"Invalid or missing X-Tenant-Id header"`.
  - [ ] richiesta con `X-Tenant-Id` troppo corto o troppo lungo → risposta `400`.
  - [ ] richiesta con `X-Tenant-Id` valido → la richiesta prosegue fino al controller.
- [ ] **Querystring (se prevista):**
  - [ ] richiesta con query valida (es. filtri/paginazione corretti) → risposta OK.
  - [ ] richiesta con query non valida (tipo errato, range errato, valori fuori lista) → risposta `400` con dettagli di validazione.
- [ ] I log applicativi mostrano:
  - [ ] errori di validazione chiari (messaggi leggibili, niente stack trace inutili).
  - [ ] nessuna eccezione non gestita dovuta a input non validi.

#### 3) Vedi anche (link minimi)

- [ ] Link allo **step 5 – validazione avanzata dati in ingresso**:
  - [ ] `../step-5-validazione-avanzata-dati-in-ingresso.md`
- [ ] Link agli step preparatori:
  - [ ] `../step-1-setup-ambiente/create-json.md`
  - [ ] `../STEP-2-—-Struttura-src-e-primi-file.md`
  - [ ] `../step-4-query-dinamiche-locale-datalake.md`
- [ ] Link alla checklist di test API:
  - [ ] `../../02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md`








