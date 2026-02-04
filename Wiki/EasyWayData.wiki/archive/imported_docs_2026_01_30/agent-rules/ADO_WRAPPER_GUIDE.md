---
id: ew-archive-imported-docs-2026-01-30-agent-rules-ado-wrapper-guide
title: 🎯 ADO Wrapper Scripts - Usage Guide
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
# 🎯 ADO Wrapper Scripts - Usage Guide

**Created**: 2026-01-13  
**Purpose**: Semplificare l'uso degli script ADO senza parametri espliciti

---

## 🚀 Universal Wrapper

**Un comando per tutti gli script ADO!**

### Usage

```powershell
pwsh Rules/scripts/ado.ps1 <command> [args]
```

### Commands Disponibili

| Command | Script Chiamato | Esempio |
|---------|-----------------|---------|
| `sprint`, `sprints` | get-ado-iterations.ps1 | `pwsh ado.ps1 sprint` |
| `test`, `tests` | get-ado-testplans.ps1 | `pwsh ado.ps1 test -ListPlans` |
| `pr`, `prs`, `pullrequest` | get-ado-pullrequests.ps1 | `pwsh ado.ps1 pr -Status active` |
| `export` | agent-ado-governance.ps1 | `pwsh agent-ado-governance.ps1 -Action ado:intent.resolve` |

---

## 📝 Examples

### Sprint/Iterations

```powershell
# Lista tutti gli sprint
pwsh Rules/scripts/ado.ps1 sprint

# Solo sprint attivo
pwsh Rules/scripts/ado.ps1 sprint -OnlyActive

# Include passati e futuri
pwsh Rules/scripts/ado.ps1 sprint -IncludePast -IncludeFuture
```

### Test Management

```powershell
# Lista test plans
pwsh Rules/scripts/ado.ps1 test -ListPlans

# Test runs ultimi 7 giorni
pwsh Rules/scripts/ado.ps1 test -ListRuns

# Test runs ultimi 30 giorni
pwsh Rules/scripts/ado.ps1 test -ListRuns -DaysBack 30
```

### Pull Requests

```powershell
# PR aperti
pwsh Rules/scripts/ado.ps1 pr -Status active

# PR completati
pwsh Rules/scripts/ado.ps1 pr -Status completed

# PR velocity
pwsh Rules/scripts/ado.ps1 pr -Status completed -CalculateVelocity

# PR con reviewers
pwsh Rules/scripts/ado.ps1 pr -Status active -IncludeReviewers
```

### Work Items Export

```powershell
# Export PBI
pwsh Rules/scripts/ado.ps1 export -WorkItemType "Product Backlog Item"

# Export con query custom
pwsh Rules/scripts/ado.ps1 export -Query "SELECT [System.Id], [System.Title] FROM WorkItems WHERE ..."
```

---

## ⚙️ Come Funziona

### 1. Config Loader (`ado-config.ps1`)

Carica automaticamente la configurazione:
- `Rules.Vault/config/connections.json` → Organization, Project, Team
- `Rules.Vault/config/secrets.json` → PAT
- Fallback a `$env:ADO_PAT` se secrets.json non ha il PAT

### 2. Universal Wrapper (`ado.ps1`)

- Carica config tramite `ado-config.ps1`
- Mappa il comando allo script corretto
- Passa automaticamente Organization, Project, PAT
- Forward tutti gli altri parametri allo script

### 3. Script Originali

Rimangono **invariati** - funzionano sia:
- ✅ Direttamente con parametri espliciti
- ✅ Tramite wrapper (auto-config)

---

## 🔧 Setup Required

**Nessun setup aggiuntivo!**

Se hai già configurato:
- ✅ `connections.json` con sezione `ado`
- ✅ `secrets.json` con `ado_pat`

Il wrapper **funziona subito**!

---

## 💡 Aliases (Opzionali)

Per rendere ancora più veloce, crea alias PowerShell:

```powershell
# Nel tuo $PROFILE (pwsh profile.ps1)
function ado { pwsh Rules/scripts/ado.ps1 @args }
function ado-sprint { pwsh Rules/scripts/ado.ps1 sprint @args }
function ado-pr { pwsh Rules/scripts/ado.ps1 pr @args }
function ado-test { pwsh Rules/scripts/ado.ps1 test @args }
```

Poi usa semplicemente:
```powershell
ado sprint
ado pr -Status active
ado test -ListPlans
```

---

## 🎯 Prima vs Dopo

### Prima (parametri espliciti)
```powershell
pwsh Rules/scripts/get-ado-iterations.ps1 `
  -Organization "GeneraliHeadOfficeIT" `
  -Project "ADA Project - Data Strategy" `
  -PAT "vZ9M88XgU..."
```

### Dopo (wrapper)
```powershell
pwsh Rules/scripts/ado.ps1 sprint
```

**Risparmio**: ~150 caratteri per comando! 🚀

---

## 🛠️ Troubleshooting

### Error: "Failed to load ADO configuration"

**Causa**: `connections.json` o `secrets.json` non trovati o malformati

**Fix**:
```powershell
# Verifica file esistono
Test-Path Rules.Vault/config/connections.json
Test-Path Rules.Vault/config/secrets.json

# Verifica contenuto
Get-Content Rules.Vault/config/connections.json | ConvertFrom-Json | Select ado
Get-Content Rules.Vault/config/secrets.json | ConvertFrom-Json | Select ado_pat
```

### Error: "Script not found"

**Causa**: Path scripting errato

**Fix**: Esegui sempre dalla **root del progetto** (dove c'è `Rules/`)

### Config non caricata

**Debug**:
```powershell
# Test config loader manualmente
. Rules/scripts/ado-config.ps1
$config = Get-AdoConfig
$config
```

---

## 📊 Vantaggi

| Feature | Valore |
|---------|--------|
| **Semplicità** | Un comando invece di 4+ parametri |
| **DRY** | Config centralizzata, no duplicazione |
| **Manutenibilità** | Update config in un posto solo |
| **Compatibilità** | Script originali funzionano ancora |
| **Sicurezza** | PAT da file o env var |

---

## 🔮 Future Enhancements

**Possibili**:
- Auto-completion per comandi
- Config profiles (dev, prod, staging)
- Logging centralizzato
- Rate limiting / retry logic

---

**Status**: ✅ Production Ready  
**Setup Time**: 0 min (se config già presente)  
**Risparmio**: ~150 chars per comando


