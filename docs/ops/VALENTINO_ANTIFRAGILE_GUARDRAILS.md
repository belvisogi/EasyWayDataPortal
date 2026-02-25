# Valentino Antifragile Guardrails

Versione: 1.0 (2026-02-24)
Scope: `apps/agent-console` + integrazione con `apps/portal-frontend`

## Obiettivo
Evitare errori strutturali nel modello ibrido (`sito` + `app-console`) e garantire evoluzione stabile, veloce e replicabile.

## 1) Guardrail Non Negoziabili

### A. Boundary Guardrail (Product vs Ops)
- [ ] `portal-frontend` gestisce UX business e journey utente.
- [ ] `agent-console` gestisce solo operazioni agenti (health, runs, logs, retry/pause/resume).
- [ ] Ogni nuova feature e classificata prima come `PRODUCT` o `OPS`.
- [ ] Feature duplicate tra i due layer sono bloccate in review.

### B. Data Guardrail (No Hardcoded Runtime)
- [ ] Nessun dato operativo hardcoded in HTML (`stat-value`, contatori, percentuali).
- [ ] Tutte le metriche arrivano da API o `config.json` runtime.
- [ ] Schema agenti versionato con `schemaVersion`.
- [ ] Compatibilita backward mantenuta per almeno 1 versione.

### C. Architecture Guardrail (Valentino 2.0)
- [ ] Routing hash dichiarativo (`#/overview`, `#/agents/:id`, `#/runs`, `#/logs`).
- [ ] Moduli separati `api`, `state`, `views`, `events`.
- [ ] Stato centralizzato leggero; niente logica sparsa nel DOM.
- [ ] Dipendenze esterne nuove consentite solo con ADR + ROI tecnico esplicito.

### D. Reliability Guardrail
- [ ] Health banner globale API (`ok|degraded|down`) visibile.
- [ ] `correlationId` presente end-to-end (task, log, errori).
- [ ] Timeout/retry policy definita lato API client.
- [ ] Degradazione controllata: UI continua a funzionare anche con endpoint parzialmente down.

### E. Deploy Guardrail (Clone-Ready)
- [ ] Deploy statico senza step build obbligatori lato runtime.
- [ ] Config ambiente esterna (`DEV`, `STAGE`, `PROD`) senza rebuild.
- [ ] Smoke test post-deploy <= 2 minuti.
- [ ] Tempo replica nuovo ambiente <= 15 minuti (KPI target).

## 2) Cose da NON Fare (Anti-Pattern)
- [ ] Trasformare `agent-console` in un secondo portale prodotto.
- [ ] Introdurre framework pesanti in console per sola uniformita.
- [ ] Mischiare logica business utente dentro viste ops.
- [ ] Aggiungere nuove viste senza aggiornare router/state contract.
- [ ] Accettare merge con metriche hardcoded o dati mock non marcati.

## 3) Release Gates Obbligatori (prima del merge)
- [ ] Gate 1: feature classificata `PRODUCT` o `OPS` e ownership chiara.
- [ ] Gate 2: nessuna duplicazione funzionale aperta.
- [ ] Gate 3: contratto dati valido (schema + backward compatibility).
- [ ] Gate 4: smoke test console passati (overview/agents/runs/logs).
- [ ] Gate 5: health + correlationId verificati in ambiente target.

## 4) Red Flags Settimanali (Early Warning)
Se >= 2 red flags nello stesso sprint, avviare hardening immediato.

- [ ] Nuove metriche inserite manualmente in HTML/JS.
- [ ] Stessa capability presente sia in `portal-frontend` che in `agent-console`.
- [ ] Tempo di replica ambiente > 15 minuti.
- [ ] Incidenti ricorrenti senza `correlationId`.
- [ ] Aumento rapido di codice non modulare in `index.html` o script globali.

## 5) Protocollo Correttivo (24-48h)
1. Freeze su nuove feature non critiche.
2. Root-cause su red flag con owner e scadenza.
3. Patch minima su hardcoded/overlap/contract drift.
4. Riapertura feature solo dopo passaggio release gates.

## 6) Rituale Operativo Consigliato
- Weekly 30 min:
  - review red flags
  - review duplicazioni `PRODUCT/OPS`
  - review KPI replica e affidabilita
- Monthly 60 min:
  - audit dipendenze
  - audit confini architetturali
  - aggiornamento playbook + guardrails

## 7) Decision Rule per Futuri Cambi Stack
Valutare migrazione console a framework solo se, per 2 trimestri consecutivi:
- complessita routing/state supera capacita manutentiva del team
- incidenti di regressione UI aumentano nonostante i guardrail
- costo totale di hardening > costo stimato migrazione

In assenza di queste condizioni: mantenere Valentino per la console.
