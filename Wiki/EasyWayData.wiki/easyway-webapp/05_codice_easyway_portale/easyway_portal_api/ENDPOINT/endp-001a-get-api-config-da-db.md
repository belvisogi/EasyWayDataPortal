---
id: ew-endp-001a
title: GET /api/config (da DB)
summary: Restituisce la configurazione dinamica dal DB per il tenant corrente (tabella PORTAL.CONFIGURATION).
status: active
owner: team-api
created: '2025-01-01'
updated: '2025-01-01'
tags: [artifact-endpoint, domain/frontend, layer/reference, audience/dev, privacy/internal, language/it]
title: endp 001a get api config da db
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/frontend|frontend]] > [[Layer - Reference|Reference]]

**Obiettivo:**  
Fornire un endpoint che restituisce la configurazione dinamica (parametri da DB) per il tenant corrente, esattamente come per il branding,  
ma stavolta leggendo dalla tabella `PORTAL.CONFIGURATION` (già pronta lato DB).

## A. Codice - File da creare/aggiornare

1. `src/routes/config.ts`

```sql
// easyway-portal-api/src/routes/config.ts
import { Router } from "express";
import { getDbConfig } from "../controllers/configController";

const router = Router();

// Endpoint GET /api/config
router.get("/", getDbConfig);

export default router;
```sql

2. `src/controllers/configController.ts`

```sql
// easyway-portal-api/src/controllers/configController.ts
import { Request, Response } from "express";
import { loadDbConfig } from "../config/dbConfigLoader";

export async function getDbConfig(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const section = req.query.section as string | undefined;

    const config = await loadDbConfig(tenantId, section);

    if (Object.keys(config).length === 0) {
      return res.status(404).json({ error: "No configuration found for this tenant/section" });
    }

    res.json(config);
  } catch (err: any) {
    res.status(500).json({ error: err.message || "Internal server error" });
  }
}
```sql

3. Aggiorna `src/app.ts` per includere la nuova rotta
   - Aggiungi dopo gli altri import:
```sql
import configRoutes from "./routes/config";
```sql
   - Aggiungi questa riga sotto le altre rotte:
```sql
app.use("/api/config", configRoutes);
```sql



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?










