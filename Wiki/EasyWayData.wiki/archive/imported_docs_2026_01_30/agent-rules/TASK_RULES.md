---
id: ew-archive-imported-docs-2026-01-30-agent-rules-task-rules
title: 🎯 AXET TASK-ORIENTED RULES
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
# 🎯 AXET TASK-ORIENTED RULES

> Queste regole guidano l'AI su COME eseguire task comuni in modo operativo.
> Da leggere SEMPRE prima di eseguire comandi Axet!

---

## ⚡ REGOLA #1: Export + Stampa = Usa `-Print`

**❌ NON FARE MAI**:
```powershell
# Step 1: Export
axctl --intent ado-export --Query "..."

# Step 2: Separate print command
Import-Csv ado-export.csv | Select-Object -First 10 | Format-Table
```

**✅ FARE SEMPRE**:
```powershell
# Un unico comando con -Print
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.Tags] CONTAINS 'SID'" \
  -Print
```

**Benefici**:
- ✅ Un solo comando invece di 2
- ✅ Output formattato automaticamente (ID, Type, State, Title, Tags, Priority)
- ✅ Mostra totale + path files
- ✅ Primi 20 items (non solo 10)

---

## ⚡ REGOLA #2: Visualizzare PBI = Usa `pbi` (non export)

**❌ NON FARE**:
```powershell
# Export solo per vedere dettagli
axctl --intent ado-export --Query "... WHERE [System.Id] = 184797"
```

**✅ FARE**:
```powershell
# Vista diretta 360°
axctl --intent pbi 184797
```

**Mostra**: Parent, Children, Test Cases, Deployments, Description

---

## ⚡ REGOLA #3: Task Comuni = Shortcut

### Task: "Mostra ultimi PBI esportati"
```powershell
# Trova ultimo export e mostra primi 20
$lastExport = Get-ChildItem out\devops\*_ado-export.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$json = Get-Content $lastExport.FullName -Raw | ConvertFrom-Json
$json | Select-Object -First 20 | ForEach-Object { 
  $f = $_.fields
  [PSCustomObject]@{
    ID = $f.'System.Id'
    Title = $f.'System.Title'.Substring(0, [Math]::Min(60, $f.'System.Title'.Length))
    State = $f.'System.State'
    Tags = $f.'System.Tags'
  }
} | Format-Table -AutoSize
```

**Crea alias** in `axctl.ps1`:
```powershell
axctl --intent show-last-export
```

### Task: "Lista PBI per Tag"
```powershell
# Sempre con -Print per preview
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.Tags] CONTAINS '<TAG>'" \
  -Print
```

### Task: "Analizza Epic completo"
```powershell
# Step 1: Vista Epic
axctl --intent pbi <EPIC_ID>

# Step 2: Se serve, vedi solo figli
axctl --intent children -- <EPIC_ID>
```

---

## ⚡ REGOLA #4: Output Leggibile

**Quando l'utente dice** "mostra", "stampa", "visualizza":
1. **Se export**: Usa `-Print` flag
2. **Se CSV esistente**: Usa colonne specifiche
3. **Se JSON**: Converti in tabella con campi chiave

**Colonne da Mostrare SEMPRE** (per PBI):
```powershell
System.Id, System.Title, System.State, System.Tags, Microsoft.VSTS.Common.Priority
```

**❌ MAI mostrare**:
- `_links.*` (URL ADO interne)
- `*.id` (UUID utenti)
- Campi HTML grezzi

---

## ⚡ REGOLA #5: Comandi Compositi

**Scenario**: "Export SID e mostra top 10 Done"

**✅ Approccio Corretto**:
```powershell
# Export con -Print (mostra già 20)
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.Tags] CONTAINS 'SID' AND [System.State] = 'Done'" \
  -Print

# Se serve filtraggio post-export:
$json = Get-Content (Get-ChildItem out\devops\*_ado-export.json -Recurse | Sort-Object LastWriteTime -Desc | Select -First 1).FullName -Raw | ConvertFrom-Json
$json | Where-Object { $_.fields.'System.State' -eq 'Done' } | Select-Object -First 10 | ...
```

---

## 📋 DECISION TREE per AI

```
User chiede: "Mostra/Stampa PBI"
├─ È un ID specifico? 
│  └─ YES → axctl --intent pbi <ID>
│  └─ NO  → Continua ↓
│
├─ È una query/tag/filtro?
│  └─ YES → Export con -Print
│  └─ NO  → Chiedi chiarimenti
│
└─ Vuole vedere export esistente?
   └─ YES → Trova ultimo export e formatta tabella
```

---

## 🎨 TEMPLATES OPERATIVI

### Template 1: Export Tag
```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.Tags] CONTAINS '<TAG>'" \
  -Print
```

### Template 2: Export Recent (7 giorni)
```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.ChangedDate] > @today-7" \
  -Print
```

### Template 3: Show Last Export
```powershell
$lastJson = (Get-ChildItem out\devops\*_ado-export.json | Sort LastWriteTime -Desc)[0]
(Get-Content $lastJson -Raw | ConvertFrom-Json) | Select-Object -First 20 | ForEach-Object { 
  [PSCustomObject]@{
    ID = $_.fields.'System.Id'
    Title = $_.fields.'System.Title'.Substring(0, [Math]::Min(50, $_.fields.'System.Title'.Length))
    State = $_.fields.'System.State'
    Tags = $_.fields.'System.Tags'
  }
} | Format-Table -AutoSize
```

---

## 🚀 QUICK WINS

1. **Sempre usare `-Print`** quando user dice "mostra" + export
2. **Preferire `pbi`** per singoli work items (non export)
3. **Colonne standard**: ID, Title (max 50-60 char), State, Tags, Priority
4. **Mai mostrare** link interni o UUID
5. **Totale sempre visibile** (es: "Total: 81 items")

---

## 📝 ESEMPI PRIMA/DOPO

### Esempio 1: Export + Stampa
**❌ Prima (2 comandi)**:
```powershell
axctl --intent ado-export --Query "..."
Import-Csv out/devops/file.csv -Delimiter '|' | Select -First 10 | Format-Table
```

**✅ Dopo (1 comando)**:
```powershell
pwsh Rules.Vault/scripts/ps/agent-ado-scrummaster.ps1 -Action 'ado:userstory.export' -Query "..." -Print
```

### Esempio 2: Vista PBI
**❌ Prima**:
```powershell
axctl --intent ado-export --Query "... WHERE [System.Id] = 184797"
```

**✅ Dopo**:
```powershell
axctl --intent pbi 184797
```

---

**Versione**: 3.1 (Task-Oriented)
**Data**: 2026-01-12


