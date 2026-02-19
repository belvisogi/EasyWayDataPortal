---
title: "Parallel Agent Execution — Guida a Invoke-ParallelAgents"
created: 2026-02-19
updated: 2026-02-19
status: active
type: guide
category: orchestration
domain: agents
tags:
  - domain/agents
  - layer/orchestration
  - tool/parallel-agents
  - gap3
  - level3
audience:
  - agent-developers
  - team-platform
id: ew-guides-parallel-agent-execution
summary: >
  Guida completa alla skill orchestration.parallel-agents (Invoke-ParallelAgents.ps1).
  Copre API, parametri, pattern d'uso, gestione timeout, troubleshooting e integrazione
  con il workflow L3. Implementata in Session 10, verificata E2E in Session 11.
llm:
  include: true
  pii: none
  chunk_hint: 300-450
  redaction: []
related:
  - [[agents/agent-evolution-roadmap]]
  - [[agents/agent-system-architecture-overview]]
  - [[standards/agent-architecture-standard]]
---

# Parallel Agent Execution — Guida a `Invoke-ParallelAgents`

> **Gap 3 — Parallelization** della [Agent Evolution Roadmap](../agents/agent-evolution-roadmap.md).
> Implementato in Session 10, verificato E2E in Session 11. Status: **DONE**.

---

## Panoramica

`Invoke-ParallelAgents` è la skill di orchestrazione che permette di eseguire **più agent script in parallelo** e di raccogliere i risultati aggregati al termine. Risolve un collo di bottiglia critico nei workflow L3: i subtask indipendenti non devono attendere la fine del precedente per avviarsi.

**Quando usarla**:

| Scenario | Esempio |
|----------|---------|
| PR gate multi-agente | `agent_review` + `agent_security` sulla stessa PR simultaneamente |
| Multi-scanner | docker-scout + trivy in parallelo, merge findings |
| Voting ensemble | Più istanze di `classify-intent` con majority vote |
| Pipeline fanout | Analisi impatto + check dipendenze + health check in simultanea |

**Quando NON usarla**:
- I job hanno dipendenze tra loro (output di A serve a B) → usare chiamate sequenziali
- Un singolo agente con stato condiviso → usare Working Memory (`session.json`)

---

## Quick Start

```powershell
# Carica la skill
. "$repoRoot/agents/skills/orchestration/Invoke-ParallelAgents.ps1"

# Esegui due agenti in parallelo
$results = Invoke-ParallelAgents -AgentJobs @(
    @{
        Name    = "review"
        Script  = "agents/agent_review/Invoke-AgentReview.ps1"
        Args    = @{ Query = "PR #42 — static analysis"; Action = "review:static" }
        Timeout = 120
    },
    @{
        Name    = "security"
        Script  = "agents/agent_security/run-with-rag.ps1"
        Args    = @{ Query = "PR #42 — security scan"; Action = "security:analyze" }
        Timeout = 90
    }
) -GlobalTimeout 150 -SecureMode

# Accesso ai risultati
if ($results.Success) {
    $reviewAnswer  = $results.JobResults["review"].Output.Answer
    $securityAnswer = $results.JobResults["security"].Output.Answer
    Write-Host "Tutti i gate superati in $($results.DurationSec)s"
} else {
    Write-Warning "Job falliti: $($results.Failed -join ', ')"
}
```

---

## Riferimento API

### Firma

```powershell
Invoke-ParallelAgents
    -AgentJobs    <array>    # Obbligatorio
    [-GlobalTimeout <int>]   # Default: 180
    [-FailFast]              # Switch
    [-SecureMode]            # Switch
```

### Parametri di input

| Parametro | Tipo | Obbligatorio | Default | Descrizione |
|-----------|------|:---:|---------|-------------|
| `AgentJobs` | `array` | **SI** | — | Array di hashtable che definisce i job da eseguire. Vedi [Job Definition](#job-definition). |
| `GlobalTimeout` | `int` | no | `180` | Timeout globale in secondi. Allo scadere, tutti i job ancora attivi vengono killati e marcati `Failed`. |
| `FailFast` | `switch` | no | off | Se impostato, il primo job in stato `Failed` o timed-out causa l'abort immediato di tutti i job rimanenti. |
| `SecureMode` | `switch` | no | off | Sopprime il logging di dati sensibili (API key, credenziali). Usare sempre in produzione. |

### Job Definition

Ogni elemento di `AgentJobs` è un hashtable con le seguenti chiavi:

| Chiave | Tipo | Obbligatorio | Default | Descrizione |
|--------|------|:---:|---------|-------------|
| `Name` | `string` | **SI** | — | Label logica del job. Usata come chiave in `JobResults`. Deve essere univoca nell'array. |
| `Script` | `string` | **SI** | — | Path relativo alla repo root dello script `.ps1` da eseguire. Es: `agents/agent_review/Invoke-AgentReview.ps1`. |
| `Args` | `hashtable` | no | `@{}` | Parametri named da passare allo script con splatting (`& script @Args`). |
| `Timeout` | `int` | no | `120` | Timeout per-job in secondi. Se il job supera questa soglia viene killato indipendentemente dal `GlobalTimeout`. |

### Valore di ritorno

La skill ritorna sempre una hashtable con la seguente shape:

```powershell
@{
    Success     = [bool]      # True se almeno un job ha avuto successo
    JobResults  = [hashtable] # Keyed by Name — vedi sotto
    Failed      = [string[]]  # Nomi dei job falliti o scaduti (array vuoto se tutto OK)
    DurationSec = [double]    # Wall-clock totale in secondi (arrotondato a 2 decimali)
}
```

Ogni entry in `JobResults[$name]` ha questa forma:

```powershell
# Job completato con successo (script ritorna oggetto con campo Success)
@{
    Success = $true
    Output  = <oggetto ritornato dallo script>
}

# Job completato ma con errore interno allo script
@{
    Success = $false
    Error   = "Script exited with code 1"
    Output  = <eventuale output parziale>
}

# Job fallito per timeout o crash del job
@{
    Success = $false
    Error   = "Timed out after 90s"   # oppure "Job state: Failed"
}

# Script non trovato (job non avviato)
@{
    Success = $false
    Error   = "Script not found: /path/to/script.ps1"
}
```

> **Nota su `Success` globale**: il campo `Success` della hashtable radice è `True` se *almeno un job* ha avuto successo. Per verificare che **tutti** i job abbiano avuto successo, usare `$results.Failed.Count -eq 0`.

---

## Esempi d'uso

### Esempio 1 — PR Gate (review + security)

Il pattern principale: due agenti L3/L2 analizzano la stessa PR in parallelo prima del merge.

```powershell
$prNumber = 42

$gate = Invoke-ParallelAgents -AgentJobs @(
    @{
        Name    = "review"
        Script  = "agents/agent_review/Invoke-AgentReview.ps1"
        Args    = @{
            Query  = "PR #$prNumber — static analysis and docs coverage"
            Action = "review:static"
        }
        Timeout = 120
    },
    @{
        Name    = "security"
        Script  = "agents/agent_security/run-with-rag.ps1"
        Args    = @{
            Query  = "PR #$prNumber — dependency and secret scan"
            Action = "security:analyze"
        }
        Timeout = 90
    }
) -GlobalTimeout 150 -SecureMode

# Gate decision
if ($gate.Failed.Count -eq 0) {
    Write-Host "PR #$prNumber: tutti i gate PASSED ($($gate.DurationSec)s)" -ForegroundColor Green
} else {
    Write-Error "PR #$prNumber: gate FAILED — $($gate.Failed -join ', ')"
    exit 1
}
```

### Esempio 2 — Multi-Scanner (docker-scout + trivy)

Due scanner CVE in parallelo, poi merge dei risultati.

```powershell
$image = "easyway-runner:latest"

$scan = Invoke-ParallelAgents -AgentJobs @(
    @{
        Name    = "scout"
        Script  = "agents/agent_vulnerability_scanner/run-scout.ps1"
        Args    = @{ ImageName = $image; FailOnSeverity = "critical" }
        Timeout = 60
    },
    @{
        Name    = "trivy"
        Script  = "agents/agent_vulnerability_scanner/run-trivy.ps1"
        Args    = @{ ImageName = $image; FailOnSeverity = "high" }
        Timeout = 60
    }
) -GlobalTimeout 90

# Merge findings
$allCritical = @()
foreach ($scanner in $scan.JobResults.Keys) {
    if ($scan.JobResults[$scanner].Success) {
        $allCritical += $scan.JobResults[$scanner].Output.critical
    }
}
Write-Host "Totale CVE critici rilevati: $($allCritical | Measure-Object -Sum | Select-Object -ExpandProperty Sum)"
```

### Esempio 3 — Majority Voting (intent classification)

Tre classificatori in parallelo, il risultato con maggioranza vince.

```powershell
$userInput = "Come faccio a deployare in produzione?"

$voters = Invoke-ParallelAgents -AgentJobs @(
    @{ Name = "clf1"; Script = "agents/agent_retrieval/run-classify.ps1"
       Args = @{ Query = $userInput; Model = "deepseek-chat" }; Timeout = 30 },
    @{ Name = "clf2"; Script = "agents/agent_retrieval/run-classify.ps1"
       Args = @{ Query = $userInput; Model = "deepseek-chat" }; Timeout = 30 },
    @{ Name = "clf3"; Script = "agents/agent_retrieval/run-classify.ps1"
       Args = @{ Query = $userInput; Model = "deepseek-chat" }; Timeout = 30 }
) -GlobalTimeout 45

# Majority vote
$votes = $voters.JobResults.Values |
    Where-Object { $_.Success } |
    ForEach-Object { $_.Output.intent }

$winner = $votes | Group-Object | Sort-Object Count -Descending | Select-Object -First 1
Write-Host "Intent votato: $($winner.Name) ($($winner.Count)/3 voti)"
```

### Esempio 4 — FailFast su pipeline critica

Abort immediato se qualsiasi step fallisce (es. pre-deploy checks).

```powershell
$checks = Invoke-ParallelAgents -AgentJobs @(
    @{ Name = "health";  Script = "agents/agent_observability/run-health.ps1"
       Args = @{ Target = "all" }; Timeout = 30 },
    @{ Name = "db-conn"; Script = "agents/agent_dba/run-check.ps1"
       Args = @{ Server = "sql-edge"; Database = "EasyWayDB" }; Timeout = 20 },
    @{ Name = "secrets"; Script = "agents/agent_security/run-secrets-check.ps1"
       Args = @{}; Timeout = 15 }
) -GlobalTimeout 60 -FailFast

if ($checks.Failed.Count -gt 0) {
    Write-Error "Pre-deploy check FAILED: $($checks.Failed -join ', ') — deploy annullato"
    exit 1
}
Write-Host "Pre-deploy check OK in $($checks.DurationSec)s — proceed to deploy"
```

---

## Comportamento Timeout

La skill implementa **due livelli di timeout** indipendenti:

```
┌─────────────────────────────────────────────────────────────────┐
│                   GlobalTimeout (es. 180s)                      │
│                                                                 │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │  Job "review"        │    │  Job "security"              │  │
│  │  Timeout: 120s       │    │  Timeout: 90s                │  │
│  │  ████████████░░░░░░  │    │  ████████░░░░░░░░░░░░░░░░░  │  │
│  │  Completato: 95s     │    │  Scaduto a 90s → Failed      │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

| Scenario | Comportamento |
|----------|---------------|
| Job completa entro il suo `Timeout` | Risultato disponibile in `JobResults` |
| Job supera `Timeout` individuale | Job stoppato, aggiunto a `Failed`, attende gli altri (se no `-FailFast`) |
| Tutti i job superano `GlobalTimeout` | Tutti i job attivi killati, aggiunti a `Failed` |
| `-FailFast` + primo job fallisce | Tutti i job rimanenti stoppati immediatamente |

**Best practice timeout**:
- `Timeout` per-job = stima realistica del singolo agente + 20% buffer
- `GlobalTimeout` = max per-job timeout + 30s overhead (scheduling, OS context switch)
- Non impostare `GlobalTimeout` < `Timeout` di qualsiasi job

---

## Job Engine: ThreadJob vs Start-Job

La skill rileva automaticamente l'ambiente PowerShell e sceglie il motore ottimale:

| | `Start-ThreadJob` (PS7+) | `Start-Job` (PS5.1) |
|--|--------------------------|----------------------|
| **Isolamento** | Thread nello stesso processo | Subprocess separato |
| **Overhead avvio** | ~ms | ~1-3s per job |
| **Memoria condivisa** | Si (variabili PowerShell) | No (serializzazione) |
| **Env vars** | Ereditate dal padre | Ereditate dal padre |
| **Crash isolation** | No (crash = crash processo) | Si (subprocess muore isolato) |
| **Quando usare** | PS7+ (default su Ubuntu/container) | PS5.1 (Windows legacy) |

Il fallback è automatico: se `Start-ThreadJob` non è disponibile, viene usato `Start-Job` senza modifiche ai parametri chiamanti.

```powershell
# Verifica motore attivo (solo per debug)
$useThread = [bool](Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)
Write-Host "Job engine: $(if ($useThread) {'ThreadJob (PS7)'} else {'Start-Job (PS5.1)'})"
```

---

## Troubleshooting

### Job fallisce immediatamente con "Script not found"

**Causa**: il path in `Script` non è relativo alla repo root.

```powershell
# Errato — path assoluto o errato
@{ Script = "C:\old\EasyWayDataPortal\agents\agent_review\Invoke-AgentReview.ps1" }

# Corretto — relativo alla repo root
@{ Script = "agents/agent_review/Invoke-AgentReview.ps1" }
```

La skill risolve automaticamente la repo root risalendo 3 livelli da `$PSScriptRoot`:
`orchestration/` → `skills/` → `agents/` → **repo root**.

---

### Job non ritorna il valore atteso (`Output = $null`)

**Causa**: lo script interno non ritorna un oggetto con campo `Success`, oppure usa `Write-Output` invece di `return`.

La skill controlla `$output.PSObject.Properties['Success']`. Se assente, il job è marcato come `Success = $true` ma `Output` contiene l'output grezzo.

**Fix**: assicurarsi che gli script agent ritornino un hashtable con `Success` esplicito:

```powershell
# Corretto
return @{ Success = $true; Answer = "..." }

# Problematico — viene ricevuto come stringa
Write-Output "risultato"
```

---

### `Receive-Job` intercetta UserWarning da Python

**Causa**: alcuni script LLM invocano Python (embedding/Qdrant), che emette warning su stderr. Con `ErrorActionPreference = 'Stop'`, questi diventano eccezioni terminanti nel job.

**Soluzione già implementata**: lo scriptBlock interno usa `$ErrorActionPreference = 'Continue'` e `Receive-Job -ErrorAction SilentlyContinue`. Non modificare questo comportamento.

---

### Tutti i job scadono per GlobalTimeout troppo basso

**Sintomo**: `$results.Failed` contiene tutti i job, `DurationSec` ≈ `GlobalTimeout`.

**Soluzione**:
1. Aumentare `GlobalTimeout` (regola: max per-job Timeout + 30s)
2. Verificare se i job impiegano più del previsto (logging con host `-ForegroundColor Gray`)
3. Considerare di ridurre `TopK` RAG o `MaxTokens` nei job LLM per ridurre la latenza

---

### FailFast aborta troppo presto

**Scenario**: un job flaky (es. rete instabile) causa abort di job critici.

**Alternativa**: non usare `-FailFast`. Raccogliere tutti i risultati e decidere post-esecuzione:

```powershell
$r = Invoke-ParallelAgents -AgentJobs $jobs -GlobalTimeout 120  # no FailFast

# Decisione custom: fallimento critico solo su job specifici
$criticalFailed = $r.Failed | Where-Object { $_ -in @("review", "security") }
if ($criticalFailed) { throw "Gate critico fallito: $($criticalFailed -join ', ')" }
```

---

## Integrazione con il Registry

La skill è registrata come `orchestration.parallel-agents` nel file `agents/skills/registry.json` v2.8.0:

```json
{
  "id": "orchestration.parallel-agents",
  "version": "1.0.0",
  "blast_radius": "MEDIUM",
  "allowed_callers": ["*"],
  "audit_log": true
}
```

- **`blast_radius: MEDIUM`** — può avviare processi/thread multipli; non modifica dati di produzione direttamente
- **`allowed_callers: ["*"]`** — qualsiasi agente può invocarla
- **`audit_log: true`** — ogni invocazione è loggata nell'audit trail

---

## Note Architetturali

1. **Scope PS**: ogni job gira nel proprio scope PowerShell. Variabili del chiamante non sono visibili al job salvo quelle esplicitamente passate in `Args`.

2. **Env vars**: le variabili d'ambiente (`$env:DEEPSEEK_API_KEY`, `$env:QDRANT_API_KEY`) sono ereditate automaticamente dal processo padre. Non passarle in `Args`.

3. **Stato condiviso**: con `Start-ThreadJob` (PS7), i thread condividono la memoria del processo padre ma operano su scope PS separati. Evitare scritture concorrenti sugli stessi file senza locking.

4. **Polling interval**: 500ms. Per job molto veloci (<1s) l'overhead di polling è trascurabile; per job lenti (>30s) è irrilevante.

5. **Cleanup**: i job completati sono rimossi con `Remove-Job -Force` immediatamente dopo la raccolta dei risultati. Non si accumulano zombie processes.

---

## Risultati E2E (Session 11)

Test eseguito il 2026-02-19 su `feature/session-11` con due agenti LLM reali:

```
Invoke-ParallelAgents — E2E Test Report
─────────────────────────────────────
Overall Success:  True
DurationSec:      26.11s   (parallelismo confermato: < upper bound seriale 180s)
Failed:           (none)

Job "static"      : Success=True | deepseek-chat | 5 RAG chunks
Job "docs-impact" : Success=True | deepseek-chat | 5 RAG chunks

Job engine:       Start-ThreadJob (PS7)
Fix applicati:    repoRoot .Parent.Parent.Parent, ErrorActionPreference=Continue,
                  Receive-Job -ErrorAction SilentlyContinue
```

---

## Riferimenti

- [Agent Evolution Roadmap — Gap 3](../agents/agent-evolution-roadmap.md#gap-3----parallelization--done-session-10)
- [Agent Architecture Standard](../standards/agent-architecture-standard.md)
- `agents/skills/orchestration/Invoke-ParallelAgents.ps1` — implementazione
- `agents/skills/registry.json` — entry `orchestration.parallel-agents` v1.0.0
- `agents/agent_review/Invoke-AgentReview.ps1` — agente L3 che usa questa skill
