---
id: ew-endp-002
title: GET /api/branding
summary: Restituisce il branding (logo, colori, testi) per il tenant corrente.
status: active
owner: team-api
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-endpoint, domain/frontend, layer/reference, audience/dev, privacy/internal, language/it]
title: endp 002 get api branding
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
type: guide
---
[Home](../../.././start-here.md) > [[domains/frontend|frontend]] > 

### **1. `src/routes/branding.ts`**

```sql
// easyway-portal-api/src/routes/branding.ts
import { Router } from "express";
import { getBrandingConfig } from "../controllers/brandingController";

const router = Router();

// Endpoint GET /api/branding
router.get("/", getBrandingConfig);

export default router;

```sql

**Dove va:**  
`easyway-portal-api/src/routes/branding.ts`

### **2. `src/controllers/brandingController.ts`**


```sql
// easyway-portal-api/src/controllers/brandingController.ts
import { Request, Response } from "express";
import { loadBrandingConfig } from "../config/brandingLoader";

export async function getBrandingConfig(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const config = await loadBrandingConfig(tenantId);
    res.json(config);
  } catch (err: any) {
    res.status(404).json({ error: err.message || "Branding config not found" });
  }
}
```sql

**Dove va:**  
`easyway-portal-api/src/controllers/brandingController.ts`

**3. Aggiungi la rotta in `src/app.ts`**

Aggiungi questa riga **sotto** la riga in cui importi le rotte health:

```sql
import brandingRoutes from "./routes/branding";
```sql
E subito **dopo** la riga  
```sql
app.use("/api/health", healthRoutes);`
```sql
aggiungi:
```sql
app.use("/api/branding", brandingRoutes);
```sql

`src/app.ts` (snippet aggiornato):

```sql
// easyway-portal-api/src/app.ts
import express from "express";
import dotenv from "dotenv";
import { logger } from "./utils/logger";
import { extractTenantId } from "./middleware/tenant";
import healthRoutes from "./routes/health";
import brandingRoutes from "./routes/branding";

// Carica variabili di ambiente (.env)
dotenv.config();

const app = express();
app.use(express.json());

// Logging di ogni richiesta base
app.use((req, res, next) => {
  logger.info(`[${req.method}] ${req.originalUrl}`);
  next();
});

// Middleware per estrarre tenant_id da header/JWT (customizza a piacere)
app.use(extractTenantId);

// Rotte API
app.use("/api/health", healthRoutes);
app.use("/api/branding", brandingRoutes);

export default app;


```sql







## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?












