---
id: ew-create-json
title: create json
tags: [domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it, configuration]
owner: team-platform
summary: 'Documento su create json.'
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
**1. `easyway-portal-api/package.json`**
----------------------------------------

```sql
{
  "name": "easyway-portal-api",
  "version": "0.1.0",
  "description": "API Backend per EasyWay Data Portal — Node.js, TypeScript, multi-tenant, parametrica, enterprise-ready",
  "main": "dist/server.js",
  "scripts": {
    "start": "node dist/server.js",
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc",
    "lint": "eslint . --ext .ts",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.19.2",
    "dotenv": "^16.4.5",
    "yaml": "^2.3.4",
    "mssql": "^10.0.1",
    "@azure/storage-blob": "^12.15.0",
    "winston": "^3.10.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "ts-node": "^10.9.2",
    "ts-node-dev": "^2.0.0",
    "eslint": "^8.57.0",
    "@types/node": "^20.11.30",
    "@types/express": "^4.17.21",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.12"
  }
}

```sql

**Dove va:**  
`easyway-portal-api/package.json`  
**A cosa serve:**  
Gestisce dipendenze, comandi, build e run del backend.

* * *

**2. `easyway-portal-api/tsconfig.json`**
-----------------------------------------

json

CopyEdit

```sql
{
  "compilerOptions": {
    "target": "es2022",
    "module": "commonjs",
    "rootDir": "src",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "exclude": [
    "node_modules",
    "dist"
  ]
}
```sql

**Dove va:**  
`easyway-portal-api/tsconfig.json`  
**A cosa serve:**  
Configura TypeScript per compilare tutto da `/src` a `/dist`.

* * *

**3. `easyway-portal-api/README.md`**
-------------------------------------

```sql
# EasyWay Data Portal API — Starter Kit

Node.js + TypeScript + Express, configurazione YAML su Datalake e tabella CONFIGURATION su SQL Server.

## Comandi principali

- `npm install` — installa tutte le dipendenze
- `npm run dev` — avvia il backend in modalità sviluppo (hot reload)
- `npm run build` — compila TypeScript in `/dist`
- `npm start` — avvia il backend dalla build

## Struttura file configurazione

- `/datalake-sample/branding.tenant01.yaml` — esempio YAML branding
- Tabella `PORTAL.CONFIGURATION` (solo DB) — per parametri runtime (script SQL in chat DB)
```sql

**Dove va:**  
`easyway-portal-api/README.md`  
**A cosa serve:**  
Guida rapida per sviluppatori (setup, build, configurazioni).

* * *

**4. `easyway-portal-api/datalake-sample/branding.tenant01.yaml`**
------------------------------------------------------------------

```sql
branding:
  primary_color: "#009FE3"
  secondary_color: "#FFD900"
  background_image: "/portal-assets/img/tenant01_bg.jpg"
  logo: "/portal-assets/img/logo_tenant01.svg"
  font: "Inter, Arial, sans-serif"

labels:
  portal_title: "EasyWay Data Portal"
  login_button: "Accedi"
  welcome_message: "Benvenuto su EasyWay!"

paths:
  official_data: "/official/tenant01/"
  staging_data: "/staging/tenant01/"
  portal_assets: "/portal-assets/"

```sql

**Dove va:**  
`easyway-portal-api/datalake-sample/branding.tenant01.yaml`  
**A cosa serve:**  
Esempio/template file di branding e config UI per ogni tenant.  
**In produzione:** verrà copiato/gestito in Datalake, path es: `/portal-assets/config/branding.tenant01.yaml`

* * *

**5. Database (schema tabella di configurazione)**
--------------------------------------------------

**Non incluso qui!**  
Script SQL **solo nella chat DB**:

> **EasyWay DataPortal - DB (modello dati, schema, convenzioni)**

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

