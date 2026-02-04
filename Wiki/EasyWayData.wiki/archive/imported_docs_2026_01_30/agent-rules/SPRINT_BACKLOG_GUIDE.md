---
id: ew-archive-imported-docs-2026-01-30-agent-rules-sprint-backlog-guide
title: 🏃 Sprint & Backlog Queries - Guide
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
# 🏃 Sprint & Backlog Queries - Guide

**Created**: 2026-01-13  
**Purpose**: Query Azure DevOps Iterations/Sprints and Backlog items  
**New Capability**: ADO REST API Iterations support ✨

---

## 🎯 Problema Risolto

**Prima**: Non potevamo ottenere lista sprint/iterations da ADO  
**Adesso**: Script `get-ado-iterations.ps1` interroga ADO REST API!

---

## 📋 Nuove Funzionalità

### 1. Lista Sprint/Iterations

**Command**:
```powershell
pwsh Rules/scripts/get-ado-iterations.ps1
```

**Output**:
```
Name           Status  Start       Finish      Path
Sprint 1       Past    2025-01-01  2025-01-14  Project\Sprint 1
Sprint 2       Active  2025-01-15  2025-01-28  Project\Sprint 2
Sprint 3       Future  2025-01-29  2025-02-11  Project\Sprint 3
```

---

### 2. Solo Sprint Attivo

**Command**:
```powershell
pwsh Rules/scripts/get-ado-iterations.ps1 -OnlyActive
```

**Use Case**: Quale sprint è attivo ora?

---

### 3. Backlog Sprint Corrente

**Approach**:
1. Get sprint attivo
2. Query PBI con IterationPath dello sprint

**Command**:
```powershell
# Step 1: Get active sprint name
$sprint = pwsh Rules/scripts/get-ado-iterations.ps1 -OnlyActive

# Step 2: Export PBI del sprint
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 `
  -Action 'ado:intent.resolve' `
  -Query "SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo]
          FROM WorkItems  
          WHERE [System.IterationPath] = 'YourProject\Sprint 2'
            AND [System.TeamProject] = @project"
```

---

### 4. Storico Sprint

**Command**:
```powershell
pwsh Rules/scripts/get-ado-iterations.ps1 -IncludePast
```

**Use Case**: Vedere tutti gli sprint completati con date

---

### 5. Sprint Futuri

**Command**:
```powershell
pwsh Rules/scripts/get-ado-iterations.ps1 -IncludeFuture
```

**Use Case**: Planning sprint futuri

---

### 6. Backlog Completo

**WIQL Query**:
```sql
SELECT [System.Id], [System.Title], [System.State], [System.IterationPath]
FROM WorkItems
WHERE [System.TeamProject] = @project
  AND [System.State] NOT IN ('Done', 'Removed', 'Closed')
  AND [System.IterationPath] = ''  -- Items not assigned to sprint
```

**Command**:
```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 `
  -Action 'ado:intent.resolve' `
  -Query "SELECT [System.Id], [System.Title], [System.State]
          FROM WorkItems
          WHERE [System.State] <> 'Done'"
```

---

### 7. Velocity Analysis

**Concept**: Story points/effort completed per sprint

**Steps**:
1. Export PBI per sprint (IterationPath)
2. Filtra State='Done'
3. Somma Effort/Story Points

**Example**:
```powershell
# Export sprint items
pwsh agent-ado-scrummaster.ps1 -Query "
  SELECT [System.Id], [System.Title], [Microsoft.VSTS.Scheduling.Effort]
  FROM WorkItems
  WHERE [System.IterationPath] = 'Project\Sprint 2'
    AND [System.State] = 'Done'
"

# Calculate velocity (manual or script)
$items = Get-Content out/devops/*_ado-export.json | ConvertFrom-Json
$velocity = ($items | Measure-Object -Property 'fields.Microsoft.VSTS.Scheduling.Effort' -Sum).Sum
Write-Host "Sprint 2 Velocity: $velocity points"
```

---

## 🔧 Script Parameters

### get-ado-iterations.ps1

```powershell
-Organization <string>  # ADO org (auto from config)
-Project <string>       # Project name (auto from config)
-Team <string>          # Team name (optional)
-PAT <string>           # Personal Access Token (auto from secrets)
-OnlyActive             # Filter: only active sprint
-IncludePast            # Include past sprints
-IncludeFuture          # Include future sprints
```

**Auto-Config**: Se non specifichi parametri, legge da:
- `Rules.Vault/config/connections.json`
- `Rules.Vault/config/secrets.json`

---

## 📊 Ricette Disponibili (8)

| Trigger | Intent | Descrizione |
|---------|--------|-------------|
| `lista sprint` | ado:sprint.list | Tutte le iterations |
| `sprint attivo` | ado:sprint.current | Solo sprint corrente |
| `backlog sprint` | ado:sprint.backlog | Backlog sprint attivo |
| `pbi dello sprint` | ado:sprint.items | PBI per sprint specifico |
| `storico sprint` | ado:sprint.history | Sprint passati |
| `sprint futuri` | ado:sprint.future | Sprint pianificati |
| `tutto il backlog` | ado:backlog.all | Backlog completo |
| `velocity sprint` | ado:sprint.velocity | Analisi velocity |

---

## 💡 Esempi d'Uso

### Scenario 1: Planning Meeting
```
User: "lista sprint"
AI: Mostra tutti sprint (past, active, future) con date
```

### Scenario 2: Daily Standup
```
User: "sprint attivo"
AI: Mostra lo sprint corrente + date

User: "backlog sprint"
AI: Export PBI dello sprint attivo
```

### Scenario 3: Retrospective
```
User: "storico sprint"
AI: Mostra tutti sprint passati

User: "velocity sprint"
AI: Calcola points completati per sprint
```

---

## 🔐 Authentication

Script usa:
1. **PAT** da `secrets.json` (preferred)
2. **Environment variable** `$env:ADO_PAT`
3. **Parameter** `-PAT` (manual override)

**Setup**:
```json
// Rules.Vault/config/connections.json
{
  "ado": {
    "organization": "YourOrg",
    "project": "YourProject",
    "team": "YourTeam"
  }
}

// Rules.Vault/config/secrets.json
{
  "ado_pat": "your-pat-here"
}
```

---

## 🎯 Integration con Existing Tools

### Con filter-export.ps1
```powershell
# Get sprint items -> filter by state
pwsh get-ado-iterations.ps1 -OnlyActive
# ... export items for sprint ...
pwsh filter-export.ps1 -Latest -State "Active"
```

### Con Deploy Recipes
```powershell
# Deploy items in specific sprint
Export deploy items + filter IterationPath = "Sprint X"
```

---

## ✅ Vantaggi

**Prima (limitations)**:
- ❌ Non potevo vedere lista sprint
- ❌ Manual lookup in ADO UI
- ❌ No automation

**Adesso**:
- ✅ Lista completa sprint via API
- ✅ Filtro active/past/future
- ✅ Export JSON per automation
- ✅ Integration con recipes
- ✅ Velocity tracking ready

---

## 📝 Output Format

**Console**:
```
📊 Iterations Found: 5

Name       Status  Start       Finish      Path
Sprint 1   Past    2025-01-01  2025-01-14  Project\Sprint 1
Sprint 2   Active  2025-01-15  2025-01-28  Project\Sprint 2
...

📈 Summary:
  Active: 1
  Past: 2
  Future: 2

💾 Exported to: out/devops/iterations_20260113062500.json
```

**JSON Export**:
```json
[
  {
    "Id": "abc123",
    "Name": "Sprint 2",
    "Path": "Project\\Sprint 2",
    "StartDate": "2025-01-15T00:00:00Z",
    "FinishDate": "2025-01-28T00:00:00Z",
    "Status": "Active",
    "TimeFrame": "current"
  }
]
```

---

## 🔮 Future Enhancements

**Possibili**:
- Sprint capacity planning
- Burndown chart data
- Sprint comparison analytics
- Auto-backlog prioritization

---

**Status**: ✅ Production Ready  
**API**: ADO REST API v7.0  
**Dependencies**: PowerShell 7+, ADO PAT


