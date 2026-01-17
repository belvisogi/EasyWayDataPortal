---
id: step-2-struttura-src-e-primi-file
title: STEP 2 — Struttura src e primi file
tags: [domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it, api, structure]
owner: team-platform
summary: 'Definisce la struttura della cartella src per easyway-portal-api e i primi file minimi (app, server, logger, middleware multi-tenant, healthcheck, tipi di configurazione).'
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: ./STEP-3-—-Gestione-configurazioni-(YAML-+-DB).md
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Howto|Howto]]

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

```text
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
```ts
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

```ts
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
```ts
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

```ts
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

```ts
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

```ts
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

```ts
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
- Come deve essere strutturata la cartella `src` dell’`easyway-portal-api`?
- Dove metto app, server, controller, middleware, routes, types e utils?
- Come preparo da subito l’API per multi-tenant (header `X-Tenant-Id`) e healthcheck?
- Qual è il minimo set di file per avere un progetto Express/TypeScript enterprise‑ready?
- Come collego questo step agli step successivi (configurazioni YAML/DB, query, validazione)?

## Prerequisiti
- Repo `easyway-portal-api` clonata in locale.
- Ambiente Node.js installato (versione LTS consigliata) e npm/yarn funzionanti.
- Step 1 completato:
  - file di configurazione base creati (`create-json`),
  - struttura minima del progetto inizializzata.
- Conoscenza base di:
  - Express (routing, middleware),
  - TypeScript (types, interfacce),
  - concetto di multi-tenant (tenant id, separazione per cliente/ambiente).

## Passi
1. **Crea la struttura della cartella `src`**
   - Replica l’albero riportato all’inizio della pagina, con sottocartelle:
     - `/config`, `/routes`, `/controllers`, `/middleware`, `/models`, `/utils`, `/types`.
   - Verifica che i path siano coerenti con gli import usati negli esempi (`./routes/health`, `./utils/logger`, ecc.).

2. **Implementa `app.ts` e `server.ts`**
   - Copia il contenuto proposto per:
     - `src/app.ts` (configurazione Express, middleware, logging, routing),
     - `src/server.ts` (entrypoint che avvia il server).
   - Aggiorna le impostazioni di porta/variabili d’ambiente se necessario.

3. **Aggiungi logger e middleware multi-tenant**
   - Crea `src/utils/logger.ts` con la configurazione base di `winston` mostrata.
   - Crea `src/middleware/tenant.ts` e verifica che:
     - legga l’header `X-Tenant-Id`,
     - imposti `req.tenantId` (o proprietà equivalente) per i controller a valle.

4. **Configura la rotta e il controller di healthcheck**
   - Crea `src/routes/health.ts` e `src/controllers/healthController.ts` come da esempi.
   - Registra in `app.ts` la rotta `/api/health` usando `healthRoutes`.

5. **Definisci i tipi di configurazione**
   - Crea `src/types/config.d.ts` con le interfacce proposte (`BrandingConfig`, `TenantConfig`, ecc.).
   - Allinea i nomi delle proprietà ai file YAML effettivi usati negli step successivi.

6. **Allinea gli script di avvio**
   - Verifica che in `package.json` gli script (`npm start`, `npm run dev`) puntino a `src/server.ts` (tramite ts-node / build JS).
   - Esegui un primo avvio locale per verificare che l’API parta senza errori.

## Verify
- Avvia l’applicazione (es. `npm run dev` o `npm start`) e controlla che:
  - il processo parta senza errori TypeScript/Node,
  - la porta configurata sia in ascolto.

- Chiamando `GET /api/health`:
  - senza header `X-Tenant-Id`:
    - verifica che il comportamento sia quello atteso (errore 400 o tenant `undefined`, in base a come hai implementato il middleware).
  - con header `X-Tenant-Id: demo-tenant`:
    - verifica che la risposta contenga `tenant: "demo-tenant"` e `service: "EasyWay Data Portal API"`.

- Verifica i log:
  - che ogni richiesta venga loggata dal `logger` (metodo, URL),
  - che eventuali errori applichino lo stesso sistema di logging.

- Conferma che tutti gli import funzionino:
  - nessun errore di tipo “Cannot find module …/routes/health”,
  - nessun errore sui tipi definiti in `config.d.ts`.

## Vedi anche

- [create json](./step-1-setup-ambiente/create-json.md)
- [come si testa](./ENDPOINT/Template-ENDPOINT/come-si-testa.md)
- [STEP 3 - Gestione configurazioni (YAML + DB)](./STEP-3-—-Gestione-configurazioni-(YAML-+-DB).md)
- [query in src queries](./step-4-query-dinamiche-locale-datalake/query-in-src-queries.md)
- [checklist di test api](../../02_logiche_easyway/api-esterne-integrazione/checklist-di-test-api.md)

