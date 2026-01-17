---
title: "ADO Export Guide - Query & Export Operations"
category: ado
domain: query
features:
  - pbi-get
  - pbi-children
  - export-print
  - pipeline
tags:
  - ado
  - query
  - export
  - pbi
  - pipeline
priority: medium
audience:
  - ai-assistant
  - developer
script-refs:
  - agent-ado-governance.ps1
  - agent-ado-scrummaster.ps1
  - show-last-export.ps1
last-updated: 2026-01-17
related:
  - EXECUTION_RULES.md
  - RULES_MASTER.md
---

# Guida Export Azure DevOps - Per AI Assistant

Questa guida spiega come estrarre Work Items (PBI, User Story, ecc.) da Azure DevOps usando `axctl`.

> [!TIP]
> **Per AI**: Esegui direttamente i comandi di lettura/export senza chiedere conferma. Tutti sono safe (SafeToAutoRun=true). Usa sempre `-Print` per export quando user chiede "mostra".

> [!IMPORTANT]
> **SAFE EXECUTION STRATEGY**: Per query complesse o su grandi dataset, usa **SEMPRE** l'approccio a 2 step:
> 1. **Export massivo** (Command: `ado export -WorkItemType "All"`)
> 2. **Filtro locale** (Command: `pwsh Rules/scripts/filter-export.ps1`)
> EVITA di eseguire query con troppi join/filtri direttamente su ADO per prevenire timeout o blocchi.

---

## ⚡ Best Practice: Approccio a 2 Step per Filtri Complesso

**Problema**: ADO WIQL può rifiutare query con filtri combinati (es. tag + data) restituendo `400 Bad Request`.

**Soluzione**: Usa l'approccio a 2 step:

### Step 1: Export Semplice (Senza Filtro Data)
Esegui export con filtro base (solo tag/tipo) che **funziona sempre**:

```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 `
  -Action 'ado:intent.resolve' `
  -WorkItemType 'Product Backlog Item' `
  -Query "SELECT [System.Id], [System.Title], [System.State], [System.CreatedDate], [System.Tags]
           FROM WorkItems
           WHERE [System.TeamProject] = @project
             AND [System.WorkItemType] = 'Product Backlog Item'
             AND [System.Tags] CONTAINS 'AIR'"
```

### Step 2: Filtro Locale in PowerShell
Filtra l'export locale per data/altri criteri:

```powershell
# Trova ultimo export
$last = Get-ChildItem "out/devops/*_ado-export.json" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1

# Carica e filtra per 2025
$json = Get-Content $last.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
$from = Get-Date '2025-01-01T00:00:00Z'
$to   = Get-Date '2026-01-01T00:00:00Z'

$items2025 = $json | Where-Object {
  $created = Get-Date $_.fields.'System.CreatedDate'
  $created -ge $from -and $created -lt $to
}

# Mostra risultati
Write-Host "Trovati: $($items2025.Count) items" -ForegroundColor Green
$items2025 | Select-Object `
  @{ Name='ID'; Expression={ $_.fields.'System.Id' } }, `
  @{ Name='Title'; Expression={ $_.fields.'System.Title' } }, `
  @{ Name='State'; Expression={ $_.fields.'System.State' } }, `
  @{ Name='CreatedAt'; Expression={ $_.fields.'System.CreatedDate' } } |
  Format-Table -AutoSize
```

**Quando Usare**:
- ✅ Query con tag + filtro data
- ✅ Filtri multipli complessi
- ✅ Quando WIQL restituisce 400 Bad Request
- ✅ Per affidabilità massima

**Vantaggi**:
- Funziona **sempre** (export semplice mai fallisce)
- Flessibilità totale nel filtro locale
- Puoi applicare filtri multipli (data, stato, tags, ecc.)
- Risultati completi (non troncati)

---

## Prerequisites

1. **Configurazione connessione ADO**:
   - File: `Rules.Vault/config/connections.json` (org, project)
   - File: `Rules.Vault/config/secrets.json` (PAT)

2. **Verifica connettività**:
   ```powershell
   axctl --intent ado-check
   ```

---

## 🚀 Identificare Work Items di Deploy

**Problema**: Come trovare work item relativi a deployment/release in un periodo specifico?

**Soluzione**: Pattern matching su Tags e Title con termini comuni di deploy.

### Pattern Comuni Deploy

Work item di deploy tipicamente contengono:

**In Tags**:
- `Deploy`
- `Release`
- `Prod` / `Production`
- `Rilascio`

**In Title**:
- "Deploy"
- "Release"
- "Rilascio"
- Pattern: `ADA - [Progetto] - Release X.Y.Z - PROD`

**WorkItemType**:
- `Deploy` (tipo specifico)
- `Test Suite` (validation pre-deploy)

### Approccio: Export + Pattern Match

**Step 1**: Export work items del periodo
```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-userstory.ps1 `
  -Action 'ado:userstory.export' `
  -WorkItemType 'All' `
  -Query "SELECT [System.Id], [System.Title], [System.State], [System.CreatedDate], 
                 [System.Tags], [System.WorkItemType]
           FROM WorkItems
           WHERE [System.TeamProject] = @project
             AND [System.ChangedDate] >= '2025-01-01'"
```

**Step 2**: Filtra per pattern deploy
```powershell
# Trova ultimo export
$last = Get-ChildItem "out/devops/*_ado-export.json" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1

# Carica
$json = Get-Content $last.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

# Filtra per anno 2025
$from = Get-Date '2025-01-01'
$to   = Get-Date '2026-01-01'
$items2025 = $json | Where-Object {
  $created = Get-Date $_.fields.'System.CreatedDate'
  $created -ge $from -and $created -lt $to
}

# Applica pattern deploy
$deployItems = $items2025 | Where-Object {
  $tags  = $_.fields.'System.Tags'
  $title = $_.fields.'System.Title'
  
  # Match: Deploy, Release, Prod, Rilascio
  ($tags -like '*Deploy*') -or 
  ($tags -like '*Release*') -or 
  ($tags -like '*Prod*') -or 
  ($title -like '*deploy*') -or 
  ($title -like '*release*') -or
  ($title -like '*rilascio*')
}

Write-Host "🚀 Deploy items 2025: $($deployItems.Count)" -ForegroundColor Green

# Mostra risultati
$deployItems | 
  Select-Object `
    @{ Name='ID'; Expression={ $_.fields.'System.Id' } }, `
    @{ Name='Title'; Expression={ $_.fields.'System.Title' } }, `
    @{ Name='Type'; Expression={ $_.fields.'System.WorkItemType' } }, `
    @{ Name='State'; Expression={ $_.fields.'System.State' } }, `
    @{ Name='Tags'; Expression={ $_.fields.'System.Tags' } } |
  Format-Table -AutoSize
```

### Varianti Comuni

**Solo Deploy PROD** (escludi test suite):
```powershell
$deployProd = $deployItems | Where-Object {
  $_.fields.'System.WorkItemType' -eq 'Deploy'
}
```

**Per Progetto Specifico** (es. AIR):
```powershell
$deployAIR = $deployItems | Where-Object {
  $_.fields.'System.Tags' -like '*AIR*'
}
```

**Deploy Completati** (State = Done):
```powershell
$deployDone = $deployItems | Where-Object {
  $_.fields.'System.State' -eq 'Done'
}
```

### Helper Script

Usa `filter-export.ps1` con pattern custom:

```powershell
# Filtra per 2025 + tag contiene Release
pwsh Rules/scripts/filter-export.ps1 `
  -Latest `
  -FromDate "2025-01-01" `
  -ToDate "2026-01-01" `
  -TagContains "Release"
```

### Pattern Reali (Esempi)

Dal tuo sistema ADA:
```
Pattern 'Deploy': 13 items
Pattern 'Release': 53 items
Pattern 'Prod': 47 items
Pattern 'Rilascio': 5 items

Esempi:
- "ADA - [AIR] - Release 14.0 - PROD" (Deploy)
- "Deploy IDQS Rel 2.4.0 - PROD" (Deploy)
- "DDT Release 15.1.0" (Test Suite)
```

**Best Practice**:
- Usa pattern multipli per coverage completa
- Verifica sia Tags che Title
- Considera WorkItemType per precisione
- Filtra State per deploy attivi vs completati

---

## Comando Base

```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State], [System.Tags] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'TAG'"
```

**Output**: `out/devops/yyyyMMddHHmmss_ado-export.json` + `yyyyMMddHHmmss_ado-export.csv`

**💡 Stampa Automatica**: Aggiungi `--Print` per visualizzare subito i risultati a video:
```powershell
# Via chiamata diretta con -Print
pwsh Rules.Vault/scripts/ps/agent-ado-userstory.ps1 -Action 'ado:userstory.export' -WorkItemType 'Product Backlog Item' -Query "..." -Print
```

Mostra una tabella formattata con: ID, Type, State, Title (max 60 char), Tags, Priority (primi 20 items).

---

## Chiamata Diretta (Consigliata)

Se `axctl` non funziona correttamente, usa la chiamata diretta allo script:

```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-userstory.ps1 `
  -Action 'ado:userstory.export' `
  -NonInteractive `
  -WorkItemType 'Product Backlog Item' `
  -Query "SELECT [System.Id], [System.Title], [System.State], [System.Tags] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'TAG'"
```

**Vantaggi:**
- ✅ Più affidabile (skip wrapper axctl)
- ✅ Parametri espliciti
- ✅ Auto-CSV incluso

---

## Esempi per Progetto/Tag

### IFRS9 (Regolamentare)
```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State], [Microsoft.VSTS.Common.Priority] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'IFRS9' ORDER BY [System.ChangedDate] DESC"
```

### SID (Sistema Informativo Direzionale)
```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'SID'"
```

### DeepDive (Analytics/Approfondimenti)
```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'DeepDive'"
```

### TeamTool (Strumenti Interni)
```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'TeamTool'"
```

### GCFO (Group CFO)
```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'GCFO'"
```

### AIR (Annual Integrated Reporting)
```powershell
axctl --intent ado-export --WorkItemType "Product Backlog Item" --Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.Tags] CONTAINS 'AIR'"
```

---

## Filtri Avanzati

### Per Stato
```powershell
# Solo PBI in stato "New"
--Query "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.State] = 'New' AND [System.WorkItemType] = 'Product Backlog Item'"
```

### Per Area Path
```powershell
# PBI in area specifica
--Query "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.AreaPath] UNDER 'ADA Project - Data Strategy\\Backend\\Datahub - IFRS9'"
```

### Per Sprint/Iteration
```powershell
# PBI in uno sprint specifico
--Query "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.IterationPath] = 'ADA Project - Data Strategy\\NTT Data Backend\\Sprint 75'"
```

---

## Campi Disponibili (Default)

Il comando di export include **18 campi**:

| Campo | Descrizione |
|-------|-------------|
| `System.Id` | ID Work Item |
| `System.Title` | Titolo |
| `System.State` | Stato (New, Active, Done) |
| `System.AssignedTo` | Assegnatario |
| `System.Tags` | Tag |
| `System.AreaPath` | Area Path |
| `System.IterationPath` | Sprint/Iteration |
| `System.CreatedDate` | Data creazione |
| `System.ChangedDate` | Ultima modifica |
| `System.CreatedBy` | Chi ha creato |
| `Microsoft.VSTS.Common.Priority` | Priorità (1-4) |
| `Microsoft.VSTS.Common.BusinessValue` | Business Value |
| `Microsoft.VSTS.Scheduling.Effort` | Sforzo stimato |
| `Microsoft.VSTS.Scheduling.StoryPoints` | Story Points |
| `Microsoft.VSTS.Scheduling.TargetDate` | Target Date |
| `Microsoft.VSTS.Common.AcceptanceCriteria` | Criteri di accettazione |
| `System.Description` | Descrizione (HTML cleanup) |

---

## Interrogare un Singolo PBI (Senza Export)

Per visualizzare un Work Item singolo **a video** senza creare file:

```powershell
# Via axctl
axctl --intent pbi 184797

# Oppure direttamente
pwsh Rules.Vault/scripts/ps/agent-ado-userstory.ps1 -Action 'ado:pbi.get' -Id 184797
```

**Output a schermo** (versione completa con tutte le relazioni):
```
========== PBI #184797 ==========

ID:          184797
Title:       SID - Input file - SBTI
State:       Done (colorato)
Priority:    2
Assigned:    Polito Lorenzo (NTT Data)
Area:        ADA Project - Data Strategy\Backend\...
Iteration:   Sprint 68
Tags:        SID

Parent:
  #181587 (Feature) - SID - Restricted List Process ( RIL )

Children:
  #189267 (Test Case) [Design] 184797 - RIL_INPUT_SBTI - upload file OK
  #189266 (Test Case) [Closed] 184797 - RIL_INPUT_SBTI - error saving

Test Cases:
  (Se collegati tramite relazione TestedBy)

Deployments:
  Builds: 2 linked
  Releases: 1 linked

Acceptance Criteria:
...

========================================
```

> [!TIP]
> Il comando `pbi` ora mostra **tutta la storia del work item**: parent (la gerarchia verso l'alto), children (verso il basso), test cases e deployments collegati. Perfetto per avere una vista completa a 360°.

---

## Esplorare Gerarchia Work Items (Children)

Per visualizzare i figli (PBI, Feature, Task) di un Epic/Feature/PBI:

```powershell
# Via axctl (sintassi con --)
axctl --intent children -- 181579

# Oppure direttamente
pwsh Rules.Vault/scripts/ps/agent-ado-userstory.ps1 -Action 'ado:pbi.children' -Id 181579
```

**Output a schermo:**
```
========== Children of PBI #181579 ==========

181587  Feature             New            SID - Restricted List Process ( RIL )
184797  Product Backlog Item Done          SID - Input file - SBTI
...

=================================================
```

> [!TIP]
> Utile per navigare la struttura Epic → Feature → PBI → Task e comprendere lo scope di lavoro di un'iniziativa.

---

### Verificare Pipeline e Rilasci Collegati
Per vedere se un PBI/User Story è stato incluso in una build o release:

```powershell
axctl --intent pipeline 199756
# OPPURE
pwsh Rules.Vault/scripts/ps/agent-ado-userstory.ps1 -Action 'ado:pipeline.get-runs' -Id 199756
```

> [!NOTE]
> Mostra solo le pipeline esplicitamente collegate (Artifact Links, Integrated in Build).

---

## 7. Pipeline Generali (Nuovo)
Puoi esplorare le pipeline del progetto indipendentemente dai PBI.

### Listare Pipeline
Per vedere tutte le pipeline definitions (Builds):
```powershell
axctl --intent pipelines
```

### Storico Pipeline
Per vedere le ultime 10 esecuzioni di una specifica pipeline (serve l'ID ottenuto dalla lista):
```powershell
axctl --intent pipeline-history 123
```

---

## 8. Export Multitipo (All Types)
Se vuoi estrarre **qualsiasi** tipo di Work Item (Bug, Epic, Feature, Task, PBI, Story) in un'unica esecuzione, usa il tipo speciale `All` o `*`.

```powershell
# Esempio: Estrai tutto (Attenzione: usare filtri query per performance!)
axctl --intent ado-export --WorkItemType 'All' --Query "SELECT [System.Id], [System.WorkItemType], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.ChangedDate] > @today-7"
```

> [!WARNING]
> Usare `Type='All'` senza filtri temporali o di tag può scaricare l'intero backlog.
I #199756) ==========

Builds Found: 1
  Build #12345: ADA.CI [20260111.1] -> succeeded (Branch: refs/heads/main, Author: Mario Rossi)

Releases Found: 1
  Release #6789: ADA.CD [Release-123] (Created: 01/11/2026 10:00:00)
    - DEV: succeeded (Green)
    - UAT: succeeded (Green)
    - PROD: rejected (Red)

======================================================
```

> [!NOTE]
> L'action mostra solo le Build e Release **esplicitamente collegate** al Work Item (tramite Commit o Pull Request completata). Se il link manca in ADO, verrà mostrato "No linked builds/releases found".

---

## Convenzioni Output

### Timestamp Prefix
Tutti i file di export hanno prefisso timestamp:
```
yyyyMMddHHmmss_nomefile.json
yyyyMMddHHmmss_nomefile.csv
```
**Esempio**: `20260111215504_ado-export.csv`

### Delimitatore CSV
Il CSV usa **pipe (`|`)** come delimitatore (non virgola), per evitare conflitti con contenuti HTML.

---

## Note Importanti

1. **Macro `@project`**: Viene sostituita automaticamente col nome del progetto da `connections.json`
2. **Escape apici**: Usa `''` (doppio apice singolo) dentro le stringhe WIQL
3. **Work Item Type**: 
   - Scrum → `Product Backlog Item`
   - Agile → `User Story`
4. **Output JSON**: Struttura completa con tutti i campi, relazioni, link
5. **Auto-CSV**: Ogni export genera automaticamente anche il file CSV

---

## Troubleshooting

### Errore 404
- Verifica `connections.json`: il nome del progetto deve essere esatto (case-sensitive)
- Prova comando: `axctl --intent ado-check`

### 0 risultati
- Verifica tag: `[System.Tags]` è case-sensitive
- Controlla se il Work Item Type è corretto (PBI vs User Story)

### Timeout
- Aggiungi `TOP 100` alla query per limitare i risultati
