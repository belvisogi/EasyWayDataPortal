---
title: "Secrets Management — Agent Platform"
created: 2026-02-19
updated: 2026-02-19
status: active
category: security
domain: platform
tags: [secrets, environment, bootstrap, security, best-practice, antifragile]
priority: high
audience: [platform-engineers, agent-developers]
---

# Secrets Management — Agent Platform

## Indice

1. [Il Problema: contesti di esecuzione multipli](#1-il-problema)
2. [La Soluzione: Import-AgentSecrets (SSOT + Lazy Loading)](#2-la-soluzione)
3. [Architettura](#3-architettura)
4. [Cosa: file e secrets gestiti](#4-cosa)
5. [Come: integrazione nei runner](#5-come)
6. [Perché queste scelte progettuali](#6-perché)
7. [Runbook operativo](#7-runbook-operativo)
8. [Aggiungere un nuovo secret](#8-aggiungere-un-nuovo-secret)
9. [Troubleshooting](#9-troubleshooting)
10. [Decisioni di design (ADR)](#10-decisioni-di-design)

---

## 1. Il Problema

Gli agenti del platform girano in **tre contesti di esecuzione distinti**, ognuno con una gestione dei secrets diversa:

| Contesto | Come arrivano i secrets | Problema pre-Session 14 |
|----------|------------------------|-------------------------|
| **Container `easyway-runner`** | Docker env vars iniettate al boot | Funziona sempre |
| **Shell SSH diretta** | Solo se l'utente esegue `export VAR=...` | Fragile, dimenticabile |
| **CI/CD pipeline** | Variabili di pipeline (Azure DevOps) | Funziona, ma isolato |

Il sintomo che ha evidenziato il problema: in Session 13, il test E2E di `security:analyze` produceva `rag_chunks=0` con warning **"401 Unauthorized"** da Qdrant. Il flusso era:

```
Invoke-AgentSecurity.ps1
  └─ Invoke-LLMWithRAG.ps1
       └─ Invoke-RAGSearch.ps1
            └─ python3 rag_search.py   ← legge os.getenv("QDRANT_API_KEY") → None → 401
```

La causa radice: `QDRANT_API_KEY` era l'unico secret **non** in `/opt/easyway/.env.secrets` e non veniva esportata nella shell SSH prima della chiamata.

### Perché la prima fix era sbagliata

La prima proposta (PR #74) aggiungeva un parametro `-QdrantApiKey` a `Invoke-LLMWithRAG` e `Invoke-AgentSecurity`. Era:

- **Non antifragile**: richiedeva azione esplicita dell'utente (`-QdrantApiKey "..."`)
- **Incompleta**: non risolveva `agent_review` e `agent_infra` (non aggiornati)
- **Dispersiva**: la responsabilità del secret era distribuita tra caller e skill
- **Non scalabile**: ogni nuovo secret avrebbe richiesto nuovi parametri

---

## 2. La Soluzione

**Principio**: *Single Source of Truth + Lazy Loading non-distruttivo*

```
/opt/easyway/.env.secrets          ← SSOT: tutti i platform secrets
        │
        ▼
Import-AgentSecrets.ps1            ← skill utilities, chiamata al boot da ogni runner
        │
        ├─ Se env var già presente  → skip (no-op: container, CI/CD invariati)
        └─ Se env var assente       → setta $env:KEY da file → tutti i caller funzionano
```

### Proprietà della soluzione

| Proprietà | Descrizione |
|-----------|-------------|
| **Idempotente** | Chiamata N volte, risultato identico |
| **Non-distruttiva** | Non sovrascrive mai env vars già presenti |
| **Fail-safe** | Se il file non esiste, ritorna silenziosamente (container: env già set) |
| **Audit-safe** | Valori dei secrets mai loggati, solo i nomi delle chiavi |
| **Portabile** | Linux (`/opt/easyway/.env.secrets`), Windows (`$USERPROFILE\.easyway\secrets`) |
| **Zero-overhead** | Nel container il file non esiste o le var sono già set: exit immediato |

---

## 3. Architettura

```
agents/skills/utilities/
└── Import-AgentSecrets.ps1      ← NEW skill (Session 14)

/opt/easyway/
└── .env.secrets                 ← SSOT (server-side, mai committato)
    ├── DEEPSEEK_API_KEY=...
    ├── GITEA_API_TOKEN=...
    └── QDRANT_API_KEY=...       ← aggiunto Session 14

Agent runners (caller di Import-AgentSecrets):
├── agents/agent_security/Invoke-AgentSecurity.ps1
├── agents/agent_review/Invoke-AgentReview.ps1
└── scripts/pwsh/agent-infra.ps1
```

### Flusso di esecuzione

```
[1] Runner starts
    │
[2] Import-AgentSecrets called
    ├── File exists?
    │   ├── NO  → return {} (container: env vars already set by Docker)
    │   └── YES → parse KEY=VALUE lines
    │             ├── key already in env? → skip (non-destructive)
    │             └── key missing?        → SetEnvironmentVariable(key, value, Process)
    │
[3] $ApiKey = $env:DEEPSEEK_API_KEY  (now guaranteed to be set)
    │
[4] Invoke-LLMWithRAG (DEEPSEEK_API_KEY) → Invoke-RAGSearch → rag_search.py (QDRANT_API_KEY)
    │
[5] Result returned
```

---

## 4. Cosa

### Secrets gestiti

| Secret | Servizio | Dove usato |
|--------|----------|-----------|
| `DEEPSEEK_API_KEY` | DeepSeek AI API | Tutti gli agenti L2/L3 via `Invoke-LLMWithRAG` |
| `QDRANT_API_KEY` | Qdrant vector DB | `rag_search.py` → RAG retrieval |
| `GITEA_API_TOKEN` | Gitea SCM | Push, PR operations |

### File `.env.secrets` — formato

```bash
# EasyWay Secrets - managed file, do NOT edit manually without updating docs
# Source: migrated from ~/.bashrc on 2026-02-09
# Next step: see Wiki/security/secrets-management-roadmap.md for cloud vault migration
DEEPSEEK_API_KEY=sk-...
GITEA_API_TOKEN=...
QDRANT_API_KEY=...
```

**Regole del file**:
- Righe che iniziano con `#` = commenti (ignorati)
- Formato: `KEY=VALUE` (KEY: lettere, cifre, underscore; inizia con lettera)
- Nessun quoting necessario per valori senza spazi
- **Mai committare questo file** — è in `.gitignore`
- Percorso su server: `/opt/easyway/.env.secrets` (owned: `ubuntu:ubuntu`, mode: `600`)

---

## 5. Come

### Integrazione in un runner (pattern standard)

```powershell
# Dopo la definizione dei path, prima di qualsiasi uso di $env:DEEPSEEK_API_KEY:

# ─── Bootstrap: load platform secrets (idempotent, non-destructive) ────────────
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets | Out-Null
}
# Resolve ApiKey dopo il caricamento dei secrets (il default del param è valutato prima)
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }
if (-not $ApiKey) {
    Write-Error "DEEPSEEK_API_KEY not set. Add to /opt/easyway/.env.secrets or pass -ApiKey."
    exit 1
}
```

**Perché `if (Test-Path $importSecretsSkill)`?**
Safety guard: se la skill non esiste (deploy parziale, test isolato), il runner non crasha. Il comportamento degradato è: l'env var deve essere presente per altro motivo (container, CI/CD).

**Perché `if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }` dopo il load?**
In PowerShell, il valore default di un parametro (`[string]$ApiKey = $env:DEEPSEEK_API_KEY`) è valutato al momento del binding del parametro, cioè **prima** del corpo dello script. Se `$env:DEEPSEEK_API_KEY` non è settata in quel momento, `$ApiKey` diventa `""`. Dopo il call a `Import-AgentSecrets`, l'env var è settata, ma `$ApiKey` è già `""`. La seconda assegnazione esplicita risolve questa race condition.

### Uso da riga di comando (SSH shell)

```bash
# Dopo Session 14: non serve più esportare manualmente
pwsh agents/agent_security/Invoke-AgentSecurity.ps1 \
  -Action security:analyze \
  -Query "Analizza configurazione docker-compose..." \
  -JsonOutput
# Import-AgentSecrets carica DEEPSEEK_API_KEY e QDRANT_API_KEY da .env.secrets automaticamente

# Override esplicito (ancora supportato, non-destructive)
DEEPSEEK_API_KEY=sk-override pwsh Invoke-AgentSecurity.ps1 ...
# → Import-AgentSecrets skippa DEEPSEEK_API_KEY (già in env), carica QDRANT_API_KEY
```

### Skill API reference

```powershell
. agents/skills/utilities/Import-AgentSecrets.ps1

# Uso standard
Import-AgentSecrets | Out-Null

# Con path custom (test, CI)
$loaded = Import-AgentSecrets -SecretsFile '/run/secrets/.env.platform'

# Verbose output (debug)
Import-AgentSecrets -Verbose
# [Import-AgentSecrets] Loaded: DEEPSEEK_API_KEY
# [Import-AgentSecrets] Loaded: QDRANT_API_KEY
# [Import-AgentSecrets] Skipped (already set): GITEA_API_TOKEN
# [Import-AgentSecrets] Loaded 2 secret(s) from: /opt/easyway/.env.secrets
```

---

## 6. Perché

### Perché non passare i secrets come parametri?

Il pattern "passare `-QdrantApiKey` come param" (PR #74, poi ritirata) presenta problemi strutturali:

1. **Proliferazione di parametri**: ogni nuovo secret richiede un nuovo parametro in ogni script
2. **Responsabilità frammentata**: il caller deve sapere quali secrets servono alla skill
3. **Non scalabile**: con 10 agenti e 5 secrets → 50 punti di modifica per ogni nuovo secret
4. **Leakage risk**: secrets in command line → visibili in `ps aux`, history, log

### Perché non usare Azure Key Vault direttamente?

Azure Key Vault è il target futuro (vedi `secrets-management-roadmap.md`). Non è la soluzione attuale perché:
- Richiede `az login` o managed identity (non disponibile fuori da Azure)
- Latenza per ogni lettura (~50-200ms) vs file locale (~1ms)
- Il file `.env.secrets` è già l'astraction layer: migrare a KV significa cambiare solo il file, non il codice

### Perché non mettere i secrets in variabili di ambiente permanenti del sistema (`/etc/environment`)?

- Visibili a tutti i processi della macchina → blast radius elevato
- Non portabili (diverso da Docker, Windows)
- Il modello file-on-disk è più controllabile e auditabile

### Perché `[System.EnvironmentVariableTarget]::Process` (non `User` o `Machine`)?

`Process` scope = variabile visibile solo al processo PowerShell corrente e ai suoi figli (incluso `python3 rag_search.py`). Non persiste dopo la fine del processo, non inquina l'ambiente di sistema. È la scelta con il minor blast radius possibile.

---

## 7. Runbook Operativo

### Verificare che tutti i secrets siano presenti sul server

```bash
ssh ubuntu@80.225.86.168 'cat /opt/easyway/.env.secrets | grep -v "^#" | cut -d= -f1'
# Output atteso:
# DEEPSEEK_API_KEY
# GITEA_API_TOKEN
# QDRANT_API_KEY
```

### Test Import-AgentSecrets in isolamento

```bash
ssh ubuntu@80.225.86.168 'cd ~/EasyWayDataPortal && pwsh -Command "
. agents/skills/utilities/Import-AgentSecrets.ps1
\$r = Import-AgentSecrets -Verbose
Write-Host \"Loaded: \$(\$r.Keys -join ', ')\"
Write-Host \"DEEPSEEK set: \$(\$env:DEEPSEEK_API_KEY.Length -gt 0)\"
Write-Host \"QDRANT set: \$(\$env:QDRANT_API_KEY.Length -gt 0)\"
"'
```

### Ruotare un secret

```bash
# 1. Aggiornare il valore nel file
sudo nano /opt/easyway/.env.secrets

# 2. Nessuna modifica al codice necessaria — Import-AgentSecrets legge sempre live

# 3. Riavviare il container per propagare nel container (se necessario)
docker restart easyway-runner

# 4. Aggiornare il secret nel container .env (se usato da Docker)
# → aggiornare docker-compose.yml o docker run --env-file
```

### Aggiungere un secret al container Docker

Per propagare un secret al container `easyway-runner`, aggiungerlo anche nel file `.env` usato da Docker (separato da `.env.secrets`). Vedi `docker-compose.yml` per la configurazione attuale.

---

## 8. Aggiungere un nuovo secret

**Checklist per aggiungere `NEW_SECRET_KEY`**:

```
[ ] 1. Aggiungere al server:
        echo "NEW_SECRET_KEY=value" | sudo tee -a /opt/easyway/.env.secrets

[ ] 2. Aggiungere al container Docker (se necessario):
        → aggiornare docker-compose.yml env_file o environment section

[ ] 3. Usarlo nel codice:
        # Import-AgentSecrets lo carica automaticamente — nessuna modifica necessaria
        # Basta usare $env:NEW_SECRET_KEY dopo il boot call

[ ] 4. Documentare in questa wiki (tabella sezione 4)

[ ] 5. Aggiornare platform-operational-memory.md se è un secret di piattaforma
```

**Nessuna modifica a `Import-AgentSecrets.ps1`**: il parsing è generico, carica tutti i `KEY=VALUE` presenti nel file.

---

## 9. Troubleshooting

### "401 Unauthorized" da Qdrant

```
WARNING: [agent_security] RAG retrieval failed: RAG Search Error: Unexpected Response: 401
```

**Causa**: `QDRANT_API_KEY` non settata al momento della chiamata a `rag_search.py`.

**Diagnosi**:
```bash
# Verifica che QDRANT_API_KEY sia in .env.secrets
grep QDRANT_API_KEY /opt/easyway/.env.secrets

# Verifica che Import-AgentSecrets la carichi
pwsh -Command ". agents/skills/utilities/Import-AgentSecrets.ps1; Import-AgentSecrets -Verbose"
```

**Fix**: Verificare che `/opt/easyway/.env.secrets` contenga `QDRANT_API_KEY` e che il runner chiami `Import-AgentSecrets` al boot.

### "DEEPSEEK_API_KEY not set" anche con .env.secrets presente

**Causa**: Il runner non chiama `Import-AgentSecrets` al boot, oppure il path alla skill è errato.

**Diagnosi**:
```powershell
# Verifica il path relativo
$SkillsDir = Join-Path $PSScriptRoot '..' 'skills'
Test-Path (Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1')
```

### Import-AgentSecrets non trova il file su Windows

Su Windows, il default path è `$USERPROFILE\.easyway\secrets`. Per usare un file diverso:
```powershell
Import-AgentSecrets -SecretsFile 'C:\old\.env.local'
```

### Secret ruotato ma ancora vecchio valore nel processo

`Import-AgentSecrets` è non-distruttivo: se `$env:KEY` è già settata, non aggiorna. Per forzare il reload in una sessione PS:
```powershell
[System.Environment]::SetEnvironmentVariable('QDRANT_API_KEY', $null, 'Process')
Import-AgentSecrets  # ora lo ricarica
```

---

## 10. Decisioni di Design (ADR)

### ADR-001: File-based secrets vs parameter injection (Session 14)

**Contesto**: RAG 401 Unauthorized perché `QDRANT_API_KEY` non propagata.

**Opzioni valutate**:
1. Parametro `-QdrantApiKey` in `Invoke-LLMWithRAG` (PR #74, ritirata)
2. `Import-AgentSecrets` skill centralizzata
3. Azure Key Vault diretto
4. Env vars di sistema (`/etc/environment`)

**Decisione**: Opzione 2 — skill centralizzata con `.env.secrets` come SSOT.

**Motivazione**:
- Zero modifiche alle skill condivise (Invoke-LLMWithRAG rimane clean)
- Non scalabile l'opzione 1 (N secrets × M runner = N×M param aggiunte)
- Opzione 3 non disponibile fuori da Azure e introduce latenza
- Opzione 4 troppo permissiva (blast radius: tutti i processi)

**Conseguenze**: ogni nuovo runner deve aggiungere il boot call. Documentato in questa wiki come pattern standard.

---

## References

- `agents/skills/utilities/Import-AgentSecrets.ps1` — implementazione skill
- `agents/skills/registry.json` v2.9.0 — entry `utilities.import-secrets`
- `/opt/easyway/.env.secrets` — SSOT secrets (server-side, mai committato)
- `Wiki/EasyWayData.wiki/security/segreti-e-accessi.md` — governance secrets generale
- `Wiki/EasyWayData.wiki/security/secrets-management-roadmap.md` — roadmap migrazione KV
- `agents/agent_security/Invoke-AgentSecurity.ps1` — esempio runner con boot call
- `agents/agent_review/Invoke-AgentReview.ps1` — esempio runner con boot call
- `scripts/pwsh/agent-infra.ps1` — esempio runner con boot call
