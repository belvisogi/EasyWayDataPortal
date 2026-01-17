---
id: ew-api-overview
title: EasyWay Portal API – Overview
summary: Visione e scelte architetturali del backend API (TS, multi-tenant, config YAML/DB, DevOps).
status: active
owner: team-api
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/frontend, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[domains/frontend|frontend]] > [[Layer - Reference|Reference]]

# EasyWay Data Portal — Manifesto Tecnologico & Analitico

## Codice

Questa sezione raccoglie **tutta la documentazione tecnica, di sviluppo e le best practice**  
che guidano la realizzazione, la manutenzione e l’evoluzione del backend EasyWay Data Portal.

Tutti gli step sono allineati al [Manifesto Tecnologico & Analitico] e alle policy di logging, sicurezza, compliance e conversational readiness.

Consulta questa sezione ogni volta che sviluppi, aggiorni o testi nuovi servizi, endpoint o logiche del portale.


## Premessa e Visione

EasyWay Data Portal **non nasce come semplice demo** o prototipo,  
ma come piattaforma **enterprise-ready**: **scalabile**, **multi-tenant**, configurabile in modo atomico, pensata per sostenere logiche di branding, sicurezza, compliance, automazione DevOps e conversational intelligence fin dal primo commit.

> **Non costruiamo Hello World. Costruiamo un’infrastruttura pronta a crescere, evolvere, parlare.**

## Scelte Architetturali e Motivazioni

- **Node.js + TypeScript**
    - Scegliamo TypeScript per controllo, sicurezza, qualità e manutenzione superiore rispetto a JavaScript puro.
    - **Perché TypeScript?**
        - Tipizzazione forte e controlli statici: meno bug, meno sorprese.
        - Refactor sicuri, onboarding più rapido di nuovi sviluppatori.
        - Standard cloud moderno, compatibile con qualsiasi team enterprise.
    - **Node.js**: de facto standard per API moderne, ecosistema vastissimo, perfetta integrazione con servizi cloud (Azure in primis).

- **Struttura multi-tenant**
    - Tutto nasce per essere parametrico: ogni tenant (cliente) ha la sua configurazione di branding, etichette, regole di business, senza cambiare codice.
    - **Multi-tenant enforced by design**: ogni richiesta API passa sempre dal middleware che garantisce isolamento dati e comportamenti.

- **Configurazione atomica (YAML su Datalake + DB)**
    - Branding e parametri statici in YAML su Datalake: versionabili, modificabili senza deploy, override per tenant immediato.
    - Parametri dinamici (feature toggle, limiti, preferenze, ACL, conversational settings) su DB: aggiornabili real-time, auditabili, gestibili via portale admin.

- **DevOps, Automazione, e Conversational-Ready**
    - Ogni step è pensato per essere deployabile tramite pipeline Azure DevOps: **niente operazioni manuali, tutto versionato, tracciabile, rollbackabile**.
    - Script di setup, pipeline, README, best practice **e convenzioni conversational** forniti da subito.

---

## Metodo di Lavoro

- **Ogni step viene validato, documentato e spiegato**
    - Ogni scelta tecnologica e strutturale è motivata, mai casuale.
    - Quando serve, ci fermiamo e ragioniamo sulle alternative.
    - Ogni file, cartella, API ha uno scopo chiaro e una spiegazione “perché/come”.
    - **Tutto è progettato per essere auditabile, “spiegabile” a persone, AI, AMS e chatbot.**

---

## Punti chiave delle scelte tecniche

- **TypeScript**
    - Più controllo = meno bug
    - Tipi chiari = team più produttivo
    - Progetti più grandi = meno fatica nel tempo

- **Multi-tenant**
    - Dati e comportamenti sempre separati per tenant, nessuna contaminazione.
    - Ogni tenant è “unico” senza duplicare codice.

- **Config fuori dal codice**
    - Branding, etichette, path, limiti, conversational settings: tutti parametrici.
    - Modifica config = niente deploy, niente downtime.

- **DevOps & Conversational Ready**
    - Tutto automatizzato: build, test, deploy, backup, logging, monitoring, e interfaccia agent-aware.

---

## Struttura progetto (STEP 1.1)
*(vedi albero cartelle dettagliato qui sotto, già validato e documentato nel README)*

**STEP 1.1 — Struttura cartelle & file principale**
---------------------------------------------------




**STEP 1.1 — Struttura cartelle & file principale**
---------------------------------------------------

```sql
easyway-portal-api/  
│  
├─ .env.example # Config base (esempio, non versionato)  
├─ package.json # Dipendenze, script NPM  
├─ tsconfig.json # Config TypeScript  
├─ README.md # Istruzioni tecniche e uso  
│  
├─ /src  
│ ├─ app.ts # Entrypoint Express  
│ ├─ server.ts # Avvio server standalone  
│ ├─ /config  
│ │ ├─ index.ts # Loader configurazioni (YAML + DB)  
│ │ ├─ brandingLoader.ts # Funzione lettura YAML dal Datalake  
│ │ └─ dbConfigLoader.ts # Funzione lettura config da DB  
│ ├─ /routes  
│ │ └─ health.ts # Rotta di healthcheck base  
│ ├─ /middleware  
│ │ └─ tenant.ts # Middleware estrazione tenant  
│ ├─ /controllers  
│ │ └─ healthController.ts  
│ ├─ /models  
│ │ └─ configuration.ts # Model config DB  
│ ├─ /utils  
│ │ └─ logger.ts # Utility logging  
│ └─ /types  
│ └─ config.d.ts # Tipizzazione configurazioni  
│  
├─ /datalake-sample  
│ └─ branding.tenant01.yaml # Esempio YAML branding/config per tenant  
│  
└─ /deploy  
└─ azure-pipeline.yml # Pipeline base per build/test/deploy

```sql

* * *


---

**Questo è il vero punto zero “Codex style”**:  
ogni pezzo pronto all’uso, **parametrico, multi-tenant, DevOps e conversational-friendly**.

---

**Architettura di una WebApp/Backend moderna (Express/Node.js/TS)**
-------------------------------------------------------------------

### **Macro-componenti principali:**

- **models/**  
    Definiscono la **struttura dei dati** (User, Profile, Notification, ecc.).  
    Cambiano solo se cambia il DB o aggiungi campi.

- **routes/**  
    Definiscono **gli endpoint esposti** (es: `/api/users`, `/api/branding`, ecc.).  
    Mappano l’endpoint HTTP (GET/POST/PUT/DELETE) al relativo controller.

- **controllers/**  
    Dove risiede la **logica vera** di ogni endpoint:  
    _“Quando arriva una GET su `/api/users`, cosa succede?”_

- **config/**  
    Gestione centralizzata delle **configurazioni** (branding, parametri DB, ecc.).  
    Si aggiorna se cambi modello/config, YAML/DB, override.

- **middleware/**  
    Blocchi riusabili prima dei controller  
    (validazione token, estrazione tenant, logging richieste, agent-aware...).

- **utils/**  
    Funzioni generiche (logging, date, parsing).

- **queries/**  
    SQL versionato, per mantenere la logica dati fuori dal codice.

---

**Controller, routes e config si evolvono più di tutto il resto**  
perché qui aggiungi/migliori endpoint, logica e parametrizzazione.

---

**Tabella di sintesi:**

| Cartella     | Cambia spesso? | Perché cambia                         |
| ------------ | -------------- | ------------------------------------- |
| controllers  | ✅ spesso      | Cambi logica endpoint                 |
| routes       | ✅ spesso      | Aggiungi/rimuovi endpoint API         |
| config       | ✅ spesso      | Nuovi parametri, gestione config      |
| models       | ❌ poco        | Solo se cambia struttura dati         |
| middleware   | ❌ poco        | Solo per security/validazione/agent   |
| utils        | ❌ poco        | Solo nuove utility                    |
| queries      | ❌ poco        | Solo nuova query/ottimizzazione       |

---

## Best Practice Logging — Dati Sensibili (EasyWay)

- **Logga solo ciò che serve, maschera tutto il resto.**
- **Mai dati sensibili in chiaro** su file, Datalake, export, workspace.
- **Documenta la policy** e attieniti sempre (es. funzione `maskEmail` in `/utils/logUtils.ts`).
- **Ogni log conversational o di sistema** rispetta questi principi.

---

## Validazione dati in ingresso — Pattern EasyWay

- Ogni endpoint che scrive su DB (POST/PUT) valida i dati con schema TypeScript/Zod.
- Input errato = risposta 400 dettagliata.
- Schemi in `/validators`, middleware in `/middleware/validate.ts`.
- Ogni CRUD ha schema di validazione.

**Esempio errore:**
```json
{
  "error": "Validation failed",
  "details": [
    { "path": ["email"], "message": "Invalid email" }
  ]
}
```sql

8. Roadmap evolutiva

| Fase | Azione |
| --- | --- |
| 1 | Refactor endpoint `/upload` in `/api/agent/upload/initiate` |
| 2 | Aggiunta validazione ACL per tutti gli endpoint agent-aware |
| 3 | Standardizzazione risposte JSON |
| 4 | Logging automatico in `portal-audit/` |
| 5 | SDK interno `AgentOrchestrator` per semplificare chiamate |
| 6 | Esporre metadati disponibili per ogni agent |
| 7 | Estensione agenti futuri: DQ, ACL, Audit, Billing |

---



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?









