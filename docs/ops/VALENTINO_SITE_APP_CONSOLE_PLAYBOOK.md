# Valentino Site + App Console Playbook

## 1) Scopo
Definire una strategia chiara e sostenibile per avere:
- `sito` orientato a utenti/business
- `app-console` orientata a operazioni agenti (Ops-first)

Obiettivo: essere pronti all'era agentica senza aumentare debito tecnico evitabile.

## 2) Decisione Architetturale (Hybrid by Design)
- `apps/portal-frontend` (Vite/TypeScript): frontend principale prodotto.
- `apps/agent-console` (Valentino vanilla/static-first): console di monitoring e controllo agenti.

Principio guida: non scegliere un solo stack per tutto, ma scegliere il miglior stack per ciascun perimetro.

## 3) Perche Valentino resta giusto per la Console
- Zero (o quasi) dipendenze esterne: operativita robusta e prevedibile.
- Deploy semplice (asset statici): meno failure point CI/CD.
- Replica rapida tra ambienti/clienti: costo operativo basso.
- Iterazione veloce su UX interna e flussi ops.

## 4) Rischi da gestire (e contromisure)
### Rischio A: SPA home-grown fragile con crescita viste
Contromisure:
- introdurre mini-router hash dichiarativo (`#/overview`, `#/agents/:id`, `#/logs`)
- separare moduli `api`, `state`, `views`, `events`

### Rischio B: metriche hardcoded nel markup
Contromisure:
- spostare dati in endpoint (`/api/console/*`) o `config/agents.json`
- vietare valori operativi hardcoded nel template HTML

### Rischio C: overlap funzionale tra `portal-frontend` e `agent-console`
Contromisure:
- confine esplicito e documentato dei due domini
- review periodica anti-duplicazione feature

## 5) Confine dei Ruoli (non negoziabile)
- `sito`:
  - journey utente
  - contenuti/prodotto/conversione
  - interazioni business-facing
- `app-console`:
  - salute agenti
  - queue/runs
  - retry/pause/resume
  - log/errori e diagnostica

Regola: niente funzionalita duplicate tra i due layer.

## 6) Standard Dati Unico Agenti
Schema minimo condiviso:
- `schemaVersion`
- `id`
- `name`
- `status` (`healthy|degraded|offline`)
- `lastHeartbeat`
- `tasksRunning`
- `errorRate`
- `version`
- `correlationId` (per task/log)

Best practice:
- versionare lo schema
- backward compatibility per almeno 1 versione
- validazione lato backend prima di esporre alla console

## 7) Best Practice App-Console (Valentino 2.0)
- Static-first: `index.html` + `assets/*.js` + `assets/*.css`.
- Runtime config esterna (`config.json`) per endpoint/tenant/branding.
- Stato centralizzato leggero (store in-memory + event bus).
- Realtime pragmatico: polling affidabile; SSE/WebSocket dove serve.
- Health banner globale API (`ok|degraded|down`).
- Log strutturati con `correlationId` e filtri rapidi.
- UX operativa minimale: 4 viste base (`Overview`, `Agents`, `Runs`, `Logs`).

## 8) Best Practice Sito Prodotto
- Tenere stack framework (`Vite/TS`) per scalabilita funzionale.
- Separare chiaramente UI prodotto da UI operativa.
- Integrare capability agentiche tramite API/contratti dati, non tramite copia di logica console.
- Misurare conversione/SEO/performance senza introdurre dipendenze non necessarie.

## 9) Clone-Ready in pochi click
Checklist minima:
1. Template deploy statico pronto (`Dockerfile` semplice o static hosting).
2. `config.json` per ambiente (`DEV`, `STAGE`, `PROD`) senza rebuild.
3. Script bootstrap ambiente (variabili, endpoint, health check).
4. Smoke test da 2 minuti post-deploy:
   - pagina raggiungibile
   - API health raggiungibile
   - vista agenti caricata
   - log consultabili

KPI operativo consigliato: tempo replica nuovo ambiente <= 15 minuti.

## 10) Roadmap 30 giorni
1. Settimana 1:
   - rimuovere hardcoded metrics
   - introdurre config runtime
2. Settimana 2:
   - mini-router + modularizzazione JS
   - schema agenti versionato
3. Settimana 3:
   - health banner + correlation id end-to-end
   - azioni ops (retry/pause/resume) con conferma
4. Settimana 4:
   - smoke test automatici + runbook replica
   - review overlap con `portal-frontend`

## 11) Non-Goals
- Non migrare `agent-console` a framework solo per uniformita estetica.
- Non duplicare feature prodotto nel layer ops.
- Non introdurre dipendenze pesanti senza ROI tecnico misurabile.

## 12) Decisione Finale
Strategia confermata: modello ibrido.
- Valentino per `app-console` (Ops-first, leggero, replicabile).
- Framework moderno per `sito`/`portal-frontend` (crescita prodotto sostenibile).

Questo modello massimizza velocita, controllo operativo e sostenibilita nel medio-lungo periodo.

## 13) Guardrails Operativi
Per evitare deriva architetturale e mantenere antifragilita, applicare:
- `docs/ops/VALENTINO_ANTIFRAGILE_GUARDRAILS.md`

## 14) Profilo Agente L3
Profilo operativo consigliato:
- `docs/ops/VALENTINO_L3_AGENT_PROFILE.md`
