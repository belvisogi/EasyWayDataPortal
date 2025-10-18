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
