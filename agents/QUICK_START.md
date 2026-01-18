# 🚀 Agent System - Quick Start Guide

> **5 minuti per iniziare con il sistema agenti EasyWayDataPortal**

## 📖 Panoramica Rapida

Il sistema agenti è composto da:
- **10+ agenti specializzati** (dba, governance, audit, frontend, backend...)
- **Issue Tracking automatico** con Kanban board
- **Governance proattiva** che propone fix automaticamente
- **Continuous improvement loop** basato su pattern di errori

**Score attuale**: 9.3/10 ⭐⭐

---

## ⚡ Quick Start (3 comandi)

### 1. Verifica sistema agenti

```powershell
# Audit completo
pwsh scripts/pwsh/agent-audit.ps1 -Mode all
```

**Output atteso**: ✅ tutti gli agenti compliant

### 2. Visualizza Kanban board

```powershell
# Vedi issue aperti
pwsh scripts/pwsh/kanban-manager.ps1 -Action view
```

### 3. Esegui governance review

```powershell
# Review automatica
pwsh scripts/pwsh/agent-governance.ps1 -Interactive:$false
```

---

## 🎯 Comandi Essenziali

| Comando | Cosa fa |
|---------|---------|
| `pwsh scripts/ewctl.ps1 -Intent "..."` | Esegue un'azione agentica |
| `pwsh scripts/pwsh/issue-logger.ps1 -Agent ... -Severity ...` | Logga un issue |
| `pwsh scripts/pwsh/kanban-manager.ps1 -Action view` | Visualizza Kanban |
| `pwsh scripts/pwsh/kanban-manager.ps1 -Action export` | Genera report |
| `pwsh scripts/pwsh/agent-audit.ps1 -Mode all` | Audit completo |
| `pwsh scripts/pwsh/agent-governance.ps1` | Review governance |

---

## 📁 Struttura Directory

```
agents/
├── agent_dba/              # Database operations
├── agent_governance/       # System governance
├── agent_audit/            # Compliance audit
├── agent_frontend/         # Frontend tasks
├── agent_backend/          # Backend tasks
├── core/
│   ├── schemas/            # JSON schemas
│   │   └── issue-log.schema.json
│   └── ISSUE_TRACKING.md   # Documentazione issue tracking
├── kb/
│   └── recipes.jsonl       # Intent → Agent mapping
└── logs/
    ├── issues.jsonl        # Issue log
    ├── kanban.json         # Kanban state
    └── events.jsonl        # Event log
```

---

## 🔧 Primi Passi

### Scenario 1: Eseguire un'azione agentica

```powershell
# Esempio: Creare un database user
pwsh scripts/ewctl.ps1 -Intent "create database user portal_reader with read permissions"
```

### Scenario 2: Loggare un issue (da agente)

```powershell
# Esempio: Directory mancante
pwsh scripts/pwsh/issue-logger.ps1 `
  -Agent "agent_dba" `
  -Severity "high" `
  -Category "missing_dependency" `
  -Description "db/migrations/ directory not found" `
  -SuggestedFix "Create directory with README"
```

### Scenario 3: Proporre un fix (governance)

```powershell
# Proponi fix per issue specifico
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action propose-fix `
  -IssueId "ISSUE-20260118-001" `
  -ProposedFix "Add pre-check to manifest..."
```

---

## 📚 Documentazione Completa

### Wiki Pages

- **[Agent System Architecture Overview](../Wiki/EasyWayData.wiki/agents/agent-system-architecture-overview.md)** - Panoramica completa
- **[Agent Issue Tracking System](../Wiki/EasyWayData.wiki/agents/agent-issue-tracking-system.md)** - Sistema issue tracking
- **[Agent Architecture Standard](../Wiki/EasyWayData.wiki/standards/agent-architecture-standard.md)** - Standard architetturale
- **[Agents Governance](../Wiki/EasyWayData.wiki/agents-governance.md)** - Governance workflow

### Core Files

- `agents/core/ISSUE_TRACKING.md` - Documentazione issue tracking
- `agents/kb/recipes.jsonl` - Knowledge base
- `scripts/pwsh/issue-logger.ps1` - Issue logger
- `scripts/pwsh/kanban-manager.ps1` - Kanban manager
- `scripts/pwsh/agent-governance.ps1` - Governance script

---

## 🎓 Tutorial: Integrare Issue Tracking in un Agente

### Step 1: Aggiungi global try/catch

```powershell
# In scripts/pwsh/agent-<name>.ps1

try {
  switch ($Action) {
    'action-name' {
      # ... logica azione
    }
  }
} catch {
  $err = $_
  if (Test-Path "scripts/pwsh/issue-logger.ps1") {
    pwsh "scripts/pwsh/issue-logger.ps1" `
      -Agent "agent_<name>" `
      -Severity "high" `
      -Category "execution_failed" `
      -Description "Action '$Action' failed: $($err.Exception.Message)" `
      -ErrorMessage $err.Exception.Message
  }
  throw $err
}
```

### Step 2: Aggiungi logging specifico

```powershell
# In catch block di azioni specifiche

catch {
  $errorMsg = $_.Exception.Message
  
  if (Test-Path "scripts/pwsh/issue-logger.ps1") {
    pwsh "scripts/pwsh/issue-logger.ps1" `
      -Agent "agent_<name>" `
      -Severity "high" `
      -Category "execution_failed" `
      -Description "Failed to execute: $errorMsg" `
      -ErrorMessage $errorMsg `
      -Intent $Action
  }
}
```

### Step 3: Testa

```powershell
# Forza un errore
pwsh scripts/pwsh/agent-<name>.ps1 -Action "test" -IntentPath "invalid.json"

# Verifica issue loggato
cat agents/logs/issues.jsonl | Select-Object -Last 1 | ConvertFrom-Json

# Verifica Kanban
pwsh scripts/pwsh/kanban-manager.ps1 -Action view
```

---

## 🐛 Troubleshooting Rapido

### Issue: "Agent not found"

```powershell
# Verifica manifest
cat agents/agent_<name>/manifest.json

# Verifica KB
cat agents/kb/recipes.jsonl | Select-String "agent_<name>"
```

### Issue: "Action failed"

```powershell
# Check logs
cat agents/logs/issues.jsonl | Select-Object -Last 5

# Check kanban
pwsh scripts/pwsh/kanban-manager.ps1 -Action view
```

### Issue: "Kanban not updating"

```powershell
# Verifica permessi
Test-Path agents/logs/kanban.json

# Verifica formato
cat agents/logs/kanban.json | ConvertFrom-Json
```

---

## 📊 Metriche di Successo

**Obiettivi Q1 2026:**

| Metrica | Target | Attuale | Status |
|---------|--------|---------|--------|
| Agent Compliance | 100% | 95% | 🟡 |
| Issue Resolution Time | <24h | 18h | ✅ |
| Governance Coverage | 100% | 100% | ✅ |
| KB Accuracy | >90% | 92% | ✅ |
| Auto-Fix Rate | >50% | 35% | 🟡 |
| Zero Critical Untracked | 100% | 100% | ✅ |

---

## 🚦 Next Steps

1. ✅ **Familiarizza** - Leggi questa guida
2. ✅ **Esplora** - Esegui i 3 comandi quick start
3. ✅ **Integra** - Aggiungi issue tracking a un agente
4. ✅ **Monitora** - Controlla Kanban giornalmente
5. ✅ **Migliora** - Proponi fix per issue ricorrenti

---

## 📞 Support

- **Documentazione**: [Wiki/agents/](../Wiki/EasyWayData.wiki/agents/)
- **Issue Tracking**: `agents/core/ISSUE_TRACKING.md`
- **Kanban Board**: `pwsh scripts/pwsh/kanban-manager.ps1 -Action view`
- **Team Governance**: Contatta via issue logging

---

**Versione**: 1.0  
**Ultima modifica**: 2026-01-18  
**Status**: ✅ Ready to Use
