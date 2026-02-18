---
title: "Platform Operational Memory — EasyWay"
created: 2026-02-18
updated: 2026-02-18
status: active
category: reference
domain: platform
tags: [platform, operations, git, powershell, deploy, secrets, lessons-learned, qdrant, gitea, deepseek, server, ssh]
priority: high
audience:
  - all-agents
  - agent-developers
  - system-architects
  - team-platform
id: ew-platform-operational-memory
summary: >
  Consolidated operational knowledge for the EasyWay platform.
  Critical rules, lessons learned, git workflows, PowerShell standards,
  infrastructure reference, and known pitfalls for Claude Code and all L2 agents.
  This file is the single source of truth for platform-level know-how.
owner: team-platform
related:
  - [[agents/agent-design-standards]]
  - [[agents/agent-evolution-roadmap]]
  - [[agents/agent-roster]]
  - [[security/secrets-management-roadmap]]
llm:
  include: true
  pii: low
  chunk_hint: 300-400
  redaction: [ip_address, api_key]
type: reference
---

# Platform Operational Memory — EasyWay

> **Scopo**: Questo documento e' la memoria operativa del team platform. Contiene tutto cio' che abbiamo imparato lavorando sulla piattaforma: workflow corretti, configurazioni, errori da non ripetere, e riferimenti rapidi. E' indicizzato in Qdrant e accessibile a tutti gli agenti L2 tramite RAG.

---

## 1. Deploy Workflow (CRITICO)

> **MAI copiare file direttamente con SCP al server. TUTTO passa per git.**

```
1. Modifica locale in C:\old\EasyWayDataPortal\
2. git add + git commit (usa ewctl commit per Iron Dome)
3. git push origin <branch>
4. SSH al server -> cd ~/EasyWayDataPortal && git pull
5. Solo DOPO -> test nel container
```

**Branch protetti**: `main`, `develop`, `baseline` — MAI commit diretto. Sempre feature branch -> PR -> merge.

**Commit tool**: usare `ewctl commit` (attiva Iron Dome pre-commit checks), non `git commit` diretto.

**Prima di qualsiasi lavoro**: eseguire `git branch --show-current` per verificare di essere sul branch corretto.

---

## 2. Server e Infrastruttura

| Componente | Valore |
|---|---|
| Server OS | Ubuntu on OCI |
| IP pubblico | `80.225.86.168` |
| SSH key | `C:\old\Virtual-machine\ssh-key-2026-01-25.key` |
| SSH comando | `ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168` |
| Interfaccia esterna | `enp0s6` |
| Rete NTT Data | Blocca siti AI/ML — usare hotspot o proxy server |

### Port Hardening (DOCKER-USER chain)
Porte bloccate esternamente (via `enp0s6`):
- 9000, 9001 (MinIO)
- 10000-10002 (Azurite)
- 8929, 2222 (GitLab legacy)
- 6333 (Qdrant)
- 1433 (SQL Azure Edge)
- 5678 (n8n)
- 2019 (Caddy admin)
- 3000 (API)
- 3100 (Gitea)

Porte pubbliche: **80, 443** (Caddy reverse proxy), **22** (SSH).

Regole persistite in `/etc/iptables/rules.v4`.

---

## 3. Secrets Management

| Elemento | Dettaglio |
|---|---|
| File secrets | `/opt/easyway/.env.secrets` (chmod 600, owner ubuntu) |
| Contiene | `DEEPSEEK_API_KEY`, `GITEA_API_TOKEN` |
| Docker override | `docker-compose.secrets.yml` (in .gitignore) |
| Wrapper script | `scripts/dc.sh` — include secrets automaticamente |
| Roadmap | `Wiki/.../security/secrets-management-roadmap.md` (4 opzioni cloud) |

**IMPORTANTE**: le chiavi NON sono piu' in `~/.bashrc` (rimosso in Session 3). Backup a `~/.bashrc.bak.20260209`.

---

## 4. Servizi Chiave

### DeepSeek API
| Parametro | Valore |
|---|---|
| API Key | in `/opt/easyway/.env.secrets` |
| Modelli | `deepseek-chat` (generale), `deepseek-reasoner` (thinking) |
| Costo per call | ~$0.00025-0.0005 |
| Endpoint | `https://api.deepseek.com/chat/completions` |
| Token cost | ~$0.14 per 1M token (cache miss), `costPerToken = 0.00000014` |

### Qdrant (RAG)
| Parametro | Valore |
|---|---|
| Versione | v1.16.2 |
| Porta | 6333 (bloccata esternamente) |
| API Key | `wgs6XqCt8qglELghWG6IE4kvzdDgh3Kk` |
| Collection | `easyway_wiki` |
| Dimensioni | ~27,000+ chunk, 384 dim (MiniLM-L6-v2), cosine |
| Ingest script | `scripts/ingest_wiki.js` — usa env var `WIKI_PATH` per targeting parziale |

### Gitea (Git interno)
| Parametro | Valore |
|---|---|
| Container | `easyway-gitea` (93 MB RAM) |
| Image | `gitea/gitea:1.22-rootless` |
| Porta | 3100 (bloccata esternamente) |
| Admin | `easywayadmin` / `EasyWay2026!` |
| Compose | `docker-compose.gitea.yml` |
| Push mirror | Azure DevOps (auto ogni 10min + on-commit) |
| Note | GitLab: containers `Exited`, volumi preservati in `~/EasyWayDataPortal/gitlab/` |

### easyway-runner
- Volume mount: `/app/agents` -> `~/EasyWayDataPortal/agents` sull'host
- 31 agents caricati, 9 Level 2 (LLM)
- Skills registry: `agents/skills/registry.json` v2.5.0

---

## 5. Git Workflow Corretto

```
feature branch -> ewctl commit -> git push -> PR (Azure DevOps / Gitea) -> merge -> server git pull
```

**Branch naming**:
- Feature: `feat/<scope>-<description>`
- Fix: `fix/<scope>-<description>`
- Release: `release/<version>`

**SEMPRE prima di lavorare**:
```powershell
git branch --show-current   # verifica branch corrente
```

**Merge commit e file tracking**:
- `git show --name-only` su merge commit mostra solo diff vs first parent
- Per file aggiunti via second parent: usare `git log --diff-filter=A --name-only`

---

## 6. PowerShell Coding Standards

### Encoding: Em Dash nei file .ps1

> **CRITICO**: Non usare em dash `—` (U+2014) in double-quoted strings nei file `.ps1`.

**Causa**: PowerShell 5.1 su Windows legge i file `.ps1` UTF-8 come Windows-1252. Il byte `0x94` (terzo byte dell'em dash in UTF-8, sequenza `E2 80 94`) corrisponde al carattere `"` in Windows-1252, troncando la stringa prematuramente.

**Effetto**: il parser riporta errori a cascata su righe successive (brace mismatch, unexpected tokens) rendendo difficile trovare la causa radice.

**Soluzioni**:
```powershell
# SBAGLIATO: em dash in double-quoted string
Write-Warning "Call failed (non-blocking — treating as PASS): $_"

# CORRETTO: virgola o trattino
Write-Warning "Call failed (non-blocking, treating as PASS): $_"
Write-Warning "Call failed (non-blocking - treating as PASS): $_"
```

**Aree sicure** per l'em dash: here-strings (`@"..."@`) e commenti (`#`). Il problema si manifesta SOLO nelle double-quoted strings (`"..."`).

**Debug tool**: `[System.Management.Automation.Language.Parser]::ParseFile()` con `-ExecutionPolicy Bypass`. Gli errori di colonna possono essere sfasati di 2 per via del multi-byte UTF-8.

### Heredoc e variabili PowerShell in bash

Quando si esegue bash da Claude Code, il heredoc interpola le variabili PowerShell `$variable`. Usare SCP per file complessi invece di passarli via stdin.

### Script con escaping complesso

Per script con escaping problematico: scrivere il file localmente -> copiarlo via git -> eseguirlo. Non usare echo/heredoc per generare script PowerShell da bash.

### Sintassi PowerShell: verifica pre-commit

```powershell
$errors = $null; $tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile('file.ps1', [ref]$tokens, [ref]$errors)
if ($errors.Count -eq 0) { "SYNTAX OK" } else { $errors | ForEach-Object { "Line $($_.Extent.StartLineNumber): $($_.Message)" } }
```

---

## 7. SSH e Comandi Remoti

**Problema**: SSH da bash Claude Code non cattura l'output correttamente.

**Soluzione**: usare PowerShell con redirect su file:
```powershell
powershell -NoProfile -NonInteractive -Command "ssh -i 'key.pem' ubuntu@host 'comando' | Out-File 'C:\temp\out.txt'"
```

Poi leggere `C:\temp\out.txt` con il Read tool.

---

## 8. Agenti — Stato Corrente

### Livelli agenti
- **L1 (scripted)**: 23 agenti — logica deterministica, no LLM
- **L2 (LLM+RAG)**: 9 agenti — DeepSeek + Qdrant RAG
- **L3 (target)**: primo candidato `agent_review` — Evaluator-Optimizer + working memory

### Agenti L2 attivi
`agent_backend`, `agent_dba`, `agent_docs_sync`, `agent_governance`, `agent_infra`, `agent_pr_manager`, `agent_review`, `agent_security`, `agent_vulnerability_scanner`

### Skill retrieval.llm-with-rag (Invoke-LLMWithRAG)
Parametri principali:
```powershell
Invoke-LLMWithRAG `
  -Query "..." `
  -AgentId "agent_review" `
  -SystemPrompt $prompt `
  -SecureMode `                          # obbligatorio in produzione
  -EnableEvaluator `                     # Gap 1 — Evaluator-Optimizer
  -AcceptanceCriteria @("AC-01...", "AC-02...") `
  -MaxIterations 2                       # default: 2
```

**Evaluator-Optimizer** (implementato in Session 5):
- Attivato con `-EnableEvaluator -AcceptanceCriteria @(...)`
- Loop: generator call -> evaluator scoring -> retry con feedback se AC falliscono
- Graceful degradation: se evaluator call fallisce, restituisce output del generator senza bloccare
- Backward-compatible: tutti i parametri evaluator sono opzionali

---

## 9. Gaps Roadmap Agent Evolution

| Gap | Titolo | Stato | File |
|---|---|---|---|
| Gap 1 | Evaluator-Optimizer | DONE (Session 5) | `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` |
| Gap 2 | Working Memory (session.json) | TODO Q2 2026 | `agents/core/schemas/session.schema.json` |
| Gap 3 | Parallelization (Start-ThreadJob) | TODO Q3 2026 | orchestrator |
| Gap 4 | Confidence Scoring (0.0-1.0) | DONE (Session 6) | `agents/core/schemas/action-result.schema.json` |
| Gap 5 | Fixture Tests per L2 agent | DONE (Session 6) | `agents/agent_review/tests/fixtures/` |
| Gap 6 | `returns` field in registry.json | DONE (Session 6) | `agents/skills/registry.json` v2.6.0 |

---

## 10. Issues Noti

| Problema | Workaround | Stato |
|---|---|---|
| `sqlcmd` non trovato in Azure SQL Edge | PATH non configurato nel container | Open |
| GitHub mirror non configurato | Mancano repo creation + PAT | Open |
| `infra/observability/data/` file root-owned sul server | `git stash` fallisce su questi file | Open |
| `git stash push --include-untracked` su file root-owned | Salva solo i file accessibili, ignora il resto | Known |
| `az repos pr create` non eredita PAT | Impostare `AZURE_DEVOPS_EXT_PAT` nella sessione corrente | Known |

---

## 11. Lessons Learned

1. **MAI SCP diretto al server** — tutto via git commit -> push -> pull
2. **Em dash in double-quoted PS strings** rompe il parser PS5.1 (vedi sezione 6)
3. **Docker volume mounts** mappano le directory host nel container direttamente
4. **Heredoc bash** interpola `$variable` PowerShell — usare SCP per file complessi
5. **DOCKER-USER chain** e' l'unico modo per bloccare le porte Docker esternamente (non INPUT chain)
6. **Gitea rootless** richiede `INSTALL_LOCK=true` in `app.ini` dopo il primo avvio
7. **SSH da bash Claude Code** non cattura output — usare PowerShell con `Out-File`
8. **`git show --name-only`** su merge commit mostra solo diff vs first parent — usare `git log --diff-filter=A` per file aggiunti via second parent
9. **`git stash push --include-untracked`** fallisce su file root-owned ma salva il resto
10. **`az repos pr create`** richiede `AZURE_DEVOPS_EXT_PAT` nella sessione corrente
11. **Emoji con byte 0x94 in UTF-8** (es. U+1F504 🔄, U+1F50D 🔍) causano lo stesso problema dell'em dash in PS5.1 `ParseFile`. Usare testo ASCII nelle stringhe PS. Il problema NON si manifesta sotto `pwsh` (PS7).
12. **`WIKI_PATH` per ingest_wiki.js**: passare sempre una DIRECTORY, non un file singolo. Il glob aggiunge `/**/*.md` — un path a file singolo restituisce 0 file trovati.

---

## 12. Architettura Distribuzione Regole agli Agenti

Le regole operative della piattaforma vengono distribuite a tre livelli:

| Livello | File | Chi lo riceve | Come |
|---|---|---|---|
| **L1 — Claude Code / Cursor** | `MEMORY.md`, `.cursorrules` | AI assistant nella IDE | System prompt automatico |
| **L2 — Agenti L2 (guaranteed)** | `Invoke-LLMWithRAG.ps1` | Tutti i 9 agenti L2 | `$script:PlatformRules` iniettato ad ogni chiamata |
| **L3 — Agenti L2 (query-dependent)** | `platform-operational-memory.md` (Qdrant) | Agenti L2 con query pertinente | RAG retrieval |

### Opzione A — Inject in Invoke-LLMWithRAG.ps1 (IMPLEMENTATA - Session 5)
`$script:PlatformRules` e' un blocco di testo costante iniettato nel system prompt di OGNI chiamata L2.
Garanzia: le regole critiche arrivano sempre, indipendentemente dalla query RAG.
Overhead: ~80-100 token fissi per chiamata.

### Opzione B — Shared Snippet per PROMPTS.md (IN CANTIERE - Q2 2026)
Creare `agents/core/prompts/platform-rules.snippet.md`.
Ogni agente L2 importa lo snippet nel proprio `PROMPTS.md`.
Permette regole personalizzate per agente (es. agent_dba riceve anche regole DB-specifiche).
Richiede: modifica dei 9 `PROMPTS.md` + meccanismo di import nello script di avvio.

---

## 13. Platform Knowledge Sync — Infrastruttura (Session 6)

La conoscenza operativa viene sincronizzata automaticamente tra tre fonti tramite uno script dedicato.

### Flusso di Sync

```
MEMORY.md (note sessione Claude Code)
      |
      | (manuale: aggiornare wiki quando la conoscenza e' stabile)
      v
Wiki/platform-operational-memory.md   <-- FONTE UNICA DI VERITA'
      |
      | Sync-PlatformMemory.ps1 (auto via pre-commit o manuale)
      v
.cursorrules [AUTO-SYNC-START ... AUTO-SYNC-END]
      |
      | $script:PlatformRules in Invoke-LLMWithRAG.ps1 (garantito a ogni call L2)
      v
Qdrant easyway_wiki (collection, query-dependent)
```

### Script: scripts/pwsh/Sync-PlatformMemory.ps1

| Parametro | Default | Descrizione |
|---|---|---|
| `-WikiFile` | `Wiki/.../platform-operational-memory.md` | File wiki sorgente |
| `-CursorRulesFile` | `.cursorrules` | File target |
| `-DryRun` | `$false` | Preview senza scrittura |

**Invocazione manuale**: `pwsh scripts/pwsh/Sync-PlatformMemory.ps1`
**Preview**: `pwsh scripts/pwsh/Sync-PlatformMemory.ps1 -DryRun`

### Trigger automatico (Iron Dome pre-commit)

Se `platform-operational-memory.md` e' staged al momento del commit:
1. Iron Dome rileva il file nella lista staged
2. Chiama `Sync-PlatformMemory.ps1` automaticamente
3. Fa `git add .cursorrules` per includere l'aggiornamento nel commit

### Regola operativa per Claude Code

> **Ogni volta che MEMORY.md viene aggiornata con conoscenza stabile (non note temporanee di sessione),
> aggiornare anche la wiki e poi eseguire `Sync-PlatformMemory.ps1` per propagare a `.cursorrules`.**

Formato sezione auto-generata in `.cursorrules`:
- Aperta da: `# AUTO-SYNC-START`
- Chiusa da: `# AUTO-SYNC-END`
- Contiene: corpo della wiki senza frontmatter YAML + timestamp di ultima sync

### Markers in .cursorrules

```
# AUTO-SYNC-START: Regenerated by scripts/pwsh/Sync-PlatformMemory.ps1
# Source: Wiki/EasyWayData.wiki/agents/platform-operational-memory.md
# Last sync: <timestamp>
[contenuto auto-generato dalla wiki]
# AUTO-SYNC-END
```

---

## Riferimenti

- [[agents/agent-design-standards]] — Pattern Anthropic per agenti
- [[agents/agent-evolution-roadmap]] — Roadmap L1->L2->L3
- [[agents/agent-roster]] — Roster completo 31 agenti
- [[security/secrets-management-roadmap]] — 4 opzioni gestione secrets cloud
- `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` — Bridge LLM+RAG (con Evaluator-Optimizer, Gap 1)
- `agents/core/schemas/action-result.schema.json` — Schema output standard (con campo `confidence`, Gap 4)
- `agents/skills/registry.json` v2.6.0 — Catalogo 22 skills con campo `returns` (Gap 6)
- `agents/agent_review/tests/fixtures/` — 3 fixture JSON per agent_review (Gap 5)
- `scripts/pwsh/Sync-PlatformMemory.ps1` — Script sync wiki → .cursorrules (Session 6)
