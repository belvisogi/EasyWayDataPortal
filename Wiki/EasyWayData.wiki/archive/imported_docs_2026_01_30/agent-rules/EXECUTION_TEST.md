---
id: ew-archive-imported-docs-2026-01-30-agent-rules-execution-test
title: 🎯 TEST: Workflow Operativo AI
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
---
# 🎯 TEST: Workflow Operativo AI

Questo test dimostra come l'AI dovrebbe comportarsi con le nuove EXECUTION_RULES.

---

## Scenario 1: "Mostra PBI 184797"

### ❌ Comportamento VECCHIO (da evitare):
```
AI: "Puoi visualizzare il PBI con questo comando:
axctl --intent pbi 184797"
```

### ✅ Comportamento NUOVO (desiderato):
```
AI: [ESEGUE: axctl --intent pbi 184797]
    
    ✅ Ecco il PBI #184797:
    
    ID: 184797
    Title: SID - Input file - SBTI
    State: Done
    Parent: #181587 (Feature)
    Children: 12 Test Cases
    ...
```

---

## Scenario 2: "Export PBI SID e mostra primi 10"

### ❌ Comportamento VECCHIO:
```
AI: "Prima esegui l'export:
axctl --intent ado-export --Query '...'

Poi stampa:
Import-Csv file.csv | Select-Object -First 10 | Format-Table"
```

### ✅ Comportamento NUOVO:
```
AI: [ESEGUE: export con -Print flag]
    
    ✅ Ho esportato 81 PBI con tag SID. Primi 20:
    
    ID     Type  State  Title
    181579 Epic  Active Dashboard...
    181586 PBI   New    AuM...
    ...
    
    Totale: 81 items
    Files: out/devops/20260112_ado-export.json + .csv
```

---

## Scenario 3: "Quali sono gli ultimi PBI esportati?"

### ❌ Comportamento VECCHIO:
```
AI: "Puoi usare show-last-export.ps1:
pwsh Rules/scripts/show-last-export.ps1"
```

### ✅ Comportamento NUOVO:
```
AI: [ESEGUE: show-last-export.ps1]
    
    🔍 Export: 20260112195212_ado-export.json
    📅 Data: 01/12/2026 19:52
    📊 Totale: 81 items
    
    ID     Type  State  Title
    181579 Epic  Active Dashboard...
    ...
```

---

## Scenario 4: "Crea nuovo PBI"

### ✅ Comportamento CORRETTO (chiede conferma):
```
AI: "Vuoi creare un nuovo PBI con:
     - Title: 'Test PBI'
     - Description: '...'
     - Tags: SID
     
     Confermi? (rispondo 'sì' per procedere)"

User: "sì"

AI: [ESEGUE: axctl --intent ado-userstory-create ...]
    
    ✅ PBI #185999 creato con successo!
```

---

## 📊 Metrics di Successo

| Scenario | Vecchio | Nuovo | Risparmio Passi |
|----------|---------|-------|-----------------|
| Vista PBI | 2 (suggerisci + user esegue) | 1 (auto-esegui) | 50% |
| Export + Print | 3 (suggerisci 2 comandi + user esegue) | 1 (auto-esegui) | 67% |
| Show Last | 2 | 1 | 50% |

**Target**: Riduzione 50%+ interazioni utente per task read-only.

---

## 🚀 Come Testare

1. **Apri nuova chat con AI**
2. **Carica context**:
   ```powershell
   pwsh Rules/scripts/ai-context-refresh.ps1 -Compact
   ```
3. **Test richieste**:
   - "Mostra PBI 184797"
   - "Export PBI SID e mostra primi 10"
   - "Quali sono gli ultimi PBI esportati?"

4. **Verifica**: AI esegue direttamente? ✅ = successo

---

**Versione Test**: 1.0
**Data**: 2026-01-12


