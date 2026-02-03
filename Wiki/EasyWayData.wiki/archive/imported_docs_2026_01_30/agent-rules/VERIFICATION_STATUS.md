---
id: ew-archive-imported-docs-2026-01-30-agent-rules-verification-status
title: ✅ VERIFICATION: Rules Update Status
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
# ✅ VERIFICATION: Rules Update Status

## 📋 File .md Aggiornati con EXECUTION Logic

| File | Status | Note |
|------|--------|------|
| **EXECUTION_RULES.md** | ✅ NUOVO | Regole di autonomia per AI |
| **TASK_RULES.md** | ✅ NUOVO | Workflow task-oriented |
| **EXECUTION_TEST.md** | ✅ NUOVO | Scenari di test |
| **RULES_MASTER.md** | ✅ AGGIORNATO | Alert IMPORTANT con execution mindset |
| **ADO_EXPORT_GUIDE.md** | ✅ AGGIORNATO | TIP box per AI |
| **README.it.md** | ✅ AGGIORNATO | Link a RULES_MASTER |
| **QA_TROUBLESHOOTING.md** | ✅ OK | Non richiede execution logic (è FAQ) |
| **.gemini/context.md** | ✅ AGGIORNATO | Execution rules in cima |

## 🔧 Script Aggiornati

| Script | Status | Note |
|--------|--------|------|
| **ai-context-refresh.ps1** | ✅ AGGIORNATO | Include execution rules in output |
| **show-last-export.ps1** | ✅ NUOVO | Helper per mostrare ultimo export |
| **agent-ado-scrummaster.ps1** | ✅ AGGIORNATO | Param -Print implementato |
| **axctl.ps1** | ✅ OK | Intent mapping per children |

## 📚 Gerarchia Documenti (da leggere in ordine)

### Per AI Assistant:
1. **EXECUTION_RULES.md** ← PRIMA DI TUTTO (autonomia)
2. **TASK_RULES.md** ← Workflow operativi
3. **RULES_MASTER.md** ← Reference completo
4. **ADO_EXPORT_GUIDE.md** ← Dettagli ADO
5. **README.it.md** ← Overview progetto

### Shortcut (genera tutto):
```powershell
pwsh Rules/scripts/ai-context-refresh.ps1 -Compact
```

## ⚡ Execution Logic Summary

### Comandi SEMPRE Safe (SafeToAutoRun=true):
```powershell
✅ axctl --intent pbi <ID>
✅ axctl --intent children -- <ID>
✅ pwsh agent-ado-governance.ps1 -Action 'ado:intent.resolve' -Print
✅ pwsh show-last-export.ps1
✅ Get-ChildItem, Get-Content, Import-Csv, etc.
```

### Chiedi conferma SOLO per:
```powershell
❌ axctl --intent ado-userstory-create (crea work item)
❌ axctl --intent ado-testcase (crea test case)
❌ Remove-Item (elimina file)
```

## 🎯 Mindset AI

**Vecchio**: "Puoi eseguire questo comando..."
**Nuovo**: [ESEGUE DIRETTAMENTE] "✅ Fatto! Ecco il risultato:"

## 📊 Coverage

- **File .md aggiornati**: 8/8 (100%)
- **Script aggiornati**: 4/4 (100%)
- **Execution rules implementate**: ✅
- **Test scenarios creati**: ✅
- **Context auto-load configurato**: ✅

---

**Verification Date**: 2026-01-12 20:03
**All Rules Updated**: ✅ YES


