---
title: Tag Scopes & Retrieval Bundles (Gerarchia)
tags: [domain/docs, layer/reference, audience/dev, audience/architect, privacy/internal, language/it, taxonomy, rag, n8n, agents]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-docs-tag-scopes
chunk_hint: 300-450
entities: []
include: true
summary: Sistema gerarchico di scopes e bundles per retrieval mirato, enforcement CI graduale e context loading ottimizzato per agents/n8n.
llm: 
pii: none
owner: team-platform
---

[[start-here|Home]] > [[domains/docs-governance|Docs]] > [[Layer - Reference|Reference]]

# Tag Scopes & Retrieval Bundles (Gerarchia)

## Contesto

Questa pagina documenta il **sistema gerarchico** di organizzazione della Wiki basato su:
1. **Scopes** - Raggruppamenti logici di pagine
2. **Retrieval Bundles** - Combinazioni di scope per scenari intent-based

**Source of truth** (machine-readable):
- Scopes: `docs/agentic/templates/docs/tag-taxonomy.scopes.json`
- Bundles: `docs/agentic/templates/docs/retrieval-bundles.json`
- Facet base: `docs/agentic/templates/docs/tag-taxonomy.json`

**Documentazione facet**: [Tag Taxonomy (Controllata)](./docs-tag-taxonomy.md)

---

## 🏗️ Architettura a 3 Livelli

```sql
🌐 Wiki (240+ pagine)
│
├─ Level 1: FACET TAGS (Coordinate)
│  └─ domain/, layer/, audience/, privacy/, language/
│
├─ Level 2: SCOPES (Raggruppamenti Logici)
│  ├─ Macro-scopes (*-all): Aggregatori top-level
│  └─ Micro-scopes (*-20): Subset per enforcement graduale
│
└─ Level 3: RETRIEVAL BUNDLES (Intent-Based)
   └─ Combinazioni scope + code_roots per scenari specifici
```sql

---

## 📦 Level 2: Scopes

### Che Cos'è uno Scope?

Uno **scope** è un raggruppamento logico di pagine Wiki, definito tramite:
- Lista esplicita di file (es. `security/segreti-e-accessi.md`)
- Directory prefixes (es. `control-plane/` include tutta la directory)

### Tipi di Scope

#### A) Macro-Scopes (`*-all`)

**Scopo**: Retrieval stabile per n8n/agents. Caricano tutto il contesto di un dominio.

| Scope | Descrizione | Pagine (~) |
|-------|-------------|------------|
| `governance-all` | Governance, control-plane, orchestration, gates | ~80 |
| `portal-all` | UI, frontend, UX | ~30 |
| `data-all` | DB, ETL, Datalake, DQ (ARGOS) | ~60 |
| `security-all` | IAM, security, accessi, KeyVault | ~40 |

**Esempio uso**:
```json
// n8n workflow "IAM provisioning"
{
  "scopes": ["security-all", "governance-all"]
  // → Carica ~120 pagine rilevanti per IAM
}
```sql

#### B) Micro-Scopes (`*-20`)

**Scopo**: Enforcement CI graduale. Subset di ~20 pagine critiche per phased adoption.

| Scope | Descrizione | Pagine |
|-------|-------------|--------|
| `db-datalake-20` | Core DB/Datalake (access mgmt, structure, ACL) | 20 |
| `controlplane-governance-20` | Core governance (gates, checklists, CI) | 20 |
| `argos-dq-20` | Core ARGOS/DQ (quality gates, policy DSL) | 20 |
| `portal-api-frontend-20` | Core Portal API/Frontend | 20 |
| `ops-runbooks-20` | Core runbooks operativi | 20 |
| `iam-security-20` | Core IAM/security | 20 |
| `frontend-ui-20` | Core UX/frontend | 20 |
| `onboarding-runbook-20` | Core onboarding/setup | 20 |
| `db-programmability-rest-20` | Core DB stored procedures/functions | 20 |

**Esempio uso**:
```powershell
# CI lint - Phase 1: solo 20 pagine critiche DB
pwsh scripts/wiki-tags-lint.ps1 `
  -Scope db-datalake-20 `
  -RequireFacets -FailOnError
```sql

#### C) Special Scope: `core`

**Scopo**: Subset minimale per bootstrap/onboarding rapido.

Include:
- `start-here.md`
- `docs-agentic-audit.md`
- `docs-tag-taxonomy.md`
- `docs-conventions.md`
- `intent-contract.md`
- `output-contract.md`
- Directory: `control-plane/`, `domains/`, `orchestrations/`, `UX/`

**Uso**: Primo caricamento per nuovi developer/agents.

---

## 🎯 Level 3: Retrieval Bundles

### Che Cos'è un Bundle?

Un **retrieval bundle** è una **combinazione predefinita di scopes** per un intent specifico, ottimizzato per:
- Ridurre token (carica solo ciò che serve)
- Aumentare precisione (contesto mirato)
- Velocizzare retrieval (meno pagine = meno latency)

### Struttura Bundle

```json
{
  "bundle-name": {
    "intent": "intent.name",
    "description": "Descrizione scenario",
    "scopes": ["scope1", "scope2", ...],
    "code_roots": ["path/to/code", ...],      // Opzionale
    "code_entrypoints": ["file1.ts", ...]     // Opzionale
  }
}
```sql

### Bundle Disponibili

#### Governance & Control Plane

**`n8n.orchestrator-dispatch`**
- **Intent**: `orchestrator.n8n.dispatch`
- **Scopes**: `governance-all`, `security-all`
- **Uso**: Webhook dispatch → validation → gate precheck → ewctl

**`n8n.controlplane.scripts`**
- **Intent**: `controlplane.scripts`
- **Scopes**: `governance-all`, `security-all`
- **Code roots**: `scripts/`, `agents/`
- **Uso**: Accesso on-demand agli script PowerShell

#### Database & Data Layer

**`n8n.db.core`**
- **Intent**: `db.ddl-inventory`
- **Scopes**: `data-all`, `governance-all`
- **Code roots**: `db/flyway/`, `db/provisioning/`
- **Uso**: Inventario DDL, architettura DB

**`n8n.db.table.create`**
- **Intent**: `db.table.create`
- **Scopes**: `data-all`, `security-all`, `governance-all`
- **Code roots**: `db/flyway/`, `db/provisioning/`
- **Uso**: Creazione tabella governata con gates

#### Data Quality & ETL

**`dq.validate`**
- **Intent**: `dq.validate`
- **Scopes**: `data-all`, `governance-all`
- **Uso**: Validazione DQ con ARGOS

**`etl.load-staging`**
- **Intent**: `etl.load-staging`
- **Scopes**: `data-all`, `governance-all`
- **Uso**: Caricamento dati in staging

**`etl.merge-target`**
- **Intent**: `etl.merge-target`
- **Scopes**: `data-all`, `governance-all`
- **Uso**: Merge staging→target (upsert governance-ready)

#### Security & IAM

**`n8n.iam-security`**
- **Intent**: `iam.security`
- **Scopes**: `security-all`, `governance-all`
- **Uso**: Provisioning IAM/permessi/accessi

#### Portal & Frontend

**`n8n.wf.excel-csv-upload`**
- **Intent**: `wf.excel-csv-upload`
- **Scopes**: `portal-all`, `data-all`, `security-all`, `governance-all`
- **Uso**: Workflow Excel/CSV upload end-to-end

**`ingest.upload-file`**
- **Intent**: `ingest.upload-file`
- **Scopes**: `portal-all`, `data-all`, `security-all`, `governance-all`
- **Uso**: Ingest/upload file con validazione multi-tenant

#### Development & Codex

**`codex.dev.core`**
- **Intent**: `codex.dev.core`
- **Scopes**: `governance-all`, `portal-all`, `security-all`
- **Code roots**: `EasyWay-DataPortal/`
- **Code entrypoints**: `README.md`, `app.ts`, `plan-viewer.html`
- **Uso**: GPT-5.2 Codex sviluppo sotto EasyWay-DataPortal/

#### Documentation

**`docs.core`**
- **Intent**: `docs.core`
- **Scopes**: `core`
- **Uso**: Contesto base governance docs (indice + convenzioni)

---

## 🔄 Flussi Operativi

### Flusso 1: n8n Retrieval Mirato

```mermaid
graph LR
    A[User: Crea tabella X] --> B[n8n webhook]
    B --> C{Intent detection}
    C --> D[Intent: db.table.create]
    D --> E[Carica bundle: n8n.db.table.create]
    E --> F[Scopes: data-all + security-all + governance-all]
    F --> G[Retrieval: ~150 pagine mirate]
    G --> H[LLM Context: DDL + gates + IAM]
    H --> I[Genera: Flyway + test + docs]
```sql

**Vantaggio**: ~150 pagine invece di 240 → -37% token, +60% precisione

### Flusso 2: CI Lint Graduale

```mermaid
graph TD
    A[Week 1: Pilot] --> B[Lint scope: db-datalake-20]
    B --> C[20 pagine validate]
    C --> D{Pass?}
    D -->|Yes| E[Week 2: Expand]
    D -->|No| F[Fix tags]
    F --> B
    E --> G[Lint scopes: db-datalake-20 + portal-api-frontend-20]
    G --> H[40 pagine validate]
    H --> I[Week 4: All micro-scopes]
    I --> J[160 pagine validate]
    J --> K[Month 3: All macro-scopes]
    K --> L[240 pagine validate]
```sql

**Strategia**:
1. **Pilot** (Week 1): `db-datalake-20` → FailOnError
2. **Expand** (Week 2-4): Tutti i `*-20` → FailOnError
3. **Stabilize** (Month 2-3): `*-all` → WarnOnly
4. **Enforce** (Month 4+): `*-all` → FailOnError

---

## 📋 Esempi Pratici

### Esempio 1: n8n Workflow DB Table Creation

**Scenario**: Agent deve creare tabella `USERS` con governance.

**Bundle**: `n8n.db.table.create`

**Scopes caricati**:
- `data-all` → Architettura DB, naming conventions, Flyway patterns
- `security-all` → RLS, permissions, audit requirements
- `governance-all` → Quality gates, approval workflow, CI checks

**Pagine caricate** (~150):
- `easyway-webapp/01-database-architecture.md`
- `db-user-access-management.md`
- `db-generate-artifacts-dsl.md`
- `security/segreti-e-accessi.md`
- `control-plane/agents-registry.md`
- `orchestrations/n8n-db-table-create.md`
- + tutte le pagine in `argos/`, `etl/`, `control-plane/`, `security/`

**Risultato**:
- LLM genera Flyway migration con naming corretto
- Include RLS policies
- Aggiunge test automatici
- Propone PR con gates pre-validati

### Esempio 2: CI Lint Phase 1

**Scenario**: Enforce tag compliance solo su pagine critiche DB.

**Comando**:
```powershell
pwsh scripts/wiki-tags-lint.ps1 `
  -Path "Wiki/EasyWayData.wiki" `
  -Scope db-datalake-20 `
  -RequireFacets `
  -FailOnError
```sql

**Scope**: `db-datalake-20`

**Pagine validate** (20):
- `db-user-access-management.md`
- `db-generate-artifacts-dsl.md`
- `datalake-ensure-structure.md`
- `datalake-apply-acl.md`
- + 16 altre pagine core DB

**Risultato**:
- Se TUTTE hanno i 5 facet → CI passa
- Se anche 1 manca facet → CI fallisce, deve fixare

**Next step**: Dopo fix, espandere a `controlplane-governance-20`

---

## 🛠️ Come Usare Scopes

### Lint con Scope

```powershell
# Dry-run (solo report, no fail)
pwsh scripts/wiki-tags-lint.ps1 -Scope db-datalake-20

# Strict enforcement
pwsh scripts/wiki-tags-lint.ps1 -Scope db-datalake-20 -RequireFacets -FailOnError

# Multi-scope
pwsh scripts/wiki-tags-lint.ps1 -Scope db-datalake-20,portal-api-frontend-20 -RequireFacets

# Macro-scope (warn only)
pwsh scripts/wiki-tags-lint.ps1 -Scope data-all -RequireFacets -WarnOnly
```sql

### n8n Workflow con Bundle

```javascript
// n8n Code node
const bundle = require('../../docs/agentic/templates/docs/retrieval-bundles.json');
const targetBundle = bundle.bundles['n8n.db.table.create'];

// Carica pagine dai scopes
const pages = await loadPagesFromScopes(targetBundle.scopes);

// Passa a LLM
const context = pages.map(p => p.content).join('\n\n');
const prompt = `${context}\n\nCrea tabella: ${userInput}`;
```sql

### Agent Script con Scope Filtering

```powershell
# agent-dba.ps1
param([string]$Scope = "data-all")

$scopesFile = "docs/agentic/templates/docs/tag-taxonomy.scopes.json"
$scopes = Get-Content $scopesFile | ConvertFrom-Json
$pages = $scopes.scopes.$Scope

# Carica solo quelle pagine
foreach ($page in $pages) {
    $content = Get-WikiPage -Path "Wiki/EasyWayData.wiki/$page"
    # Process...
}
```sql

---

## 📊 Metriche & Coverage

### Scope Coverage (Stima)

| Macro-Scope | Pagine | % Wiki Totale |
|-------------|--------|---------------|
| governance-all | ~80 | 33% |
| data-all | ~60 | 25% |
| security-all | ~40 | 17% |
| portal-all | ~30 | 12% |
| **Overlap** | ~30 | - |
| **Totale unico** | ~180 | 75% |

**Note**: Alcune pagine sono in più scope (es. `db-user-access-management.md` in `data-all` E `security-all`)

### Micro-Scope Coverage

| Categoria | Scopes | Pagine Totali |
|-----------|--------|---------------|
| DB & Data | 3 (`*-20`) | 60 |
| Portal & UI | 2 (`*-20`) | 40 |
| Security & IAM | 1 (`*-20`) | 20 |
| Governance & Ops | 2 (`*-20`) | 40 |
| **Totale** | **9 micro-scopes** | **~160** |

---

## 🔗 Integrazione con Facet Tags

### Come Scopes e Facets Lavorano Insieme

**Facets** = Coordinate (domain, layer, audience)  
**Scopes** = Raggruppamenti logici

```yaml
# Esempio: security/segreti-e-accessi.md
tags: [domain/security, layer/reference, audience/ops, ...]

# È inclusa in:
scopes:
  - security-all        # Perché in security/
  - iam-security-20     # Perché lista esplicita
  - governance-all      # Perché security governance-related
```sql

**Query combinata**:
```sql
-- Trova pagine security runbook per ops in scope iam-security-20
SELECT * FROM wiki_pages
WHERE scope = 'iam-security-20'
  AND 'domain/security' IN tags
  AND 'layer/runbook' IN tags
  AND 'audience/ops' IN tags
```sql

---

## 🚀 Best Practices

### 1. Scelta Scope per Retrieval

**Usa macro-scope** (`*-all`) quando:
- n8n workflow complesso
- Serve contesto end-to-end
- Non sai esattamente quali pagine servono

**Usa micro-scope** (`*-20`) quando:
- CI enforcement graduale
- Testing nuove regole
- Subset ben definito

### 2. Creazione Nuovi Scope

**Quando creare uno scope**:
- ✅ Scenario ricorrente (es. `migration-all` per migration guide)
- ✅ Enforcement specifico (es. `critical-path-30` per pagine critiche)
- ❌ One-off query → usa facet filtering

**Come definire uno scope**:
1. Identifica 15-25 pagine rappresentative
2. Preferisci directory prefixes (`security/`) vs liste enumerate
3. Testa retrieval efficacy (precision/recall)
4. Aggiungi a `tag-taxonomy.scopes.json`

### 3. Bundle Naming Convention

**Pattern**: `{sistema}.{azione}.{dettaglio}`

Esempi validi:
- `n8n.db.table.create` ✅
- `n8n.wf.excel-csv-upload` ✅
- `codex.dev.core` ✅

Esempi da evitare:
- `random-bundle-123` ❌ (non descrittivo)
- `everything` ❌ (troppo generico)

---

## 🔧 Manutenzione

### Quando Aggiornare Scopes

**Trigger per update**:
1. Nuova directory Wiki creata (es. `analytics/`)
2. Nuovo dominio emerge (es. `domain/monitoring`)
3. Scope diventa >100 pagine (considera split)
4. Coverage gaps identificati in retrieval

**Processo**:
1. Update `tag-taxonomy.scopes.json`
2. Update questa pagina Wiki (docs-tag-scopes.md)
3. Run lint su nuovo scope: `wiki-tags-lint.ps1 -Scope new-scope-name`
4. Update retrieval bundles se necessario

### Audit Periodico

```powershell
# Check scope overlap
pwsh scripts/wiki-scopes-audit.ps1 -ShowOverlap

# Check scope coverage
pwsh scripts/wiki-scopes-audit.ps1 -ShowCoverage

# Find orphan pages (non in nessuno scope)
pwsh scripts/wiki-scopes-audit.ps1 -FindOrphans
```sql

---

## 📚 Riferimenti Tecnici

### File Source of Truth

| File | Scopo | Ownership |
|------|-------|-----------|
| `docs/agentic/templates/docs/tag-taxonomy.scopes.json` | Definizione scopes | team-platform |
| `docs/agentic/templates/docs/retrieval-bundles.json` | Definizione bundles | team-platform |
| `docs/agentic/templates/docs/tag-taxonomy.json` | Facet values | team-platform |
| `Wiki/docs-tag-scopes.md` | **Questa pagina** (Doc user-facing) | team-platform |

### Script Utility

| Script | Funzione |
|--------|----------|
| `scripts/wiki-tags-lint.ps1` | Lint con scope filtering |
| `scripts/wiki-scopes-audit.ps1` | Audit coverage/overlap |
| `scripts/n8n-load-bundle.ps1` | Carica bundle per n8n |

---

## Vedi Anche

- [Tag Taxonomy (Controllata) - Facet Base](./docs-tag-taxonomy.md)
- [Agents Registry - Ownership & Intent](./control-plane/agents-registry.md)
- [Orchestrator n8n - Dispatch & Workflow](./orchestrations/orchestrator-n8n.md)
- [Documentazione Agentica - Audit & Policy](./docs-agentic-audit.md)
- [Retrieval Bundles - Mapping Intent → Context](./orchestrations/n8n-retrieval-bundles.md) (se esiste)



