---
id: ew-step-2-—-struttura-src-e-primi-file
title: STEP 2 — Struttura src e primi file
tags: [domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it, api, structure]
owner: team-platform
summary: 'Documento su STEP 2 — Struttura src e primi file.'
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
**Perché lo facciamo:**
*   Creiamo la struttura reale dove andrà **tutto il codice** dell’applicazione (API, middleware, controller, utilità).
    
*   Applichiamo già i pattern enterprise (separazione tra logica, controller, middleware, ecc.)
    
*   Mettiamo subito un middleware multi-tenant e un endpoint di healthcheck, così ogni API sarà già “tenant-aware” e monitorabile.
    
**A cosa serve:**
*   `/src/app.ts` → punto di ingresso dell’applicazione, dove si configurano middleware, logging e routing
    
*   `/src/server.ts` → avvio del server, separato per chiarezza e testabilità
    
*   `/middleware/tenant.ts` → rende ogni richiesta multi-tenant
    
*   `/routes/health.ts`, `/controllers/healthController.ts` → test rapido dell’API (monitorabile e “tenantizzata”)
    
**Risultato:**  
Hai una struttura **già pronta per team, estensioni e deployment enterprise**, con logging e multi-tenant **dalla prima riga di codice**.

```sql
easyway-portal-api/
└── src/
    ├── app.ts
    ├── server.ts
    ├── /config
    │     ├── index.ts
    │     ├── brandingLoader.ts
    │     └── dbConfigLoader.ts
    ├── /routes
    │     └── health.ts
    ├── /controllers
    │     └── healthController.ts
    ├── /middleware
    │     └── tenant.ts
    ├── /models
    │     └── configuration.ts
    ├── /utils
    │     └── logger.ts
    └── /types
          └── config.d.ts
```sql

2.1 `src/app.ts`
```sql
// easyway-portal-api/src/app.ts
import express from "express";
import dotenv from "dotenv";
import { logger } from "./utils/logger";
import { extractTenantId } from "./middleware/tenant";
import healthRoutes from "./routes/health";

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

export default app;

```sql
**Dove va:**  
`easyway-portal-api/src/app.ts`
**A cosa serve:**  
Bootstrap di Express, setup middleware, logging, parsing JSON, aggancio rotte, estrazione tenant.  
**Qui “attacchi” tutte le rotte e i middleware globali.**

2.2 `src/server.ts`

```sql
// easyway-portal-api/src/server.ts
import app from "./app";

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`EasyWay API running on port ${PORT}`);
});
```sql

**Dove va:**  
`easyway-portal-api/src/server.ts`
**A cosa serve:**  
Avvio reale del server (entrypoint).  
Se fai `npm run dev` o `npm start` parte da qui.


2.3 `src/utils/logger.ts`
```sql
// easyway-portal-api/src/utils/logger.ts
import winston from "winston";

export const logger = winston.createLogger({
  level: "info",
  format: winston.format.simple(),
  transports: [
    new winston.transports.Console(),
  ],
});
```sql

**Dove va:**  
`easyway-portal-api/src/utils/logger.ts`
**A cosa serve:**  
Logger base (usato per log di sistema, debug, audit).  
**Espandibile** (file, cloud, Application Insights…).

2.4 `src/middleware/tenant.ts`

```sql
// easyway-portal-api/src/middleware/tenant.ts
import { Request, Response, NextFunction } from "express";

// Esempio: tenant_id estratto da header X-Tenant-Id
export function extractTenantId(req: Request, res: Response, next: NextFunction) {
  const tenantId = req.header("X-Tenant-Id");
  if (!tenantId) {
    return res.status(400).json({ error: "Missing X-Tenant-Id header" });
  }
  // Attach tenant_id to req for downstream use
  (req as any).tenantId = tenantId;
  next();
}
```sql
**Dove va:**  
`easyway-portal-api/src/middleware/tenant.ts`
**A cosa serve:**  
Middleware che estrae e “attacca” il tenantId ad ogni richiesta (standard multi-tenant).  
**In futuro** puoi cambiarlo per estrazione da JWT/token, se vuoi SSO/OAuth.

2.5 `src/routes/health.ts`

```typescript

// easyway-portal-api/src/routes/health.ts
import { Router } from "express";
import { healthCheck } from "../controllers/healthController";

const router = Router();

// Rotta di healthcheck base
router.get("/", healthCheck);

export default router;
```sql
**Dove va:**  
`easyway-portal-api/src/routes/health.ts`
**A cosa serve:**  
Definisce endpoint GET `/api/health` per testare che l’API sia up & running.

2.6 `src/controllers/healthController.ts`

```sql
// easyway-portal-api/src/controllers/healthController.ts
import { Request, Response } from "express";

export function healthCheck(req: Request, res: Response) {
  res.json({
    status: "ok",
    tenant: (req as any).tenantId || "undefined",
    service: "EasyWay Data Portal API"
  });
}
```sql

**Dove va:**  
`easyway-portal-api/src/controllers/healthController.ts`
**A cosa serve:**  
Handler (controller) per la health, ritorna info su API e tenant corrente.

2.7 (Esempio) `src/types/config.d.ts`

```sql
// easyway-portal-api/src/types/config.d.ts

export interface BrandingConfig {
  primary_color: string;
  secondary_color: string;
  background_image: string;
  logo: string;
  font: string;
}

export interface LabelsConfig {
  portal_title: string;
  login_button: string;
  welcome_message: string;
}

export interface PathsConfig {
  official_data: string;
  staging_data: string;
  portal_assets: string;
}

export interface TenantConfig {
  branding: BrandingConfig;
  labels: LabelsConfig;
  paths: PathsConfig;
}
```sql

**Dove va:**  
`easyway-portal-api/src/types/config.d.ts`
**A cosa serve:**  
Tipizzazione per i parametri di configurazione YAML letti da Datalake.







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

