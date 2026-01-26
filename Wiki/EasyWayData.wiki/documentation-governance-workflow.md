---
tags: [domain/docs, layer/reference, governance, best-practice, documentation]
updated: 2026-01-16
owner: team-platform
summary: Workflow completo del Documentation Gardener Cycle - processo iterativo di governance documentale con Knowledge Graph, Master Hierarchy e Agent-driven analysis.
status: draft
---

[Home](../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/docs-governance|Docs]] > [[Layer - Reference|Reference]]

# Documentation Governance Workflow 🌳

> **Filosofia**: La documentazione è un giardino vivo. Non si progetta una volta, si coltiva continuamente con un processo data-driven e agent-assisted.

## Il Sistema Completo

```mermaid
flowchart TD
    A[📁 Files .md nella Wiki] -->|1. Scan| B[agent-docs-scanner.ps1]
    B -->|genera| C[knowledge-graph.json]
    C -->|contiene| D[Pages + Summaries + Tags]
    
    E[tag-master-hierarchy.json] -->|definisce| F[Approved Tags + Mappings]
    
    D -->|2. Audit| G{AuditHierarchy}
    F -->|confronta con| G
    
    G -->|produce| H[📊 Compliance Report]
    H -->|95%+ ✅| I[Sistema Sano]
    H -->|<95% ⚠️| J[Orphan Tags Detected]
    
    J -->|3. Analyze| K[AnalyzeExotics]
    K -->|legge contenuto file| L{Semantic Analysis}
    
    L -->|KEEP| M[Tag Unico Valido]
    L -->|MERGE| N[Aggiorna Hierarchy]
    L -->|DELETE| O[🗑️ CleanTags]
    
    O -->|rimuove da frontmatter| P[Backup + Clean]
    N -->|applica mapping| P
    
    P -->|4. Rebuild| Q[Rigenera Graph]
    Q -->|5. Links| R[AnalyzeLinks]
    
    R -->|trova pagine correlate| S[Link Suggestions]
    
    Q -->|6. Index| T[GenerateHierarchicalIndex]
    T -->|crea struttura| U[📚 Indices/PILLAR/Category]
    
    U -->|navigazione Obsidian| V[KNOWLEDGE-GRAPH.md]
    
    I -->|weekly check| G
    
    W[ProposeHierarchy] -->|se >15 docs per tag| X{Cluster Semantico?}
    X -->|Sì| Y[Proponi Livello 3]
    X -->|No| Z[Mantieni Livello 2]
    
    style C fill:#e1f5fe
    style F fill:#fff9c4
    style H fill:#c8e6c9
    style K fill:#ffccbc
    style U fill:#f3e5f5
    style V fill:#c5e1a5
```sql

## Le 8 Azioni dello Scanner

### 1. **Scan** - Indicizzazione Base
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action Scan
```sql
**Output**: `agents/memory/docs-content-index.json`  
**Cosa fa**: Scansiona i file .md, estrae keyword, crea indice inverso (keyword → file).

---

### 2. **BuildGraph** - Generazione Knowledge Graph
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action BuildGraph
```sql
**Output**: `agents/memory/knowledge-graph.json`  
**Cosa fa**:
- Estrae il `summary` dal frontmatter di ogni file
- Se manca, usa i primi 150 caratteri
- Crea il mapping `file → (summary, tags)`
- **Questo è il cuore del sistema RAG**

**Struttura Output**:
```json
{
  "generated_at": "2026-01-14 12:00:00",
  "stats": { "total_files": 316, "files_with_summary": 306 },
  "pages": {
    "Wiki/file.md": {
      "summary": "Descrizione semantica del file",
      "tags": ["domain/db", "layer/spec"]
    }
  },
  "tags": {
    "domain/db": {
      "description": "Database Layer...",
      "keywords": ["sql", "table", "stored procedure"],
      "linked_pages": ["file1.md", "file2.md"]
    }
  }
}
```sql

---

### 3. **AuditHierarchy** - Controllo Compliance
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action AuditHierarchy
```sql
**Output**: Report console + statistiche  
**Cosa fa**:
- Carica `knowledge-graph.json` + `tag-master-hierarchy.json`
- Confronta i tag reali con quelli approvati
- Calcola % compliance
- Identifica orphan tags (non mappati)

**Output Sample**:
```sql
📐 HIERARCHY STRUCTURE:
   Pillars (Level 1): 6
      DOMAIN -> 13 categories
      PROCESS -> 9 categories
      ...
   Total Approved Tags (Level 2): 53
   Loose Tag Mappings: 135

📊 AUDIT STATS:
   Compliant Tags: 1823/1919 (95%+)
   Orphan Tag Types: 96
   Orphan Occurrences: 96 (5%)
```sql

---

### 4. **AnalyzeExotics** - Analisi Semantica Profonda
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action AnalyzeExotics
```sql
**Output**: `agents/memory/exotic-tags-analysis.json`  
**Cosa fa**:
- Trova i tag usati una sola volta
- **Legge il contenuto COMPLETO** del file
- Propone azione: KEEP / MERGE / DELETE
- Salva report dettagliato con reasoning

**Decision Logic**:
- `why`, `how`, `what`, `meta` → **DELETE** (filosofici senza valore tassonomico)
- `database`, `testing`, `guardrail` → **MERGE** (sinonimi/varianti lowercase)
- `spid`, `rls`, `token-tuning` → **KEEP** (concetti specifici validi)

---

### 5. **CleanTags** - Rimozione Automatica Tag Noise
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action CleanTags
```sql
**Output**: File modificati + backup  
**Cosa fa**:
- Legge `exotic-tags-analysis.json`
- Per ogni tag con `Action: DELETE`:
  - Rimuove il tag dal frontmatter YAML
  - Crea backup con timestamp
- Report di cleanup con file modificati

**Safety**:
- Backup automatico (`.backup-YYYYMMDD-HHMMSS`)
- Solo remove tag, non tocca contenuto
- Report errori gracefully

---

### 6. **ProposeHierarchy** - Evoluzione Automatica
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action ProposeHierarchy
```sql
**Output**: Report console  
**Cosa fa**:
- Analizza tag con >15 documenti
- Estrae top keywords dai summary
- **Propone Livello 3** solo se ci sono cluster semantici distinti
- Segue Vector DB best practices (no frammentazione)

**Esempio Output**:
```sql
📌 domain/db (41 docs)
   Top themes: tenant, tabelle, governato, audit
   ✅ No split needed (homogeneous cluster)
```sql

---

### 7. **AnalyzeLinks** - Suggerimenti Link Semantici
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action AnalyzeLinks
```sql
**Output**: `agents/memory/link-suggestions.json` + `obsidian-link-suggestions.md`  
**Cosa fa**:
- Analizza tag in comune tra pagine
- Trova pagine semanticamente correlate (≥2 tag condivisi)
- Suggerisce wikilink `[[page]]` da aggiungere
- Evita super-hub (max 5 suggerimenti per pagina)

**Risultato**:
- 1200+ suggerimenti di link
- Report Obsidian-friendly
- Migliora navigazione semantica

---

### 8. **GenerateHierarchicalIndex** - Creazione Indici Strutturati
```powershell
pwsh scripts/ps/agent-docs-scanner.ps1 -Action GenerateHierarchicalIndex
```sql
**Output**: `KNOWLEDGE-GRAPH.md` + `indices/PILLAR/Category.md`  
**Cosa fa**:
- Crea root index (`KNOWLEDGE-GRAPH.md`)
- Genera 6 pillar indexes (`indices/DOMAIN/index.md`, ecc.)
- Genera 53 category indexes (`indices/DOMAIN/DB.md`, ecc.)
- Ogni index linka solo le pagine con quel tag

**Struttura generata**:
```sql
KNOWLEDGE-GRAPH.md (root)
└── indices/
    ├── DOMAIN/
    │   ├── index.md
    │   ├── DB.md (52 pagine)
    │   ├── Control-Plane.md (84 pagine)
    │   └── ...
    ├── AUDIENCE/
    │   ├── index.md
    │   ├── Dev.md (222 pagine)
    │   └── ...
    └── ... (6 pillars totali)
```sql

**Beneficio**: Navigazione gerarchica in Obsidian invece di super-hub centrale!

---

## File Critici del Sistema

### 1. `tag-master-hierarchy.json` (LA LEGGE)
**Location**: `agents/memory/tag-master-hierarchy.json`  
**Owner**: Umano (con AI assistant)  
**Update Frequency**: Settimanale (dopo review proposal)

**Struttura**:
```json
{
  "hierarchy": {
    "DOMAIN": { "children": ["DB", "API", "UX", ...] },
    "PROCESS": { "children": ["Governance", "Testing", ...] },
    ...
  },
  "tag_mapping": {
    "mappings": {
      "flyway": "TECH/Flyway",
      "migration": "PROCESS/Migration",
      ...
    }
  }
}
```sql

### 2. `knowledge-graph.json` (LA REALTÀ)
**Location**: `agents/memory/knowledge-graph.json`  
**Owner**: Scanner automatico  
**Update Frequency**: Ad ogni commit (CI/CD hook)

---

## Regole di Governance

### ✅ DO
1. **Tag multi-facet**: Usa `[domain/db, layer/spec, audience/dba]` per massimizzare retrieval
2. **Summary obbligatorio**: Ogni file DEVE avere un `summary:` nel frontmatter
3. **Lowercase per mappings**: I mapping coprono varianti (es. `agents` → `DOMAIN/Agents`)
4. **Iterazione settimanale**: Review orphan report ogni settimana

### ❌ DON'T
1. **No tag filosofici**: Evita `why`, `how`, `meta`, `riflessione`
2. **No duplicati concettuali**: `guardrail` = `governance`, usa uno solo
3. **No micro-categorie**: Se un tag ha <3 file, probabilmente è rumore
4. **No Livello 3 prematuro**: Aspetta >15 doc + evidenza semantica

---

## Ciclo di Vita (Gardener Loop)

### Settimana 0: Setup
1. Run `BuildGraph` per baseline
2. Run `AuditHierarchy` → target 90%+ compliance
3. Fix top orphan con mappings nel hierarchy

### Settimana N (Manutenzione)
1. **Lunedì**: Run `AuditHierarchy` post-weekend commits
2. **Mercoledì**: Run `AnalyzeExotics` se orphan > 5%
3. **Venerdì**: Review proposte, update hierarchy JSON
4. **Rigenera Graph**: `BuildGraph` dopo ogni hierarchy update

### Milestone Check (Mensile)
1. Run `ProposeHierarchy` → verifica se serve Livello 3
2. Export metrics (compliance trend)
3. Review tag usage heatmap

---

## Metriche di Successo

| Metric | Target | Current |
|--------|--------|---------|
| Compliance % | >90% | **95%** ✅ |
| Files with Summary | >95% | **97%** ✅ |
| Orphan Tags (distinct) | <100 | **96** ✅ |
| Avg Tags per File | 5-8 | ~7.8 ✅ |

---

## Troubleshooting

### "Compliance è scesa sotto il 90%"
1. Run `AuditHierarchy` per vedere orphan list
2. Run `AnalyzeExotics` per capire cosa sono
3. Batch-add mapping per top 20 orphan

### "Vector DB retrieval è impreciso"
1. Verifica che i summary siano descrittivi (no "Documento su...")
2. Check tag multi-facet (almeno 3 tag per file)
3. Considera Livello 3 se un dominio ha >50 doc

### "Troppi tag KEEP in AnalyzeExotics"
È normale! Molti tag exotic sono legittimi (es. `spid`, `cie`).  
Solo DELETE rumore vero (`why`, `how`, acronym senza context).

---

## Futuro: Auto-apply

**Roadmap**:
- [ ] `-Action FixOrphans` → Riscrive frontmatter automaticamente
- [ ] CI/CD hook per auto-run scanner su commit
- [ ] Dashboard compliance con trend chart
- [ ] LLM-powered summary generation per file senza frontmatter

---

## References
- [Best Practices Documentation Gardening](./best-practices/documentation-gardening.md)
- [Tag Taxonomy Schema](./docs-tag-taxonomy.md)
- Knowledge Graph: `agents/memory/knowledge-graph.json`
- Master Hierarchy: `agents/memory/tag-master-hierarchy.json`




