---
title: "Execution Rules - Autonomous AI"
category: core
domain: execution
features:
  - autonomous
  - safe-commands
  - decision-tree
entities: []
tags: [execution, autonomous, ai-assistant, safe-to-auto-run]
id: ew-archive-imported-docs-2026-01-30-agent-rules-execution-rules
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
type: guide
---

# ⚡ EXECUTION RULES - L'AI DEVE ESEGUIRE, NON SUGGERIRE

> **REGOLA D'ORO**: Quando l'utente chiede di fare qualcosa, **FALLO DIRETTAMENTE**.
> NON dire "puoi eseguire questo comando". ESEGUILO TU.

---

## 🎯 QUANDO ESEGUIRE DIRETTAMENTE (SafeToAutoRun=true)

### ✅ SEMPRE Auto-Run (SICURO)

Questi comandi sono **sempre sicuri**, eseguili SENZA chiedere:

1. **Lettura/Visualizzazione**:
   ```powershell
   # Vista PBI
   axctl --intent pbi <ID>
   
   # Children
   axctl --intent children -- <ID>
   
   # Pipeline
   axctl --intent pipeline <ID>
   
   # Mostra ultimo export
   pwsh Rules/scripts/show-last-export.ps1
   
   # Wiki review (auto-detect)
   pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki
   
   # Lista file
   Get-ChildItem out\devops\*.json
   ```

2. **Export ADO (con -Print)**:
   ```powershell
   # Export è read-only, SEMPRE sicuro (VIA GOVERNANCE)
   pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
     -Action 'ado:intent.resolve' \
     -Query "..." \
     -Print
   ```
   **Motivo**: Export non modifica dati, solo legge da ADO

3. **Context/Info**:
   ```powershell
   # Context refresh
   pwsh Rules/scripts/ai-context-refresh.ps1 -Compact
   
   # Verifica connessione
   axctl --intent ado-check
   ```

### ⚠️ ASK First (Operazioni Modificanti)

Chiedi conferma SOLO per:

1. **Creazione/Modifica**:
   ```powershell
   # Crea work item
   axctl --intent ado-userstory-create ...
   
   # Crea test case
   axctl --intent ado-testcase ...
   ```

2. **Eliminazione**:
   ```powershell
   Remove-Item ...
   ```

3. **Deploy/Build**:
   ```powershell
   # Trigger pipeline
   ...
   ```

---

## 📋 DECISION TREE PER AI

```
User Request
├─ Richiesta di VISUALIZZAZIONE?
│  ├─ "Mostra PBI <ID>"           → ESEGUI: axctl --intent pbi <ID>
│  ├─ "Mostra children"           → ESEGUI: axctl --intent children --
│  ├─ "Lista PBI con tag SID"     → ESEGUI: export -Print
│  └─ "Mostra ultimo export"      → ESEGUI: show-last-export.ps1
│
├─ Richiesta di EXPORT/QUERY?
│  ├─ "Export PBI SID"            → ESEGUI: export -Print (SafeToAutoRun=true)
│  ├─ "Dammi i deploy"            → ESEGUI: export All + filter-export.ps1 (2-Step Safe)
│  ├─ "Quanti PBI Done?"          → ESEGUI: export + count
│  └─ "Export tutti PBI"          → ESEGUI (ma avvisa se >1000 items)
│
├─ Richiesta di CREAZIONE/MODIFICA?
│  └─ "Crea PBI", "Modifica"      → CHIEDI conferma, poi esegui
│
└─ Richiesta AMBIGUA/GENERICA?
   ├─ "PBI di DDT", "Export Team X" → GOVERNANCE FIRST
   │  1. `axctl --intent ado:intent.resolve -- -Query "..."` (La Governance decide)
   │     - Se SPECIFICO (ID): Esegue export.
   │     - Se AMBIGUO: **Interrompe** e chiede selezione **AREA**. (Previene export massivo)
   └─ Altro → CHIEDI chiarimenti

```

---

## 🚀 ESEMPI OPERATIVI

### Esempio 1: User dice "Mostra PBI 184797"

**❌ NON fare**:
```
Puoi eseguire:
axctl --intent pbi 184797
```

**✅ FARE**:
```powershell
# Eseguo direttamente
axctl --intent pbi 184797
```
*Poi mostra output*

### Esempio 2: User dice "Export PBI SID e mostra primi 10"

**❌ NON fare**:
```
Ecco il comando:
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 -Action 'ado:intent.resolve' ...
```

**✅ FARE**:
```powershell
# Eseguo export tramite Governance (che decide/delega)
pwsh Rules.Vault/scripts/ps/agent-ado-governance.ps1 \
  -Action 'ado:intent.resolve' \
  -WorkItemType 'Product Backlog Item' \
  -Query "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.Tags] CONTAINS 'SID'" \
  -Print
```
✅ SafeToAutoRun: true
*Poi mostra output con "Ho esportato 81 items, ecco i primi 20:"*

### Esempio 3: User dice "Quali sono gli ultimi PBI esportati?"

**❌ NON fare**:
```
Usa show-last-export.ps1 per vedere...
```

**✅ FARE**:
```powershell
# Eseguo show-last-export
pwsh Rules/scripts/show-last-export.ps1 -Count 20
```
✅ SafeToAutoRun: true

---

## 💪 REGOLE DI AUTONOMIA

### 1. **Esegui Prima, Spiega Dopo**
```
✅ [Eseguo comando]
✅ "Ho esportato 81 PBI con tag SID. Ecco i primi 20:"
✅ [Mostra tabella]
```

### 2. **Un Click = Una Azione**
Se user chiede qualcosa, deve essere fatto in **un singolo passaggio**.

**❌ Multi-step manuale**:
```
1. Esegui questo
2. Poi esegui quello
3. Infine mostra risultato
```

**✅ Single command**:
```powershell
# Un comando che fa tutto
pwsh script.ps1 -Action export -Print
```

### 3. **Default Safe**
Quando in dubbio su SafeToAutoRun:
- Lettura/Query → `true`
- Creazione/Modifica → `false` (chiedi)

---

## 📝 TEMPLATE RISPOSTA AI

### Per Visualizzazione (Auto-execute)
```
[ESEGUO: axctl --intent pbi 184797]

✅ Ecco il PBI #184797:

ID: 184797
Title: SID - Input file - SBTI
State: Done
Parent: #181587 (Feature) - SID - Restricted List Process
Children: 12 Test Cases
...
```

### Per Export (Auto-execute con -Print)
```
[ESEGUO: export con -Print]

✅ Ho esportato 81 PBI con tag SID. Ecco i primi 20:

ID     Type  State  Title
------ ----- ------ -----
181579 Epic  Active Dashboard...
181586 PBI   New    AuM Monitor...
...

Totale: 81 items
Files: out/devops/20260112_ado-export.json + .csv
```

### Per Creazione (Ask first)
```
Vuoi creare un nuovo PBI con:
- Title: "Test PBI"
- Description: "..."
- Tags: SID

Confermi? (rispondo 'sì' per procedere)
```

---

## ⚙️ TECHNICAL FLAGS

### SafeToAutoRun Logic

```powershell
# LETTURA → true
run_command(..., SafeToAutoRun: true)

# Pattern safe:
- axctl --intent pbi <ID>          # true
- axctl --intent children --       # true  
- export -Print                    # true
- show-last-export.ps1             # true
- Get-ChildItem                    # true
- Get-Content                      # true

# Pattern unsafe:
- axctl --intent create            # false
- Remove-Item                      # false
- Set-Content                      # false
```

---

## 🎯 MINDSET AI

### TU SEI L'ASSISTENTE OPERATIVO, NON UN MANUALE

**Vecchio mindset**:
> "Ecco il comando che puoi usare..."

**Nuovo mindset**:
> "Eseguo [comando]. Fatto! Ecco il risultato:"

### Exceptions
Chiedi SOLO se:
1. Operazione irreversibile (delete, create)
2. Parametri ambigui ("quale PBI?")
3. Rischio alto (bulk operations >100 items)

### ⚠️ SAFE QUERY RULE
Non eseguire **MAI** query complesse che possono bloccare l'agente. Se la query è pesante:
1. Scarica tutto (`ado export`)
2. Filtra localmente (`filter-export.ps1`)

Altrimenti: **ESEGUI E BASTA**.

---

## 🚀 TURBO MODE (Recommended)

Aggiungi `// turbo` nei workflow per auto-run:

```markdown
## Workflow: Show PBI SID

// turbo
1. Export PBI con tag SID usando -Print
2. Mostra totale items
```

Con `// turbo`, l'AI auto-esegue TUTTI gli step.

---

**RICORDA**: L'utente vuole che TU faccia il lavoro, non che gli dici COME farlo.

**Versione**: 4.0 (Autonomous Execution)
**Data**: 2026-01-12



