# Epic Taxonomy — Tassonomia Epiche EasyWay

**Versione**: 1.0
**Data**: 2026-02-28
**Owner**: Giuseppe Belviso
**Audience**: agent_discovery, agent_backlog_planner, Product Owner, Scrum Master

---

## Regola Fondamentale — Wiki-First

> **Chi produce il PRD deve SEMPRE partire dalla wiki via RAG prima di scrivere qualsiasi epica.**

Il RAG serve per rispondere a tre domande obbligatorie prima di creare nuovi work item:

1. **Esiste già un'epica attiva** in questo dominio in ADO?
   → Se sì: aggiungere Features/PBI all'epica esistente, non crearne una nuova.
2. **Quale dominio** copre il requisito? (Infra / AMS / Business / Data / Governance)
   → Determina Area Path, Kanban vs Sprint, pattern Feature/PBI.
3. **Che tipo di Feature/PBI** ci si aspetta in questo dominio?
   → Ogni dominio ha un pattern standard — non inventare strutture nuove.

**Fonte RAG obbligatoria**: questa pagina + `ado-operating-model.md` + epiche attive in ADO.

---

## Indice Domini

| Dominio | Area Path ADO | Flusso | Epic owner tipico |
|---------|--------------|--------|-------------------|
| [Infrastructure](#infra) | `EasyWay\Infra` | Kanban | Platform/DevOps team |
| [AMS](#ams) | `EasyWay\AMS` | Kanban | Support team |
| [Business — Frontend](#frontend) | `EasyWay\Business\Frontend` | Sprint | Frontend team |
| [Business — Logic/API](#logic) | `EasyWay\Business\Logic` | Sprint | Backend team |
| [Business — Reporting](#reporting) | `EasyWay\Business\Reporting` | Sprint | Analytics team |
| [Data](#data) | `EasyWay\Business\Logic` o dedicato | Sprint/Kanban | Data team |
| [Governance](#governance) | cross-cutting | Sprint | Platform team |

---

## <a name="infra"></a>1. Epic Infrastructure

**Area Path**: `EasyWay\Infra`
**Flusso**: Kanban (WIP limit, no sprint timeboxing)
**Tag obbligatorio**: `domain:infra`
**Criteri Business Approved**: approvazione Platform Lead + stima effort

### Quando creare un'Epic Infra

- Nuova componente infrastrutturale (server, rete, storage, container)
- Hardening di sicurezza con più componenti impattate
- CI/CD pipeline (nuova o ristrutturazione significativa)
- Disaster Recovery o Backup strategy
- Upgrade di versione con impatti su più servizi

### Pattern Feature → PBI

```
Epic: [INFRA] <Nome componente / obiettivo>
│
├── Feature: Setup & Provisioning
│   ├── PBI: Provisioning infra base (server, rete, storage)
│   ├── PBI: Installazione dipendenze e runtime
│   └── PBI: Configurazione iniziale e test connettività
│
├── Feature: Security & Hardening
│   ├── PBI: RBAC e permessi
│   ├── PBI: Secrets management (env.secrets, vault)
│   └── PBI: Port hardening e firewall rules
│
├── Feature: CI/CD Integration
│   ├── PBI: Pipeline stage definizione
│   ├── PBI: Deploy script e health check
│   └── PBI: Rollback procedure
│
├── Feature: Monitoring & Alerting
│   ├── PBI: Agent diskwatcher / observability setup
│   ├── PBI: Alert thresholds e notifiche
│   └── PBI: Runbook aggiornato
│
└── Feature: Documentation & Runbook
    ├── PBI: Wiki aggiornata (architettura, deployment, access)
    └── PBI: Runbook operativo testato
```

**Nota**: Le Feature "Security" e "Documentation" sono **sempre presenti** in ogni Epic Infra. Non è facoltativo.

---

## <a name="ams"></a>2. Epic AMS (Application Management Services)

**Area Path**: `EasyWay\AMS`
**Flusso**: Kanban (classi servizio: Expedite / Standard / FixedDate)
**Tag obbligatorio**: `domain:ams`
**Criteri Business Approved**: richiesta formalizzata da business owner

### Quando creare un'Epic AMS

- Gestione incidenti ricorrenti con impatto sistemico
- Change request complessi (impatto su più componenti)
- Knowledge transfer a nuovo team
- Operational improvement con più deliverable

### Pattern Feature → PBI

```
Epic: [AMS] <Tipo intervento — Area — Anno/Quarter>
│
├── Feature: Incident Analysis & Root Cause
│   ├── PBI: Log analysis e identificazione causa radice
│   └── PBI: Post-mortem documentato
│
├── Feature: Remediation
│   ├── PBI: Fix primario (stop bleeding)
│   ├── PBI: Fix sistemico (prevenzione recidiva)
│   └── PBI: Test di regressione
│
└── Feature: Knowledge Base Update
    ├── PBI: FAQ / Q&A aggiornata
    └── PBI: Runbook aggiornato con scenario nuovo
```

---

## <a name="frontend"></a>3. Epic Business — Frontend

**Area Path**: `EasyWay\Business\Frontend`
**Flusso**: Sprint (2 settimane)
**Tag obbligatorio**: `domain:frontend`
**Criteri Business Approved**: Product Owner firma DoR + prioritizzazione in sprint planning

### Quando creare un'Epic Frontend

- Nuova sezione/pagina del portale
- Nuovo flusso UX multi-step
- Redesign di componente con impatto visivo significativo
- Integrazione frontend-backend con nuovi contratti API

### Pattern Feature → PBI

```
Epic: [FE] <Nome funzionalità / pagina>
│
├── Feature: UX Design & Mockup
│   ├── PBI: Wireframe / mockup validato con stakeholder
│   └── PBI: Design system compliance check
│
├── Feature: Component Development
│   ├── PBI: Componente UI (lista, form, table, chart…)
│   ├── PBI: Responsive / mobile adaptation
│   └── PBI: Accessibility (WCAG baseline)
│
├── Feature: API Integration
│   ├── PBI: Contratto API definito (request/response)
│   ├── PBI: Chiamate API integrate nel componente
│   └── PBI: Error handling e loading states
│
├── Feature: Testing
│   ├── PBI: Unit test componente
│   ├── PBI: Integration test (mock API)
│   └── PBI: UAT con utente pilota
│
└── Feature: Documentation
    └── PBI: Wiki aggiornata (screen, flusso, permessi)
```

---

## <a name="logic"></a>4. Epic Business — Logic / API

**Area Path**: `EasyWay\Business\Logic`
**Flusso**: Sprint (2 settimane)
**Tag obbligatorio**: `domain:api` o `domain:db`
**Criteri Business Approved**: Product Owner firma DoR + arch review se impatto DB

### Quando creare un'Epic Logic/API

- Nuova API endpoint o servizio backend
- Nuova business rule con impatto su più moduli
- Integrazione con sistema esterno (GEDI, AMS, fonti dati)
- Refactoring con impatto funzionale

### Pattern Feature → PBI

```
Epic: [BE] <Nome servizio / integrazione>
│
├── Feature: Data Model
│   ├── PBI: Schema DB (Flyway migration)
│   ├── PBI: Entità e relazioni
│   └── PBI: Indici e performance baseline
│
├── Feature: Business Logic
│   ├── PBI: Regola / calcolo / validazione principale
│   ├── PBI: Edge case e error handling
│   └── PBI: Audit log integrato
│
├── Feature: API Endpoint
│   ├── PBI: Endpoint REST (GET/POST/PUT/DELETE)
│   ├── PBI: Autenticazione e autorizzazione (RBAC)
│   └── PBI: OpenAPI spec aggiornata
│
├── Feature: Testing
│   ├── PBI: Unit test business logic
│   ├── PBI: Integration test (DB + API)
│   └── PBI: Performance test (baseline SLO)
│
└── Feature: Documentation
    ├── PBI: Wiki API aggiornata
    └── PBI: Runbook operativo (deploy, rollback, monitoring)
```

---

## <a name="reporting"></a>5. Epic Business — Reporting / Analytics

**Area Path**: `EasyWay\Business\Reporting`
**Flusso**: Sprint (2 settimane)
**Tag obbligatorio**: `domain:analytics`
**Criteri Business Approved**: Product Owner + Data Owner firma requisiti di dato

### Quando creare un'Epic Reporting

- Nuova dashboard o report operativo
- Nuovo KPI con fonte dati da definire
- Export di dati in formato nuovo (Excel, CSV, PDF)
- Alert o notifica automatica basata su soglia

### Pattern Feature → PBI

```
Epic: [RPT] <Nome dashboard / report / KPI>
│
├── Feature: Data Source & Query
│   ├── PBI: Identificazione fonte dati e owner
│   ├── PBI: Query / view SQL ottimizzata
│   └── PBI: Data quality check sulla fonte
│
├── Feature: Visualization
│   ├── PBI: Componente chart / table / card
│   ├── PBI: Filtri e drill-down
│   └── PBI: Export (Excel/CSV/PDF se richiesto)
│
├── Feature: Access Control
│   ├── PBI: RBAC — chi vede cosa
│   └── PBI: Row-level security se necessario
│
└── Feature: Documentation & Training
    ├── PBI: Glossario metriche (definizione, formula, owner)
    └── PBI: Wiki con screenshot e guida utente
```

---

## <a name="data"></a>6. Epic Data

**Area Path**: `EasyWay\Business\Logic` (o dedicato se volume alto)
**Flusso**: Sprint o Kanban a seconda dell'urgenza
**Tag obbligatorio**: `domain:datalake` o `domain:db`
**Criteri Business Approved**: Data Owner + Platform Lead

### Quando creare un'Epic Data

- Nuova pipeline di ingestione da fonte esterna
- Trasformazione / normalizzazione di dataset esistente
- Data quality framework su nuova area dati
- Migrazione dati tra sistemi

### Pattern Feature → PBI

```
Epic: [DATA] <Nome pipeline / dataset / fonte>
│
├── Feature: Source Analysis
│   ├── PBI: Analisi sample dati (struttura, volume, qualità)
│   ├── PBI: Mapping campi fonte → target
│   └── PBI: Regole DQ identificate (null, range, dedup)
│
├── Feature: Ingestion
│   ├── PBI: Connettore / script ingestione
│   ├── PBI: Schedulazione (frequenza, trigger)
│   └── PBI: Error handling e dead-letter queue
│
├── Feature: Transformation & Quality
│   ├── PBI: Trasformazione / normalizzazione
│   ├── PBI: DQ check automatico (soglie, alert)
│   └── PBI: Audit trail ingestione
│
├── Feature: Serving Layer
│   ├── PBI: View / API per consumo downstream
│   └── PBI: ACL e permessi sul dato
│
└── Feature: Documentation
    ├── PBI: Data lineage documentata
    └── PBI: Runbook pipeline (retry, reprocess, archivio)
```

---

## <a name="governance"></a>7. Epic Governance / Compliance

**Area Path**: cross-cutting (usare l'area più impattata)
**Flusso**: Sprint
**Tag obbligatorio**: `governance`, `compliance`
**Criteri Business Approved**: Platform Lead + Security Lead

### Quando creare un'Epic Governance

- Implementazione nuova policy di sicurezza (RBAC, audit, encryption)
- Compliance con normativa (GDPR, ISO, NTT Data policy)
- Aggiornamento documentazione obbligatoria (wiki, runbook, DR plan)

### Pattern Feature → PBI

```
Epic: [GOV] <Policy / normativa / area di controllo>
│
├── Feature: Policy Definition
│   ├── PBI: Policy scritta e approvata
│   └── PBI: Mapping con requisiti normativi
│
├── Feature: Technical Implementation
│   ├── PBI: Controllo tecnico implementato (script, config, rule)
│   ├── PBI: Test del controllo (incluso scenario di violation)
│   └── PBI: CI gate integrato (Iron Dome / PR guardian)
│
└── Feature: Audit & Evidence
    ├── PBI: Audit log configurato
    ├── PBI: Report / dashboard compliance
    └── PBI: Wiki evidence aggiornata
```

---

## Regole Trasversali (tutti i domini)

### Feature "Documentation" è sempre presente

Ogni epica di qualsiasi tipo **deve** avere almeno una Feature di documentazione con:
- Wiki aggiornata (architettura, configurazione, accesso)
- Runbook operativo testato

Se manca la documentazione, il PBI non soddisfa il DoD (Definition of Done).

### Regola "Non duplicare le Epiche"

Prima di creare una nuova epica, verificare via ADO e RAG se:
1. Esiste già un'epica **attiva** nello stesso dominio con scope simile
2. Il requisito può essere coperto come nuova **Feature** su un'epica esistente
3. L'epica esistente è in stato "Closed/Done" → si può creare una nuova (con riferimento alla precedente)

### Criteri per una nuova Feature vs nuovo PBI

| Scope | Crea |
|-------|------|
| Deliverable coeso con 3+ PBI | Nuova Feature |
| Singola User Story verificabile | Nuovo PBI su Feature esistente |
| Task tecnico puro (< 1 giorno) | Task sotto PBI esistente |

---

## Esempio pratico: requisito → epica

**Requisito business**: "Vogliamo caricare i saldi da un file Excel di terze parti, validarli e mostrarli sul portale."

**RAG step**:
1. Cerco "saldi" + "ingestione" nella wiki → trovo che esiste già `Epic [DATA] Ingestione Fonti Esterne` in stato Active
2. Il requisito ha componente Data (ingestione Excel) **e** Frontend (visualizzazione portale)
3. Decido: aggiungo Feature a epica Data esistente + nuova Feature in epica Frontend esistente (se c'è) o nuova Epic FE

**Output PRD**:
```
→ Epic [DATA] Ingestione Fonti Esterne  (esistente)
   └── Feature: Ingestione Saldi da Excel Terze Parti  (nuova)
       ├── PBI: Analisi template Excel + mapping campi
       ├── PBI: Parser e validazione (DQ: null, range, dedup)
       ├── PBI: Schedulazione upload e audit trail
       └── PBI: Wiki + runbook ingestione

→ Epic [FE] Portale Gestione Saldi  (nuova se non esiste)
   └── Feature: Visualizzazione Saldi  (nuova)
       ├── PBI: Componente tabella saldi con filtri
       ├── PBI: RBAC — chi vede quali saldi
       └── PBI: Export Excel/CSV
```

---

## Riferimenti

- `Wiki/EasyWayData.wiki/ado-operating-model.md` — modello ibrido Kanban/Sprint, Area Path, DoR/DoD
- `Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md` — flusso PRD → PBI → Branch → PR
- `Wiki/EasyWayData.wiki/docs-tag-taxonomy.md` — tassonomia tag controllata
- `Wiki/EasyWayData.wiki/control-plane/release-use-cases.md` — scenari di rilascio
- `#innovazione_agenti/EASYWAY_AGENTIC_SDLC_MASTER.md` — visione SDLC agentico
