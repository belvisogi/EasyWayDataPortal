---
id: ew-archive-imported-docs-2026-01-30-agent-rules-rules-master
title: 📖 AXET RULES - MASTER REFERENCE
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
```
---
title: "Rules Master - Complete Reference"
category: core
domain: reference
features:
  - complete
  - quick-ref
  - index
tags:
  - reference
  - complete
  - index
  - ado
  - wiki
  - governance
priority: high
audience:
  - ai-assistant
  - developer
script-refs: []
last-updated: 2026-01-12
related:
  - EXECUTION_RULES.md
  - TASK_RULES.md
  - ADO_EXPORT_GUIDE.md
  - GOVERNANCE.md
---

# 📖 AXET RULES - MASTER REFERENCE

> Documento di riferimento completo per tutti i comandi e regole Axet.  
> Aggiornato con nuove funzionalità: Wiki Review, Tagging System, Agent Docs Sync.
> Versione: 2026-01-12
> Leggere prima di fare modifiche al progetto Axet!

> [!IMPORTANT]
> **PER AI ASSISTANTS**: Quando l'utente chiede di fare qualcosa, **ESEGUILO DIRETTAMENTE**.
> NON dire "puoi eseguire questo comando". Tutti i comandi di lettura/visualizzazione sono SAFE (SafeToAutoRun=true).
> Vedi [EXECUTION_RULES.md](EXECUTION_RULES.md) per dettagli completi.

---

## 🎯 COMANDI ADO - GUIDA RAPIDA

### 1. Vista Completa PBI (360°)
```powershell
# Mostra: Parent, Children, Test Cases, Deployments, Description
axctl --intent pbi <ID>

# Esempio
axctl --intent pbi 184797
```

**Output Include**:
- ✅ Informazioni base (ID, Title, State, Priority, Tags)
- ✅ **Parent** (Epic/Feature padre)
- ✅ **Children** (Features/PBI/Task figli)
- ✅ **Test Cases** collegati
- ✅ **Deployments** (Build/Release linkate - count)
- ✅ Acceptance Criteria
- ✅ Description (primi 500 char)

### 2. Navigazione Gerarchia (Children)
```powershell
# Lista SOLO i figli di Epic/Feature/PBI
axctl --intent children -- <ID>

# Esempio
axctl --intent children -- 181579
```

**Output**: Tabella formattata con ID, Type, State, Title

### 3. Export con Stampa Automatica
```powershell
# Export PBI con preview immediata (VIA GOVERNANCE)
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'SID'" \
  -Print
```

**Flag `-Print`**:
- Mostra tabella formattata (max 20 items)
- Include: ID, Type, State, Title (60 char), Tags, Priority
- Mostra totale items + path files JSON/CSV

### 4. Altri Comandi ADO
```powershell
# Pipeline linkate a PBI
axctl --intent pipeline <ID>

# Lista tutte le pipeline
axctl --intent pipelines

# Storico esecuzioni pipeline
axctl --intent pipeline-history <PIPELINE_ID>

# Crea test case
axctl --intent ado-testcase --Title "TC-001" --Steps '[...]' --ParentId <ID>
```

### 5. Wiki Review & Normalize
```powershell
# Auto-detect wiki (trova Wiki/AdaDataProject.wiki automaticamente)
pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki

# Wiki cliente specifica
pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki -WikiPath "Path/To/Custom.wiki"
```
**Output**: Scan termini chiave, errori tipici, check glossario

---

## 📂 STRUTTURA FILE PROGETTO

```
Axet/
├── Rules/                           # Documentazione regole & guide
│   ├── README.it.md                 # Overview principale
│   ├── RULES_MASTER.md              # Questo file (master reference)
│   ├── EXECUTION_RULES.md           # Regole autonomous execution AI
│   ├── TASK_RULES.md                # Workflow task-oriented
│   ├── TAGGING_SYSTEM.md            # Sistema tag gerarchici (NEW)
│   ├── AGENT_DOCS_SYNC.md           # Agent manutenzione docs (NEW)
│   ├── GOVERNANCE.md                # Orchestration & governance
│   ├── ADO_EXPORT_GUIDE.md          # Guida ADO operations
│   ├── WIKI_REVIEW_GUIDE.md         # Guida Wiki review
│   ├── QA_TROUBLESHOOTING.md        # FAQ troubleshooting
│   ├── FINAL_VERIFICATION.md        # Status verification
│   ├── DOCS_INDEX.yaml              # Index metadata docs+scripts (TODO)
│   └── scripts/
│       ├── axctl.ps1                # Entry point principale
│       ├── ai-context-refresh.ps1   # Context generator per AI
│       └── show-last-export.ps1     # Helper ultimo export
│
├── Rules.Vault/                    # Implementation vault
│   ├── agents/
│   │   ├── agent_ado_userstory/
│   │   │   └── manifest.json       # ADO agent specification
│   │   └── kb/
│   │       └── recipes.jsonl       # Knowledge base recipes
│   ├── scripts/ps/
│   │   └── agent-ado-scrummaster.ps1 # ADO core logic
│   └── config/
│       ├── connections.json        # ADO org/project config
│       └── secrets.json            # PAT tokens (gitignored)
│
└─ .gemini/
    └── context.md                  # AI context auto-load
```

---

## 🔧 AZIONI ADO DISPONIBILI

| Action | Descrizione | Parametri | Output |
|--------|-------------|-----------|--------|
| `ado:pbi.get` | Vista 360° work item | `-Id` | Parent + Children + Test + Deploy |
| `ado:pbi.children` | Solo figli | `-Id` | Lista children formattata |
| `ado:userstory.export` | Export PBI/Stories | `-Query`, `-WorkItemType`, `-Print` | JSON + CSV (opz. tabella) |
| `ado:testcase.create` | Crea test case | `-Title`, `-Steps`, `-ParentId` | Test case ID |
| `ado:pipeline.get-runs` | Build/Release linkate | `-Id` | Lista builds/releases |
| `ado:pipeline.list` | Lista pipeline | - | Tabella pipeline definitions |
| `ado:pipeline.history` | Storico pipeline | `-Id` | Ultime 10 esecuzioni |

---

## 📖 DOCUMENTAZIONE FILE PER FILE

### 1. README.it.md
**Path**: `Rules/README.it.md`
**Sezioni Chiave**:
- Step 5 (linee 480-490): Comandi PBI e Children
- Struttura bundle (linee 1-100)
- Agent fleet overview

**Da Ricordare**:
- Entry point: `axctl.ps1`
- Convenzione output: `out/<categoria>/`
- Auto-CSV sempre generato negli export

### 2. ADO_EXPORT_GUIDE.md
**Path**: `Rules/ADO_EXPORT_GUIDE.md`
**Sezioni Chiave**:
- Comando base export (linee 20-35)
- Interrogare singolo PBI con vista 360° (linee 131-178)
- Esplorare gerarchia children (linee 181-206)
- Print flag (linea 28-36)

**Esempi Tag**:
- SID, IFRS9, DeepDive, TeamTool, GCFO, AIR

### 3. QA_TROUBLESHOOTING.md
**Path**: `Rules/QA_TROUBLESHOOTING.md`
**FAQ Aggiunte**:
- Q: pbi.get non mostra parent/children (linee 30-37)
- Q: children restituisce vuoto (linee 39-46)

**Soluzioni Comuni**:
- Verificare relazioni ADO (Hierarchy-Forward/Reverse)
- PAT scaduto → rigenerare
- WIQL syntax → usare @project macro

### 4. agent_ado_userstory/manifest.json
**Path**: `Rules.Vault/agents/agent_ado_userstory/manifest.json`

**Knowledge Sources** (linee 34-42):
```json
"knowledge_sources": [
  "Rules/README.it.md",
  "Rules/ADO_EXPORT_GUIDE.md",
  "Rules/QA_TROUBLESHOOTING.md",
  "Rules.Vault/agents/kb/recipes.jsonl",
  ...
]
```

**Actions Documentate**:
- `ado:pbi.get`: Vista 360° (linee 251-270)
- `ado:pbi.children`: Children (linee 272-292)
- `ado:userstory.export`: Con param `print` (linee 165-198)

### 5. recipes.jsonl
**Path**: `Rules.Vault/agents/kb/recipes.jsonl`

**Recipe ADO**:
```json
{"id":"kb-ado-pbi-get","trigger":"visualizza pbi","intent":"ado:pbi.get","procedure":"axctl --intent pbi <ID>"}
{"id":"kb-ado-pbi-children","trigger":"visualizza figli epic","intent":"ado:pbi.children","procedure":"axctl --intent children -- <ID>"}
```

---

## 🎨 RELAZIONI ADO (Dettagli Tecnici)

**Parsed da `ado:pbi.get`**:
```javascript
Hierarchy-Reverse      → Parent (Epic se Feature, Feature se PBI)
Hierarchy-Forward      → Children (Features, PBI, Task, Test Cases)
TestedBy-Forward       → Test Cases (relazione specifica)
ArtifactLink           → Build/Release (vstfs:///Build/Build*, vstfs:///ReleaseManagement*)
```

**API Version**: 7.0 (stabile, non preview)

**URL Pattern**:
```
GET {orgUrl}/_apis/wit/workitems/{id}?$expand=relations&api-version=7.0
```

---

## 💡 USE CASES COMUNI

### Use Case 1: Analisi Epic Completo
```powershell
# 1. Vista completa Epic
axctl --intent pbi 181579

# 2. Lista tutti i figli (Features)
axctl --intent children -- 181579

# 3. Per ogni Feature, vedere i suoi PBI
axctl --intent children -- 181587
```

### Use Case 2: Export Tag con Preview
```powershell
# Export tutti i PBI SID + stampa primi 20
pwsh Rules.Vault/scripts/ps/agent-ado-scrummaster.ps1 \
  -Action 'ado:userstory.export' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.Tags] CONTAINS 'SID'" \
  -Print

# Output: out/devops/yyyyMMddHHmmss_ado-export.json + .csv
```

### Use Case 3: Tracking Deployment
```powershell
# Vedere se PBI è stato deployato
axctl --intent pbi 184797

# Output include sezione Deployments:
#   Builds: 2 linked
#   Releases: 1 linked
```

---

## 🚨 TROUBLESHOOTING

### Problema: "No children found"
**Causa**: Work item senza figli o relazioni errate
**Soluzione**:
1. Aprire ADO Web UI
2. Verificare che esistano work items linkati come "Child"
3. Verificare gerarchia: Epic → Feature → PBI → Task

### Problema: pbi.get non mostra parent/children
**Causa**: Script obsoleto o no relazioni in ADO
**Soluzione**:
1. Verificare versione script (deve usare API 7.0)
2. Controllare relazioni in ADO
3. Relazioni devono essere tipo `Hierarchy-Forward/Reverse`

### Problema: Export troppo lento
**Causa**: Query senza filtri su backlog grande
**Soluzione**:
```powershell
# Aggiungere filtro temporale
--Query "... WHERE [System.ChangedDate] > @today-7"
```

### Problema: CSV vuoto o corrotto
**Causa**: Encoding o delimiter issues
**Soluzione**:
- CSV usa delimiter pipe `|` (non virgola)
- Encoding UTF-8
- Verificare con: `Import-Csv file.csv -Delimiter '|'`

---

## 📊 TEST VALIDATI

| Feature | Test ID | Risultato | Note |
|---------|---------|-----------|------|
| pbi.get (360°) | #184797 | ✅ | 1 parent + 12 children |
| pbi.get (360°) | #181587 | ✅ | Parent + children + state colors |
| pbi.children | #181579 | ✅ | 1 child (Feature) |
| export -Print | SID tag | ✅ | 81 items visualizzati |

---

## 🔄 CHANGELOG FEATURES

### 2026-01-12 - Major Update
- ✅ **Enhanced pbi.get**: Aggiunto parent, children, test cases, deployments
- ✅ **New pbi.children**: Comando dedicato navigazione gerarchia
- ✅ **Print flag**: Export con preview automatica (-Print)
- ✅ **Documentation**: 6 file aggiornati, 20+ esempi
- ✅ **AI Context**: Script ai-context-refresh.ps1

---

## 📝 BEST PRACTICES

1. **Usare sempre `-Print`** per export quando vuoi preview immediata
2. **Preferire `pbi` a `pbi.children`** per vista completa (include già children)
3. **Filtrare sempre per tag** o date negli export (`WHERE [System.Tags] CONTAINS '...'`)
4. **Usare @project macro** invece di hardcodare nome progetto
5. **Verificare PAT** prima di troubleshooting (scade periodicamente)

---

## 🎯 QUICK REFERENCE CARD

```powershell
# Vista 360° (RECOMMENDED)
axctl --intent pbi <ID>

# Solo figli
axctl --intent children -- <ID>

# Export + stampa
pwsh Rules.Vault/scripts/ps/agent-ado-scrummaster.ps1 -Action 'ado:userstory.export' -Query "..." -Print

# Pipeline
axctl --intent pipeline <ID>

# AI Context refresh
pwsh Rules/scripts/ai-context-refresh.ps1 -Compact
```

---

**📌 RICORDA**: Tutti i comandi ADO richiedono:
- ✅ PAT configurato (`secrets.json` o `$env:ADO_PAT`)
- ✅ Connessione ADO (`connections.json`: org + project)
- ✅ Permessi Read su Work Items e Build

---

**Documento aggiornato**: 2026-01-12 19:51
**Versione Rules**: 3.0 (con enhanced pbi.get, children, print)


