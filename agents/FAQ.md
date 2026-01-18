# ❓ Agent System - FAQ

> **Domande frequenti sul sistema agenti EasyWayDataPortal**

## 🎯 Generale

### Cos'è il sistema agenti?

Un'architettura di agenti autonomi che gestiscono task specifici (database, frontend, backend, governance) con issue tracking automatico e continuous improvement.

### Quanti agenti ci sono?

**10+ agenti attivi**, tra cui:
- agent_dba (database)
- agent_governance (governance)
- agent_audit (compliance)
- agent_frontend, agent_backend, agent_api
- agent_cartographer, agent_chronicler, agent_second_brain

### Come funziona l'issue tracking?

Quando un agente fallisce:
1. Logga automaticamente l'issue in `agents/logs/issues.jsonl`
2. L'issue appare nella Kanban board
3. `agent_governance` riceve notifica se critical/high
4. Propone un fix automaticamente
5. Human approva e implementa

---

## 🔧 Operazioni

### Come eseguo un'azione agentica?

```powershell
pwsh scripts/ewctl.ps1 -Intent "descrizione azione"
```

Esempio:
```powershell
pwsh scripts/ewctl.ps1 -Intent "create database user portal_reader"
```

### Come vedo gli issue aperti?

```powershell
pwsh scripts/pwsh/kanban-manager.ps1 -Action view
```

### Come loggo manualmente un issue?

```powershell
pwsh scripts/pwsh/issue-logger.ps1 `
  -Agent "agent_name" `
  -Severity "high" `
  -Category "execution_failed" `
  -Description "Descrizione problema"
```

### Come propongo un fix?

```powershell
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action propose-fix `
  -IssueId "ISSUE-YYYYMMDD-XXX" `
  -ProposedFix "Descrizione fix"
```

---

## 🐛 Troubleshooting

### "Agent not found"

**Causa**: Manifest mancante o KB non aggiornata

**Soluzione**:
```powershell
# Verifica manifest
cat agents/agent_<name>/manifest.json

# Verifica KB
cat agents/kb/recipes.jsonl | Select-String "agent_<name>"

# Audit
pwsh scripts/pwsh/agent-audit.ps1 -Mode all
```

### "Action failed silently"

**Causa**: Issue logging non integrato

**Soluzione**: Aggiungi try/catch con issue-logger.ps1 (vedi QUICK_START.md)

### "Kanban board vuota"

**Causa**: Nessun issue loggato o file corrotto

**Soluzione**:
```powershell
# Verifica file
cat agents/logs/kanban.json | ConvertFrom-Json

# Verifica issue log
cat agents/logs/issues.jsonl | Select-Object -Last 5
```

### "Permission denied su logs/"

**Causa**: Directory non esistente o permessi

**Soluzione**:
```powershell
# Crea directory
New-Item -ItemType Directory -Path "agents/logs" -Force

# Verifica permessi
Get-Acl agents/logs
```

### "Issue non appare in Kanban"

**Causa**: Severity troppo bassa o errore in issue-logger

**Soluzione**:
```powershell
# Verifica ultimo issue
cat agents/logs/issues.jsonl | Select-Object -Last 1 | ConvertFrom-Json

# Verifica kanban
cat agents/logs/kanban.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

---

## 🏗️ Sviluppo

### Come creo un nuovo agente?

1. Crea directory `agents/agent_<name>/`
2. Crea `manifest.json` (vedi standard)
3. Crea `README.md`
4. Implementa script in `scripts/pwsh/agent-<name>.ps1`
5. Aggiungi recipes in `agents/kb/recipes.jsonl`
6. Testa con `agent-audit.ps1`

**Template**:
```json
{
  "name": "agent_<name>",
  "description": "Descrizione agente",
  "version": "1.0.0",
  "allowed_paths": ["path1/", "path2/"],
  "actions": [
    {
      "name": "action:name",
      "description": "Descrizione azione",
      "script": "../../scripts/pwsh/agent-<name>.ps1",
      "params": {}
    }
  ]
}
```

### Come integro issue tracking in un agente esistente?

Vedi **Tutorial** in `QUICK_START.md`

### Come testo un agente?

```powershell
# Audit
pwsh scripts/pwsh/agent-audit.ps1 -Mode all

# Test azione
pwsh scripts/pwsh/agent-<name>.ps1 -Action "test" -IntentPath "test-intent.json"

# Verifica logs
cat agents/logs/issues.jsonl | Select-Object -Last 5
```

---

## 📊 Governance

### Quando viene eseguito agent_governance?

- **Automatico**: Quando issue critical/high viene loggato
- **Manuale**: `pwsh scripts/pwsh/agent-governance.ps1`
- **Schedulato**: Daily review (configurabile)

### Come funziona il propose-fix?

`agent_governance` analizza l'issue e genera una proposta che include:
- Diagnosi problema
- Soluzione proposta (codice)
- Impatto stimato
- Effort stimato
- Raccomandazione (APPROVE/REJECT)

### Posso modificare le regole di governance?

Sì, modifica `agents/agent_governance/priority.json` e `manifest.json`

---

## 🔐 Sicurezza

### Gli agenti hanno accesso illimitato?

No. Ogni agente ha `allowed_paths` nel manifest che limita l'accesso.

**Esempio**:
```json
{
  "allowed_paths": ["db/", "scripts/pwsh/agent-dba.ps1"]
}
```

### Come viene verificato l'accesso?

`scripts/enforcer.ps1` verifica `allowed_paths` prima dell'esecuzione.

```powershell
pwsh scripts/enforcer.ps1 -Agent agent_dba -GitDiff
# Exit code 2 se violazione
```

### Gli issue contengono dati sensibili?

Gli issue loggano solo metadati. **Non loggare**:
- Password
- Connection strings complete
- PII (Personal Identifiable Information)

**Best practice**: Usa `SuggestedFix` generico, non specifico.

---

## 📈 Metriche

### Come genero un report?

```powershell
# Report completo
pwsh scripts/pwsh/kanban-manager.ps1 -Action export

# Output: out/issues-report.md
```

### Quali metriche sono disponibili?

- Total issues
- Open issues
- Critical issues
- Issues by severity
- Issues by agent
- Issues by category
- Resolution time (manuale)

### Come identifico pattern di errori?

```powershell
# Group by category
cat agents/logs/issues.jsonl | ConvertFrom-Json | 
  Group-Object -Property category | 
  Sort-Object Count -Descending

# Group by agent
cat agents/logs/issues.jsonl | ConvertFrom-Json | 
  Group-Object -Property agent | 
  Sort-Object Count -Descending
```

---

## 🚀 Performance

### Il sistema scala con molti agenti?

Sì. Il sistema è progettato per scalare:
- Log JSONL (append-only, performante)
- Kanban JSON (piccolo, <100KB)
- Agenti indipendenti (no shared state)

### Quanto spazio occupano i log?

- `issues.jsonl`: ~1KB per issue
- `kanban.json`: ~10KB
- `events.jsonl`: ~500B per evento

**Stima**: 1000 issue = ~1MB

### Come archivio vecchi issue?

```powershell
# Filtra resolved > 30 giorni
$cutoff = (Get-Date).AddDays(-30)
cat agents/logs/issues.jsonl | ConvertFrom-Json | 
  Where-Object { 
    $_.status -eq 'resolved' -and 
    [DateTime]$_.metadata.updated_at -lt $cutoff 
  } | ConvertTo-Json -Compress | 
  Set-Content "agents/logs/archive/issues-$(Get-Date -Format 'yyyyMM').jsonl"
```

---

## 🔄 Integrazione

### Come integro con CI/CD?

```yaml
# Azure Pipelines example
- task: PowerShell@2
  displayName: 'Agent Audit'
  inputs:
    targetType: 'inline'
    script: |
      pwsh scripts/pwsh/agent-audit.ps1 -Mode all -FailOnError
      if ($LASTEXITCODE -ne 0) { exit 1 }

- task: PowerShell@2
  displayName: 'Check Critical Issues'
  inputs:
    targetType: 'inline'
    script: |
      $critical = cat agents/logs/issues.jsonl | ConvertFrom-Json | 
        Where-Object { $_.status -eq 'open' -and $_.severity -eq 'critical' }
      if ($critical.Count -gt 0) {
        Write-Error "Critical issues open: $($critical.Count)"
        exit 1
      }
```

### Come integro con Slack/Teams?

Aggiungi webhook in `issue-logger.ps1`:

```powershell
if ($Severity -in @('critical', 'high')) {
  $webhook = $env:SLACK_WEBHOOK_URL
  $payload = @{
    text = "🚨 $Severity issue: $Description"
    issue_id = $issueId
  } | ConvertTo-Json
  
  Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json'
}
```

---

## 📚 Risorse

### Dove trovo la documentazione completa?

- **Wiki**: `Wiki/EasyWayData.wiki/agents/`
  - `agent-system-architecture-overview.md`
  - `agent-issue-tracking-system.md`
- **Core**: `agents/core/ISSUE_TRACKING.md`
- **Quick Start**: `agents/QUICK_START.md`

### Ci sono esempi pratici?

Sì, vedi:
- `agents/core/ISSUE_TRACKING.md` - Workflow completi
- `Wiki/.../agent-issue-tracking-system.md` - Esempi dettagliati
- `scripts/pwsh/agent-dba.ps1` - Integrazione reale

### Come contribuisco?

1. Leggi `agent-architecture-standard.md`
2. Crea branch feature
3. Implementa agente/fix
4. Testa con `agent-audit.ps1`
5. Commit e PR

---

## 🆘 Support

**Non trovi risposta?**

1. Consulta `QUICK_START.md`
2. Verifica `agents/core/ISSUE_TRACKING.md`
3. Esegui `pwsh scripts/pwsh/kanban-manager.ps1 -Action view`
4. Logga un issue per team governance

**Contatti**:
- Team Governance: Via issue logging
- Documentazione: `Wiki/EasyWayData.wiki/agents/`

---

**Versione**: 1.0  
**Ultima modifica**: 2026-01-18  
**Status**: ✅ Active
