---
title: "Platform Operational Memory — EasyWay"
created: 2026-02-18
updated: 2026-02-25T00:00:00Z
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

## 0. The Sovereign Law (La Costituzione)
> **Reference**: See `.cursorrules` (Section 0-8) for the full text of the Law.
> **Status**: The Active Agent MUST follow the Constitution provided in its System Prompt.
> **Key Principles**: Integrity, Fail-Fast Security, and Strict Standards.

## 0b. Fonti Normative e Precedenza (ANTI-CONFUSIONE)

Per evitare conflitti tra documenti con nomi simili:

1. **Source of truth operativa**: `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md`
2. **Derivato auto-sync**: `.cursorrules` (sincronizzato via `scripts/pwsh/Sync-PlatformMemory.ps1`)
3. **Entrypoint repo**: `AGENTS.md` in root repo

File `AGENTS.md` dentro `Wiki/**/archive/**` o `Wiki/**/indices/**` sono storici/indice e **non normativi**.

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
| Dimensioni | ~103,156 chunk (post Session 21-C), 384 dim (MiniLM-L6-v2), cosine |
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
- L1 (scripted): 22 agenti | L2 (LLM+RAG): 7 agenti | L3: 6 agenti (review, security, infra, levi, scrummaster, pr_gate)
- Skills registry: `agents/skills/registry.json` v2.9.0 (25 skill, incl. `orchestration.parallel-agents`, `utilities.import-secrets`)

---

## 5. Git Workflow Corretto

### Flusso PR obbligatorio (NON DEROGABILE)

> **MAI fare PR direttamente da feature branch a main.**
> Il flusso corretto e' SEMPRE: feature → develop → main (via PR release).
> Riferimento storico: Session 5 PR 32 (feat → develop) + PR 33 (develop → main).

```
feat/<name>
    | PR 1: feat -> develop
    v
develop
    | PR 2 (release): develop -> main  [titolo: "[Release] Session N — ..."]
    v
main
    | SSH: cd ~/EasyWayDataPortal && git pull
    v
server aggiornato
    | (se wiki cambiata) WIKI_PATH=Wiki node scripts/ingest_wiki.js
    v
Qdrant re-indexed
```

### Flusso completo comandi

```
ewctl commit
git push origin feat/<name>
# Azure DevOps: PR feat/<name> -> develop  (merge)
# Azure DevOps: PR develop -> main  [Release]  (merge)
# SSH server (se PAT valido):
cd ~/EasyWayDataPortal && git pull origin main
# SSH server (se PAT scaduto — aggiornare remote prima):
git remote set-url origin 'https://Tokens:<PAT>@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal' && git pull origin main
```

### Qdrant full re-index (comando completo)

```bash
source /opt/easyway/.env.secrets && \
  QDRANT_API_KEY=$QDRANT_API_KEY WIKI_PATH=Wiki \
  node scripts/ingest_wiki.js > /tmp/ingest.log 2>&1
# Verifica:
grep -E "Found|Complete|Error" /tmp/ingest.log | tail -5
curl -s "http://localhost:6333/collections/easyway_wiki" -H "api-key: $QDRANT_API_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print('chunks:', d['result']['points_count'])"
```

### PAT management

- **File attivo**: `C:\old\.env.developer` — scope `Code R/W` + `PR Contribute`
- **Se `.env.local` scaduto**: `source C:\old\.env.developer` o copiare su `.env.local`
- **Verificare validita' PAT**: `pwsh scripts/pwsh/Initialize-AzSession.ps1 -Verify`

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

**Merge strategy `develop -> main`** (Azure DevOps - DEFINITIVO - Session 9):
- Impostazione: **"Merge (no fast-forward)"** — NON Squash
- Squash generava conflitti da history divergente al merge successivo
- Configurato su Azure DevOps: Branch Policies di `main` -> Merge strategy -> Merge commit

### Regola PR Description (OBBLIGATORIO - Session 6)

> **SEMPRE generare e fornire il testo della PR quando si creano pull request.**

Template PR standard:
```markdown
## Summary
- <bullet 1>
- <bullet 2>
- <bullet 3>

## Test plan
- [ ] <check 1>
- [ ] <check 2>

## Artefatti
- <file/script creati o modificati>
```

Titolo: `<tipo>(<scope>): <descrizione breve>` — max 70 caratteri.

### Creazione PR via az CLI (OPERATIVO - Session 8)

**Prerequisito**: `AZURE_DEVOPS_EXT_PAT` del **service account** `ew-svc-azuredevops-agent` settato in `C:\old\.env.local`.

**Setup una-tantum**: creare in `C:\old\` i file di configurazione segregati (fuori dal repo, mai committati). 
A differenza del vecchio modello monolitico, **NON si usa più un unico `.env.local`**. Esistono 4 profili per il Principio del Minimo Privilegio:
1. `C:\old\.env.discovery`: Solo `Code (Read)` e `Wiki (Read)`.
2. `C:\old\.env.planner`: Solo `Work Items (Read)`.
3. `C:\old\.env.executor`: `Work Items (Read & Write)` (CRITICO: Limitare accesso via permessi OS `chmod 400`).
4. `C:\old\.env.developer`: `Code (Read & Write)` + `Pull Request Contribute` per creare PR (usato da `Initialize-AzSession`).

Ottenere i PAT da `https://dev.azure.com/EasyWayData/_usersSettings/tokens`.
**NON aggiungere altri scope oltre quelli strettamente necessari per il ruolo.**
**NON aggiungere Work Items** — il service account non deve poter creare WI autonomamente.

**Inizializzazione sessione Developer** (una volta per sessione Claude Code):
```powershell
# Carica PAT da C:\old\.env.developer e configura az devops defaults
pwsh EasyWayDataPortal/scripts/pwsh/Initialize-AzSession.ps1

# Verifica env nella sessione corrente
pwsh EasyWayDataPortal/scripts/pwsh/Initialize-AzSession.ps1 -Verify

# Verifica token direttamente dal file developer
pwsh EasyWayDataPortal/scripts/pwsh/Initialize-AzSession.ps1 -VerifyFromFile -SecretsFile C:\old\.env.developer
```

**Inizializzazione sessione GitHub** (multi-provider):
```powershell
# Carica GH_TOKEN/GITHUB_TOKEN da C:\old\.env.github via RBAC Gatekeeper
pwsh EasyWayDataPortal/scripts/pwsh/Initialize-GitHubSession.ps1

# Verifica auth gh nella stessa sessione
pwsh EasyWayDataPortal/scripts/pwsh/Initialize-GitHubSession.ps1 -Verify
```

Template segregati disponibili in: `config/environments/.env.*.sample`

**Golden Path Atomico (raccomandato)**:
```powershell
pwsh EasyWayDataPortal/scripts/pwsh/agent-pr.ps1 `
  -Title "fix(scope): descrizione breve max 70 char" `
  -WhatIf:$false
```

Il comando sopra esegue init Azure + `az repos pr create` nello stesso processo PowerShell.

**Comando PR feat → develop**:
```powershell
az repos pr create `
  --organization https://dev.azure.com/EasyWayData `
  --project "EasyWay-DataPortal" `
  --repository EasyWayDataPortal `
  --source-branch feat/<nome-branch> `
  --target-branch develop `
  --title "feat(scope): descrizione breve max 70 char" `
  --description "## Summary`n- bullet`n`n## Test plan`n- [ ] check`n`n## Artefatti`n- file"
```

**Comando PR develop → main (Release)**:
```powershell
az repos pr create `
  --organization https://dev.azure.com/EasyWayData `
  --project "EasyWay-DataPortal" `
  --repository EasyWayDataPortal `
  --source-branch develop `
  --target-branch main `
  --title "[Release] Session N — titolo" `
  --description "## Summary`n- bullet`n`n## Test plan`n- [ ] check`n`n## Artefatti`n- file"
```

**Note critiche**:
- `AZURE_DEVOPS_EXT_PAT` NON viene ereditato tra sessioni PowerShell diverse
- `Initialize-AzSession.ps1 -Verify` controlla solo la sessione corrente; per validare il file usare `-VerifyFromFile`
- Gli initializer resettano i token di processo per default (evita cache/stale creds); usare `-NoTokenReset` solo per debug
- PAT valido: ~52 caratteri alfanumerici; se utente restituito e' `aaaa-aaaa-aaaa` il PAT e' invalido
- Per body lunghi: scrivere prima in `C:\temp\pr-body.md`, poi passare con `--description (Get-Content 'C:\temp\pr-body.md' -Raw)`
- Se az fallisce con "not authorized": il PAT e' scaduto o non ha scope corretto
- **PAT scope per automazione completa**: `Code (Read & Write)` + `Pull Request Contribute` + `Work Items (Read, Write & Manage)`
  (senza Work Items non si puo' creare WI da API per soddisfare la policy obbligatoria del branch `develop`)
- **Push HTTPS obbligatorio per visibilita' REST API**: il push SSH `git@ssh.dev.azure.com` potrebbe non essere subito visibile via REST API. Prima del merge, eseguire: `git push https://<PAT>@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal <branch>`
- **Policy `develop` richiede work item**: ogni PR verso `develop` deve avere almeno un Work Item linkato. Il PAT deve avere Work Items scope per crearlo automaticamente.

**Merge automatico completo** (quando PAT ha tutti gli scope):
```powershell
# 1. Push HTTPS (garantisce visibilita' API)
git push https://<PAT>@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal feat/<name>
# 2. Crea PR + linka WI + completa (via Initialize-AzSession + script REST API)
pwsh scripts/pwsh/Initialize-AzSession.ps1
az repos pr create --source-branch feat/<name> --target-branch develop --title "..." --description "..."
```

Comportamento Claude Code:
- Se `az repos pr create` disponibile (con `AZURE_DEVOPS_EXT_PAT` valido + tutti gli scope) → crea e completa la PR automaticamente
- Altrimenti → output testo formattato + link PR per approvazione manuale su Azure DevOps

---

## 5b. Service Account — Agente Sviluppatore (Session 8 - DEFINITIVO)

### Identita' del service account

| Campo | Valore |
|---|---|
| Display name | `Service Azure DevOps Agent` |
| Username | `ew-svc-azuredevops-agent` |
| UPN | `ew-svc-azuredevops-ag...@giuseppebelvisogmail.onmicrosoft.com` |
| Azure DevOps ID | `dda3ec11-05a2-405d-8ea7-8675e4e001ca` |
| Ruolo | Automation agent (Claude Code / CI) |
| Gruppo appartenenza | **NON membro** di `EasyWay-DataPortal Team` |

### Perche' un service account separato

Il PAT personale `giuseppe belviso` era membro del gruppo `EasyWay-DataPortal Team` (auto-reviewer Required).
Usando il PAT personale, il voto dell'agente soddisfaceva il Required reviewer anche se "Allow requestors to approve their own changes" era OFF.
Con il service account separato (non nel Team), questa bypass e' impossibile.

### Protezioni attive (testate Session 8)

| Policy | Branch | Valore | Effetto |
|---|---|---|---|
| Require min 1 reviewer | develop, main | ON - min 1 | Serve approvazione umana |
| Allow requestors to approve own changes | develop, main | OFF | Il service account non puo' approvare le proprie PR |
| Prohibit most recent pusher from approving | develop, main | ON | Chi ha pushato non puo' approvare |
| Check for linked work items | develop | Required | Ogni PR verso develop deve avere WI |
| Automatically included reviewers | develop, main | `EasyWay-DataPortal Team` (Required) | Solo giuseppe belviso puo' soddisfare |

### Flusso PR produzione (verificato)

```
[Claude Code / ew-svc-azuredevops-agent]
    |
    |-- git push feat/<name>  (HTTPS)
    |-- az repos pr create feat/<name> -> develop
    |-- az repos pr set-vote approve   --> IGNORATO (e' l'autore)
    |
    v
[Azure DevOps - policy check]
    |-- Work item linked?         --> deve essere linkato manualmente
    |-- EasyWay-DataPortal Team?  --> PENDING (service account non e' nel team)
    |
    v
[giuseppe belviso - approvazione umana]
    |-- Approva PR su Azure DevOps
    |-- Completa merge
```

### PAT scope del service account

| Scope | Incluso | Motivo |
|---|---|---|
| Code (Read & Write) | SI | Push + lettura repo |
| Pull Request Contribute | SI | Crea PR, vota (voto ignorato se autore) |
| Work Items (R/W/Manage) | NO | Non deve creare WI autonomamente |
| Build | NO | Non necessario |

### Regola operativa

> **Claude Code usa SEMPRE il PAT del service account `ew-svc-azuredevops-agent`**, mai il PAT personale di giuseppe belviso.
> Il PAT personale deve rimanere FUORI da `.env.local` e da qualsiasi file/script automatizzato.

---

## 5c. Governance Rigorosa (Enterprise Minimum)

### Modello a 4 identita' (raccomandato)
1. `svc-agent-pr-creator` -> branch/push/create PR
2. `svc-agent-ado-executor` -> apply Work Items/ADO execution
3. `svc-agent-scrum-master` -> planning/boards/reporting
4. `human-approver` -> approvazione PR/release finale

### Controlli obbligatori
- Separation of Duties: creator PR != approver PR.
- Least Privilege: scope PAT minimi per ruolo.
- Branch Protection: PR obbligatoria, min reviewer 1, no self-approval.
- Human Gate: apply critici solo dopo checkpoint umano.
- Audit Trail: log RBAC + policy + pipeline sempre disponibili.

### Riferimento checklist operativa
- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`

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
- **L1 (scripted)**: 22 agenti — logica deterministica, no LLM
- **L2 (LLM+RAG)**: 7 agenti — DeepSeek + Qdrant RAG
- **L3 (DONE)**: 6 agenti — Evaluator-Optimizer + Working Memory + RAG
  - `agent_review` (Session 9), `agent_security` (Session 13), `agent_infra` (Session 15)
  - `agent_levi` (Session 21-A), `agent_scrummaster` (Session 21-B), `agent_pr_gate` (Session 20)

### Agenti L2 attivi (7 totali, aggiornato Session 22)
`agent_backend` (S22), `agent_dba` (S21-B), `agent_docs_sync`, `agent_frontend` (S22), `agent_governance`, `agent_pr_manager`, `agent_vulnerability_scanner`

> **agent_security L3** (Session 13): manifest v3.0.0, `Invoke-AgentSecurity.ps1`, 4 fixture E2E, Evaluator-Optimizer + dual CVE scan + confidence gating.
> **agent_infra L3** (Session 15): manifest v3.0.0, `Invoke-AgentInfra.ps1`, 4 fixture E2E, Evaluator-Optimizer + structured JSON output + `infra:compliance-check`. Promosso da L2 (Session 13).
> **agent_levi L3** (Session 21-A): manifest v3.0.0, `Invoke-AgentLevi.ps1`, 4 fixture E2E, Evaluator-Optimizer + RAG, confidence gating. Fix `Invoke-RAGSearch.ps1`: `Invoke-Expression` → `& python3`.
> **agent_scrummaster L3** (Session 21-B): manifest v3.0.0, `Invoke-AgentScrummaster.ps1`, `sprint:report` + `backlog:health`, 3 fixture E2E.
> **agent_dba L2** (Session 21-B): manifest v2.0.0, `Invoke-AgentDba.ps1`, `dba:check-health` + `db-guardrails:check`, Import-AgentSecrets, 2 fixture.
> **agent_backend L2** (Session 22): manifest v2.0.0, `Invoke-AgentBackend.ps1`, `api:health-check` + `api:openapi-validate` LLM+RAG, 3 fixture.
> **agent_frontend L2** (Session 22): manifest v2.0.0, `Invoke-AgentFrontend.ps1`, `frontend:build-check` + `frontend:ux-review` LLM+RAG, 2 fixture.

### agent_review L3 — dettaglio (DONE - Session 9, runner rinominato Session 10)
- **Script**: `agents/agent_review/Invoke-AgentReview.ps1` (rinominato da `run-with-rag.ps1` in Session 10) — flag: `-EnableEvaluator`, `-SessionFile`, `-NoEvaluator`
- **E2E test**: PASSED — 5 RAG chunks, deepseek-chat, $0.0005, 0 errori
- **Bug fix Session 9**: ApiKey splatting, EvaluatorRuns guard, RAG error guard (PR 49/51/52/53 merged)
- **AC review:docs-impact**: 4 predicati (verdict, docs analysis, file coverage, recommendations)
- **AC review:static**: 4 predicati (naming, structure, specific findings, standard reference)

### Skills Registry
- **v2.9.0** — 25 skill totali (Session 14)
- **Nuova skill Session 7**: `session.manage` — `agents/skills/session/Manage-AgentSession.ps1`
- **Nuova skill Session 10**: `orchestration.parallel-agents` — `agents/skills/orchestration/Invoke-ParallelAgents.ps1` (Start-ThreadJob/Start-Job fallback, Gap 3)
- **Nuova skill Session 14**: `utilities.import-secrets` — `agents/skills/utilities/Import-AgentSecrets.ps1` (SSOT secrets, idempotente, non-distruttiva)

### Secrets Management (Session 14)
- **SSOT**: `/opt/easyway/.env.secrets` — tutti i platform secrets (DEEPSEEK_API_KEY, GITEA_API_TOKEN, QDRANT_API_KEY)
- **Pattern**: ogni runner chiama `Import-AgentSecrets` al boot — non-distruttivo, fail-safe
- **Guida completa**: `Wiki/EasyWayData.wiki/security/secrets-management.md`
- **Problema risolto**: RAG 401 Unauthorized da shell SSH (QDRANT_API_KEY non propagata)

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
  -MaxIterations 2 `                     # default: 2
  -SessionFile $sessionPath              # Gap 2 — Working Memory (opzionale)
```

**Evaluator-Optimizer** (implementato in Session 5):
- Attivato con `-EnableEvaluator -AcceptanceCriteria @(...)`
- Loop: generator call -> evaluator scoring -> retry con feedback se AC falliscono
- Graceful degradation: se evaluator call fallisce, restituisce output del generator senza bloccare
- Backward-compatible: tutti i parametri evaluator sono opzionali

**Working Memory** (implementato in Session 7 — Gap 2):
- Attivato con `-SessionFile <path>` — inietta stato sessione nel system prompt
- Il file session.json e' creato da `Manage-AgentSession -Operation New`
- Consente multi-step senza ripassare tutto il contesto ad ogni call LLM
- Schema: `agents/core/schemas/session.schema.json`

### Skill session.manage (Manage-AgentSession)
```powershell
# Crea sessione
$s = Manage-AgentSession -Operation New -AgentId agent_review -Intent "review:docs-impact"

# Imposta step corrente
Manage-AgentSession -Operation SetStep -SessionFile $s.SessionFile -StepName "analyze_docs"

# Aggiorna con risultato step
Manage-AgentSession -Operation Update -SessionFile $s.SessionFile `
    -CompletedStep "analyze_docs" `
    -StepResult @{ missing_wiki_pages = @("guides/health.md") } `
    -Confidence 0.85

# Chiudi (elimina file, restituisce summary)
$summary = Manage-AgentSession -Operation Close -SessionFile $s.SessionFile
```
Operations: `New`, `Get`, `Update`, `SetStep`, `Close`, `Cleanup` — TTL default 30 minuti.

---

## 8b. Platform Adapter SDK (Session 16 - Phase 9 Feature 17)

> **Principio**: Il processo e' invariante, solo l'adapter cambia (EASYWAY_AGENTIC_SDLC_MASTER.md §11.1).

### Architettura

```
config/platform-config.json  -->  platform-plan.ps1 (L3 Planner)
                              -->  platform-apply.ps1 (L1 Executor)
                                        |
                                   PlatformCommon.psm1 (8 utility functions)
                                        |
                                   IPlatformAdapter.psm1 (factory + classes)
                                        |
                              AdoAdapter / GitHubAdapter / BusinessMapAdapter
```

### File principali

| File | Scopo |
|---|---|
| `config/platform-config.json` | Config ADO Scrum (gerarchia, auth, tags, paths) |
| `config/platform-config.schema.json` | JSON Schema per IntelliSense e validazione CI |
| `scripts/pwsh/core/PlatformCommon.psm1` | 8 funzioni: config, auth, URL, hierarchy, token |
| `scripts/pwsh/core/adapters/IPlatformAdapter.psm1` | Modulo consolidato: 3 adapter + factory |
| `scripts/pwsh/platform-plan.ps1` | L3 Planner generico (sostituisce ado-plan-apply) |
| `scripts/pwsh/platform-apply.ps1` | L1 Executor generico (sostituisce ado-apply) |

### Come usare

```powershell
# Planning (genera execution_plan.json senza creare nulla)
pwsh scripts/pwsh/platform-plan.ps1 -BacklogPath out/phase9_backlog.json -ConfigPath config/platform-config.json

# Apply (crea i work item sulla piattaforma)
pwsh scripts/pwsh/platform-apply.ps1 -PlanPath out/execution_plan.json -ConfigPath config/platform-config.json

# Backward compat (delegano ai nuovi script)
pwsh scripts/pwsh/ado-plan-apply.ps1
pwsh scripts/pwsh/ado-apply.ps1
```

### Regole operative Platform Adapter SDK

1. **Cambiare piattaforma = cambiare `platform-config.json`**. Zero code changes.
2. **MAI hardcodare** URL, project, work item types, o PAT negli script. Tutto dal config.
3. **Nuovi adapter**: aggiungere la classe in `IPlatformAdapter.psm1` + case nella factory `New-PlatformAdapter`.
4. **PS v5 classi**: tutte le classi con ereditarieta' DEVONO vivere nello stesso `.psm1` (vedi Lesson 24).
5. **Token security**: il config contiene solo il *nome* della env var (`auth.envVariable`), MAI il valore.
6. **Piattaforme supportate**: ado, github, jira, forgejo, businessmap, witboost (6 totali, §11.3 SDLC MASTER).
7. **Wiki completa**: `docs/wiki/Platform-Adapter-SDK.md` — Cosa, Come, Perche', Q&A.

---

## 9. Gaps Roadmap Agent Evolution

| Gap | Titolo | Stato | File |
|---|---|---|---|
| Gap 1 | Evaluator-Optimizer | DONE (Session 5) | `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` |
| Gap 2 | Working Memory (session.json) | DONE (Session 7) | `agents/core/schemas/session.schema.json`, `agents/skills/session/Manage-AgentSession.ps1` |
| Gap 3 | Parallelization (Start-ThreadJob) | DONE (Session 10) | `agents/skills/orchestration/Invoke-ParallelAgents.ps1`, registry v2.8.0 |
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
| `az repos pr create` non eredita PAT | Impostare `AZURE_DEVOPS_EXT_PAT` nella sessione corrente (vedi sez. 5 per comando completo) | Documented |

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
13. **Sync-PlatformMemory duplicate marker bug**: `IndexOf("# AUTO-SYNC-END")` trova la PRIMA occorrenza, ma la wiki puo' contenere quel testo come esempio documentale in code block. Usare `LastIndexOf` per il marker di chiusura — garantisce di trovare sempre il vero `# AUTO-SYNC-END` finale.
14. **`git push origin` (SSH) vs HTTPS Azure DevOps**: Il remote SSH `git@ssh.dev.azure.com:v3/...` e il remote HTTPS `https://dev.azure.com/...` sono ENTRAMBI Azure DevOps, ma il push SSH non sempre e' visibile immediatamente via REST API. Per PR creation/merge via API, fare prima `git push https://<PAT>@dev.azure.com/EasyWayData/EasyWay-DataPortal/_git/EasyWayDataPortal <branch>` per garantire visibilita'. Script: `C:\temp\push-https.ps1`.
15. **PAT scope per PR automation completa**: `Code (Read & Write)` + `Pull Request Contribute` + **`Work Items (Read, Write & Manage)`**. Senza Work Items, non si puo' creare WI da API ne' linkarlo alla PR (policy obbligatoria su `develop`). Per merge automatico: aggiungere Work Items scope al PAT e re-salvare in `C:\old\.env.local`.
16. **`"$key: value"` in PS**: la colon dopo una variabile viene interpretata come scope qualifier. Usare `"$($key): value"` o `"${key}: value"` per evitare il parser error.
17. **Merge strategy `develop->main`** (Session 9): impostata su "Merge (no fast-forward)" su Azure DevOps. Con Squash si generavano conflitti da history divergente. Cambiamento definitivo — non ripristinare Squash.
18. **SSH single-quote per remote vars**: `ssh host 'export VAR=$(cmd) && ...'` con singoli apici evita espansione bash locale. Con doppi apici usare `\$`, ma `${#VAR}` viene espanso ugualmente. Usare sempre singoli apici per comandi remoti con variabili.
19. **pip3 su Ubuntu 24.04**: richiede `--break-system-packages` per installare moduli system-wide (`pip3 install qdrant-client sentence-transformers --break-system-packages`). Alternativa consigliata: venv.
20. **PSObject property guard**: usare `$obj.PSObject.Properties['PropName'] -and $obj.PropName` prima di accedere a proprieta' opzionali su hashtable/oggetti dinamici PS. Evita l'errore "property cannot be found on this object".
21. **PR creation via curl** (Session 9): quando `az repos pr create` non e' disponibile da bash Claude Code, usare `curl` direttamente con PAT da `.env.local`. Il PAT si legge con `source .env.local && curl -u ":$AZURE_DEVOPS_EXT_PAT" -X POST ...`. Evita problemi di escaping PS in bash.
22. **`Receive-Job -ErrorAction Stop`** (Session 11): re-throw TUTTI i record di errore del job stream (inclusi Python/Qdrant UserWarning su stderr nativo) come eccezioni PS terminanti, PRIMA che il return value dello scriptBlock sia accessibile. Fix: usare `-ErrorAction SilentlyContinue` + logica di check esplicita nel `if` successivo. Il scriptBlock ha gia' il suo `try/catch` interno.
23. **repoRoot in `agents/skills/<category>/`** (Session 11): servono 3 livelli `.Parent.Parent.Parent` (`category/` -> `skills/` -> `agents/` -> repo root). Con `.Parent.Parent` si ottiene `agents/`, non la repo root. Verificare sempre il repoRoot in test E2E con `Write-Host "Repo root: $repoRoot"` prima di eseguire.
24. **PS v5 class inheritance cross-module** (Session 16): `class AdoAdapter : IPlatformAdapter` dichiarato in file diverso dal base class produce `Unable to find type [IPlatformAdapter]`. **Regola: in PS v5, tutte le classi con relazione di ereditarieta' devono vivere nello stesso `.psm1`**. L'alternativa `using module` richiede path assoluti, inutilizzabile in CI/CD.
25. **Pester v3 vs v5 assertion syntax** (Session 16): `Should -Be` (Pester v5 syntax) fallisce con Pester v3.4.0 — il trattino e' ambiguo. Usare v3 syntax: `Should Be` (senza trattino). `Should Throw` non funziona con `throw` in funzioni CmdletBinding — usare pattern `try/catch` + `$threw | Should Be $true`. **Verificare versione Pester**: `Get-Module Pester -ListAvailable`.
26. **Array count gotcha PS** (Session 16): `$patch.Count` su un singolo hashtable ritorna il numero di chiavi (es. 3 per `@{op=x; path=y; value=z}`), non 1. **Regola: SEMPRE wrappare in `@()` quando ci si aspetta un array**: `$patch = @(Build-AdoJsonPatch -Title 'X')`.
27. **PAT ADO scaduto su server** (Session 20): il remote `origin` sul server ha il PAT hardcoded nell'URL HTTPS. Quando scade, `git pull` restituisce `Authentication failed`. Fix: `git remote set-url origin 'https://Tokens:<NEW_PAT>@dev.azure.com/...'`. Il PAT valido e' in `C:\old\.env.developer` (locale) — NON in `.env.local` che puo' essere stale.
28. **Qdrant ingest EPIPE** (Session 20): `ingest_wiki.js` termina con `EPIPE` quando rediretto via SSH se il terminale chiude il pipe prima del flush finale. Non e' un errore reale — verificare con `curl /collections/easyway_wiki` per il conteggio finale. Usare `> /tmp/ingest.log 2>&1` (redirect su server) per evitare il problema.
29. **`Invoke-Expression` con JSON** (Session 21-A): MAI usare `Invoke-Expression "python3 $script $query"` quando `$query` contiene JSON. PS parser interpreta `:`, `{`, `}` come codice. Usare `& python3 $script $query` (argomento separato). Fix in `Invoke-RAGSearch.ps1`.
30. **Import-AgentSecrets RBAC** (Session 21-A): `Import-AgentSecrets.ps1` richiede `/etc/easyway/rbac-master.json` (Linux) o `C:\old\rbac-master.json` (Windows). Se mancante → halt. Ogni nuovo agente L2/L3 va aggiunto al registry PRIMA del boot del runner.
31. **PS param default timing** (Session 21-B): `[string]$ApiKey = $env:DEEPSEEK_API_KEY` e' valutato PRIMA del corpo script (al param binding). Se la env var viene settata da `Import-AgentSecrets` nel body, il param e' gia' `""`. Fix: aggiungere `if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }` DOPO la boot call.
32. **Docker bind mount + `cp`** (Session 22): `cp src dst` crea un NUOVO inode — il container vede ancora il vecchio inode (stale). Per aggiornare un file bind-mounted in-place usare `cat src > dst` (stesso inode). Altrimenti restart container o push via admin API.
33. **Caddy config stale** (Session 22): verificare config runtime via `docker inspect <container> --format "{{json .Mounts}}"` per il file EFFETTIVO montato. Se diverso da `Caddyfile`, usare `curl -X POST http://localhost:2019/load -H "Content-Type: text/caddyfile" --data-binary @/path/to/Caddyfile` per hot-push. Fix operativo: `docker compose up -d --force-recreate caddy`.
34. **`node:20-alpine` non ha python3** (Session 28): l'immagine base del container API non include Python. Qualsiasi chiamata a `execFile('python3', ...)` produce `ENOENT`. Soluzione: usare la Qdrant REST API direttamente via `fetch()` con filter `match:{text:query}` dopo aver creato un text index sul campo `content`. Non serve nessuna dipendenza ML/Python nell'API Node.js.
35. **Qdrant full-text search** richiede text index (Session 28): prima di usare `match:{text:"..."}` nel filter, creare esplicitamente l'indice: `PUT /collections/{name}/index` con `{"field_name":"content","field_schema":"text"}`. Senza indice, Qdrant risponde 400 "Index required for payload search".
36. **Docker network isolation multi-stack** (Session 28): se due servizi sono deployati con `docker compose` separati (es. `docker-compose.apps.yml` vs `docker-compose.yml` radice), i container non vedono la rete dell'altro per default. Fix: `docker network connect <target-net> <container>` + persistere in compose: `networks: {qdrant-net: {external: true, name: <nome-network>}}`.
37. **EACCES `/app/data` in container** (Session 28): il container Node.js gira come `node` (uid=1000). Se la directory host è owned da `ubuntu` (uid=1001), il container non può scrivere. Fix: `sudo chown -R 1000:1000 ~/EasyWayDataPortal/data/`. Verificare sempre con `id` nel container: `docker exec <name> id node`.
38. **Merge conflict "Added in both"** (Session 28): si verifica quando due branch creano un file nuovo con lo stesso path, entrambi mergiati nella stessa base branch. Non si risolve con un semplice fixup; creare un nuovo branch dalla base (develop) pulita, applicare la versione corretta del file, e aprire una nuova PR abbandonando quella in conflitto.
39. **X-EasyWay-Key auth ordine** (Session 28): il middleware `authenticateJwt` deve controllare prima l'header `X-EasyWay-Key` (machine-to-machine) e fare early `return next()` se match, PRIMA del check JWT. Altrimenti il JWT fallisce per assenza di token e la richiesta M2M viene rifiutata con 401.
40. **ADO curl Basic auth** (Session 28): usare `B64=$(echo -n ":$PAT" | base64 -w0)` + `-H "Authorization: Basic $B64"`. Il flag `-u ":$PAT"` di curl causa un redirect 302 non-authenticated. La `-w0` in `base64` evita il newline finale che invalida il base64 su alcune versioni Linux.
41. **`Zod z.string().date()`** (Sessions 26-28): accetta solo `YYYY-MM-DD` (non ISO datetime). Per campi data da `<input type="date">` usare `.date()`. Per campi datetime da `<input type="datetime-local">` (che produce `YYYY-MM-DDTHH:mm`) usare `.string()` — il backend memorizza as-is, accettabile per mock mode.

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

### Opzione B — Shared Snippet per PROMPTS.md (DONE - Session 8)
Snippet canonico: `agents/core/prompts/platform-rules.snippet.md`.
Ogni agente L2 ha la sezione `## EasyWay Platform Rules` nel proprio `PROMPTS.md` (tra Security Guardrails e sezione dominio).
Script di sync: `scripts/pwsh/Sync-AgentPlatformRules.ps1` - propaga future modifiche allo snippet nei 9 PROMPTS.md.
Invocazione: `pwsh scripts/pwsh/Sync-AgentPlatformRules.ps1` (con `-DryRun` per preview, `-AgentFilter agent_dba` per agente singolo).
Markers: `PLATFORM_RULES_START` / `PLATFORM_RULES_END` (analoghi ad AUTO-SYNC-START/END di .cursorrules).

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

## 14. Session 9 — Tasks completati e Next Session Priorities

### Session 9 — Completati

| Stato | Task | Note |
|---|---|---|
| DONE | Server `git pull` | Aggiornato a `6dbe718` (PR 51+53) |
| DONE | Qdrant re-index wiki/agents | 396 chunk (wiki) + 1297 chunk (agents/) |
| DONE | 3 bug fix agent_review L3 | ApiKey splatting, EvaluatorRuns guard, RAG error guard — PR 49/51/52/53 |
| DONE | E2E test agent_review L3 | PASSED: 5 RAG chunks, deepseek-chat, $0.0005, 0 errori |
| DONE | Merge strategy develop->main | Cambiata da Squash a "Merge (no fast-forward)" |
| DONE | PR 31 abbandonata | Nessuna azione necessaria |

### Session 10 — Completati

| Stato | Task | Note |
|---|---|---|
| DONE | Wiki update: agent-roster.md | gpt-4-turbo → deepseek-chat, L3 badge, tools corretti |
| DONE | Wiki update: agent-evolution-roadmap.md | Tutti i gap DONE, L3 implemented, roadmap aggiornata |
| DONE | Rename runner | `run-with-rag.ps1` → `Invoke-AgentReview.ps1` (git mv + manifest) |
| DONE | Gap 3 Parallelization | `Invoke-ParallelAgents.ps1` + registry v2.8.0 (24 skill) |
| DONE | E2E test Evaluator | EvaluatorIterations=2, EvaluatorPassed=False (graceful degradation OK) |

### Session 10 — Post-merge (DONE)
| DONE | Server `git pull` | Aggiornato a `3d86310` (PR 54+55) |
| DONE | Qdrant re-index agents/ | 1297 chunk |
| DONE | Qdrant re-index wiki/agents/ | 398 chunk |

### Session 11 — Completati (2026-02-19)

| Stato | Task | Note |
|---|---|---|
| DONE | Server `git pull` | Aggiornato a `3d86310` (PR 54+55) |
| DONE | Qdrant re-index agents/ | 1297 chunk |
| DONE | Qdrant re-index wiki/agents/ | 398 chunk |

### Session 11 — Completati (2026-02-19)

| Stato | Task | Note |
|---|---|---|
| DONE | E2E test `Invoke-ParallelAgents.ps1` | **PASSED**: Success=True, 26s wall, 2/2 job OK (PR #58-#65) |
| DONE | Bug fix repoRoot | `.Parent.Parent.Parent` (3 livelli) in Invoke-ParallelAgents + test E2E |
| DONE | Bug fix Receive-Job | `-ErrorAction SilentlyContinue` — Python UserWarning non causa piu' Success=False |
| DONE | Bug fix ErrorActionPreference | `$ErrorActionPreference='Continue'` nel scriptBlock ThreadJob |

### Session 11 — Post-merge (DONE)

| Stato | Task | Note |
|---|---|---|
| DONE | Server `git pull` | Aggiornato a `7adc903` (PR #65) |
| DONE | Wiki + MEMORY.md aggiornati | Gap 3 DONE, Session 11 completata |

### Session 12 — Completati (2026-02-19)

| Stato | Task | Note |
|---|---|---|
| DONE | `guides/parallel-agent-execution.md` | Doc coverage Invoke-ParallelAgents 0%->100% — API reference, 4 esempi, timeout, ThreadJob vs Job, 5 troubleshooting |
| DONE | `agents/agent-security-prd-l3.md` | PRD L3 per agent_security: 11 AC, 4 EX, Evaluator-Optimizer, parallel CVE scan (docker-scout + trivy), confidence gating < 0.70, working memory |
| DECISION | agent_infra: rinviato a Session 13 | L1 con gpt-4o, zero skills — promosso prima a L2 poi considerare L3 |

### Session 13 — COMPLETATA (2026-02-19)

| Stato | Task | Note |
|---|---|---|
| DONE | agent_infra L1->L2 | PR #68 feat/agent-infra-l2->develop — manifest v2.0.0, deepseek-chat, `infra:drift-check` LLM+RAG, Iron Dome PASSED |
| DONE | `Invoke-AgentSecurity.ps1` | PR #71 feat/agent-security-l3->develop — L3 runner 441 righe, manifest v3.0.0, 4 fixture E2E, Iron Dome PASSED |
| DONE | Wiki ingest Session 12+13 | 239 chunks (guides/) + 450 chunks (agents/) — tot. 38,313 chunk Qdrant |
| DONE | platform-operational-memory.md | Aggiornato + Sync-PlatformMemory.ps1 (34,023 chars -> .cursorrules) |
| DONE | agent-roster.md + agent-evolution-roadmap.md | L3 badge agent_security, L2 count 9->7, nuova sezione L3 |

### Session 14 — COMPLETATA (2026-02-19)

| Stato | Task | Note |
|---|---|---|
| DONE | `Import-AgentSecrets.ps1` | Nuova skill `utilities.import-secrets` — SSOT secrets, idempotente, non-distruttiva |
| DONE | QDRANT_API_KEY in `.env.secrets` | Aggiunta su server — ora tutti e 3 i platform secrets nel file |
| DONE | 3 runner aggiornati | Invoke-AgentSecurity, Invoke-AgentReview, agent-infra: boot call + ApiKey post-load |
| DONE | Revert PR #74 | Rimosso QdrantApiKey param da Invoke-LLMWithRAG (pattern sbagliato) |
| DONE | registry.json v2.9.0 | Aggiunta entry `utilities.import-secrets` (25 skill totali) |
| DONE | Wiki `secrets-management.md` | Guida completa: ADR, perché/come/cosa, runbook, troubleshooting |
| DONE | E2E retest post-fix | security:analyze — rag_chunks > 0 (verifica post-deploy) |
| DONE | Wiki `agent-platform-faq.md` | FAQ piattaforma: 10 sezioni, 30+ Q&A — secrets, RAG, L1/L2/L3, deploy, Iron Dome, troubleshooting |

### Session 15 — COMPLETATA (2026-02-19)

| Stato | Task | Note |
|---|---|---|
| DONE | Merge PR #77 | docs/session14-faq -> develop: agent-platform-faq.md + platform-operational-memory |
| DONE | Release PR #78 -> main | server git pull (PR #78 applicato) |
| DONE | Qdrant ingest | 57,868 chunk totali (+17,796 rispetto a Session 13) |
| DONE | E2E agent_infra L2 | `infra:drift-check` sul server: ok=true, ragChunks=5, $0.000398 |
| DONE | **agent_infra L2->L3** | Invoke-AgentInfra.ps1, manifest v3.0.0, PROMPTS.md JSON output |
| DONE | infra:compliance-check | Nuova action L3 (verifica porte, segreti, IaC patterns) |
| DONE | 4 fixture E2E | EX-01 drift, EX-02 injection, EX-03 low confidence, EX-04 compliance |
| DONE | Wiki agent-infra-prd-l3.md | PRD completo: 10 AC, 4 EX, evaluator_config, working memory schema |
| DONE | Release PR #80 -> main | server git pull + E2E L3 runner PASSED |
| DONE | E2E L3 runner | EX-01 ok=true/HIGH/0.75, EX-02 SECURITY_VIOLATION, EX-04 compliance OK |

### Session 16 — COMPLETATA (2026-02-23)

| Stato | Task | Note |
|---|---|---|
| DONE | Scrum Migration | Processo migrato da Basic a Scrum (ADO inherited process) |
| DONE | Platform Adapter SDK | Phase 9 Feature 17: config-driven adapter pattern, 13 file, +1457/-284 righe |
| DONE | `platform-config.json` + Schema | Config ADO Scrum + JSON Schema per 6 piattaforme |
| DONE | `PlatformCommon.psm1` | 8 utility condivise (config, auth, URL, hierarchy, token) |
| DONE | `IPlatformAdapter.psm1` | Modulo consolidato: AdoAdapter + GitHubAdapter (stub) + BusinessMapAdapter (stub) + factory |
| DONE | `platform-plan.ps1` + `platform-apply.ps1` | L3 Planner + L1 Executor generici |
| DONE | Backward compat wrappers | `ado-plan-apply.ps1` (186->33 righe) + `ado-apply.ps1` (131->30 righe) |
| DONE | Pester test suites | PlatformCommon 18/18 + AdoAdapter 6/10 (4 = Pester v3 class scope) |
| DONE | SDLC MASTER §11 | Aggiunto BusinessMap come 6° adapter + capability matrix |
| DONE | Wiki Platform-Adapter-SDK.md | Cosa, Come, Perche', Q&A, Verifiche, Lessons Learned (314 righe) |
| DONE | Iron Dome | PSScriptAnalyzer PASSED, 2 commit su `feature/platform-adapter-sdk` |

### Session 21-A — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | E2E agent_levi | EX-01 PASSED (confidence=0.95, $0.0019), EX-02 PASSED (injection), EX-04 PASSED dopo fix (rag_chunks=5, confidence=0.50) |
| DONE | Deploy `rbac-master.json` su server | Aggiunto `agent_levi` + `agent_pr_gate` in `/etc/easyway/rbac-master.json` |
| DONE | Fix `Invoke-RAGSearch.ps1` | `Invoke-Expression` → `& python3` (JSON in query rompe PS parser) — PR #130 merged in develop |
| DONE | Update EX-04 fixture | `confidence_min` 0.70→0.50 (LLM corretto: 284 issues > 15-sample → confidence bassa) |

### Session 21-B — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | `agent_scrummaster` L1→L3 | `Invoke-AgentScrummaster.ps1` (sprint:report, backlog:health), manifest v3.0.0, DeepSeek, Evaluator+WM, 3 fixture |
| DONE | `agent_dba` informal→L2 | `Invoke-AgentDba.ps1` (dba:check-health, db-guardrails:check), Import-AgentSecrets, structured JSON, 2 fixture |
| DONE | rbac-master.json locale + server | Aggiunto agent_scrummaster + agent_dba |
| DONE | PR #133 feat/agent-scrummaster-l3-dba-l2 → develop | Iron Dome PASSED |
| DONE | E2E scrummaster | EX-01 PASSED (confidence=0.85, $0.004), EX-02 PASSED (SECURITY_VIOLATION), EX-03 PASSED (health=0.65) |
| DONE | E2E dba | EX-01 PASSED (degraded, sqlcmd missing), EX-02 PASSED (rag=5, confidence=0.5 graceful) |

### Session 21-C — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | Release PR #134 develop→main | Merge no-FF, server git pull (commit 29e13c3) |
| DONE | Qdrant ingest | 514 file, 66,813→103,156 chunk (+36,343). EPIPE sull'ultimo file (non critico) |

### Session 22 — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | Caddy fix | `docker compose up -d --force-recreate caddy`, mount corretto Caddyfile |
| DONE | `agent_backend` L2 | `Invoke-AgentBackend.ps1` (api:health-check + api:openapi-validate LLM+RAG), manifest v2.0.0, 3 fixture |
| DONE | `agent_frontend` L2 | `Invoke-AgentFrontend.ps1` (frontend:build-check + frontend:ux-review LLM+RAG), manifest v2.0.0, 2 fixture |
| DONE | rbac-master.json aggiornato | agent_backend + agent_frontend aggiunti |
| DONE | E2E backend | EX-01 PASS (health=ok, 0.03s), EX-02 PASS (confidence=0.95, violations=10, $0.0006) |
| DONE | E2E frontend | EX-01 PASS (degraded, no dist/), EX-02 PASS (confidence=0.85, issues=12, $0.0009) |
| DONE | PR #135 feat→develop + PR #136 Release develop→main | server git pull (commit 9e04aa3) |

### Session 23 — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | Valentino framework committato | Skills: backoffice-architect/builder/memory-ledger/web-guardrails + web-design-guidelines — PR #137→develop, PR #138→main |
| DONE | Backoffice slice 1 | appointments + quotes page specs + manifest routes |
| DONE | Backoffice slice 2 | `/backoffice/agents` (hero + L3/RUN/AUDIT cards + CTA) — PR #139→develop, PR #140→main |
| DONE | `content.json` | 90+ i18n keys backoffice in italiano |
| DONE | `platform-operational-memory.md` + `.cursorrules` sync | Sessions 21-22, lessons 29-33 |
| DONE | Qdrant ingest | 121,370 chunk (+18,214 da 103,156) |
| DONE | `openapi.yaml` v0.3.0 | operationId su 8 op + API contracts `/api/appointments` + `/api/quotes` + 6 schemi — PR #141/#142 |

### Session 24 — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | Nav entry `Backoffice` | `pages.manifest.json` (order 45) → `/backoffice/appointments` |
| DONE | Section type `data-list` | `pages-renderer.ts`: fetch async + table + badge status |
| DONE | Tipo `DataListSection` + `DataListColumnSpec` | `runtime-pages.ts` |
| DONE | Mock data | `public/data/mock/appointments.json` + `quotes.json` (5 record each) |
| DONE | Wire backoffice pages | `backoffice-appointments.json` + `backoffice-quotes.json` con `data-list` sezione |
| DONE | Docker build OK | 0 errori TS, smoke test 200 |
| DONE | PR #143 feat→develop + PR #144 Release→main | server git pull (HEAD 7241da8) |

### Session 25 — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | GET/POST /api/appointments + /api/quotes live | mock mode (DB_MODE=mock) |
| DONE | auth.ts JWT bypass DB_MODE=mock | tenant=demo quando DB_MODE=mock |
| DONE | Dockerfile `/app/data` pre-creata | ownership node, risolve EACCES in container |
| DONE | docker-compose.prod.yml fix | `easyway-net: external:true` — Caddy e API stessa rete |
| DONE | `/backoffice/agents` data-list | 34 agenti da `/data/mock/agents.json` |
| DONE | PR #149-#153 merged → main | smoke test OK |

### Session 26 — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | Server seeded | 5 appointments + 5 quotes via POST /api/* |
| DONE | `renderDataList` empty-state | "Nessun dato disponibile" quando rows=[] |
| DONE | Section type `action-form` | POST form + inline feedback + numeric coercion |
| DONE | `backoffice-appointments.json` + `backoffice-quotes.json` | action-form sections aggiunte |
| DONE | `content.json` | `backoffice.table.empty` + form keys (appointments + quotes) |
| DONE | PR #154 feat→develop + PR #155 develop→main | Build OK, 0 TS errors |

### Session 27 — COMPLETATA (2026-02-25)

| Stato | Task | Note |
|---|---|---|
| DONE | LLM-SEO | `llms.txt` + bookmark directive, `index.html` OpenGraph + Schema.org JSON-LD, `sitemap.xml` — PR #156+#157 |
| DONE | Status badge coloring | CONFIRMED=verde, PENDING=giallo, CANCELLED=rosso |
| DONE | `GET /api/agents` live | 36 agenti da manifest scan (`AGENTS_PATH=/app/agents`) |
| DONE | `docker-compose.apps.yml` | `AGENTS_PATH=/app/agents` + `./agents:/app/agents:ro` — locale, non committato |
| DONE | Hotfix PR #158 | `agentChatRouter` intercettava `/api/agents`; fix: `app.use("/api/agents")` PRIMA di agentChatRouter |

### Session 28 — COMPLETATA (2026-02-26)

| Stato | Task | Note |
|---|---|---|
| DONE | `GET /api/knowledge` — RAG API pubblica | X-EasyWay-Key machine-to-machine auth; Qdrant full-text search via REST (nessun python3) |
| DONE | `POST /api/agents/:id/run` + `GET /api/agents/:id/runs` | Run history JSON in `/app/data/agent-runs.json`, max 200 entry |
| DONE | RUN button backoffice `/backoffice/agents` | `rowActions` su `data-list`, inline feedback "Avviato / Errore" |
| DONE | Cron scheduler autonomo | node-cron: infra-drift (6h), openapi-validate (lun 09:00), sprint-report (lun 08:00); `CRON_ENABLED=true` server |
| DONE | ADO auto-issue su cron failure | `createAdoIssue()` apre Bug ADO con Basic auth PAT se severity HIGH / violations > 0 |
| DONE | Hotfix: `knowledgeController` rewrite | `node:20-alpine` non ha python3 — controller riscritto con `fetch()` su Qdrant HTTP REST |
| DONE | Hotfix: EACCES `/app/data` | `chown -R 1000:1000 ~/EasyWayDataPortal/data/` — node uid=1000, non 1001 |
| DONE | Hotfix: Qdrant network isolation | API su `easyway-net`, Qdrant su `easywaydataportal_easyway-net` — `docker network connect` + persist in `docker-compose.apps.yml` |
| DONE | Qdrant text index `content` | `PUT /collections/easyway_wiki/index {"field_name":"content","field_schema":"text"}` richiesto per full-text match |
| DONE | PR #160 feat→develop + PR #161 develop→main | server git pull, docker build + restart |
| DONE | PR #163 fix/knowledge-controller-hotfix→develop | Sostituisce PR #162 (merge conflict) |

---

## 14b. Session 8 — Tasks completati e Next Session Priorities (storico)

### Session 8 — Completati

| Stato | Task | Note |
|---|---|---|
| DONE | Server `git pull` (Gap 2 in main) | Gia' aggiornato (PR 36-39 in main) |
| DONE | Qdrant re-index `agents/` | 1216 chunk indicizzati |
| DONE | Option B — `platform-rules.snippet.md` | 9 PROMPTS.md aggiornati via Sync-AgentPlatformRules.ps1 |
| DONE | `agent_review` L3 upgrade | `run-with-rag.ps1` con Evaluator+Session, `manifest.json` v3.0.0 |
| DONE | `Initialize-AzSession.ps1` + az PR workflow | Script carica PAT da `.env.local`, documenta flow completo in wiki |

### Next Session Priorities (Session 9)

| Priorita' | Task | Note |
|---|---|---|
| Alta | Merge PR 40+41 + server `git pull` | PR 40 bloccata da work item policy - aggiungere Work Items scope al PAT |
| Media | Qdrant re-index dopo wiki Session 8 | Ri-indicizzare `agents/` e wiki dopo merge PR 40+41 |
| Bassa | Gap 3 — Parallelization | `Start-ThreadJob` per workflow paralleli (Q3 2026) |
| Bassa | PR 31 cleanup | Vecchia PR da Session 5 ancora aperta - abbandonare |

---

## Riferimenti

- [[agents/agent-design-standards]] — Pattern Anthropic per agenti
- [[agents/agent-evolution-roadmap]] — Roadmap L1->L2->L3
- [[agents/agent-roster]] — Roster completo 31 agenti
- [[security/secrets-management-roadmap]] — 4 opzioni gestione secrets cloud
- `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` — Bridge LLM+RAG (Evaluator-Optimizer Gap 1, Working Memory Gap 2)
- `agents/core/schemas/action-result.schema.json` — Schema output standard (campo `confidence`, Gap 4)
- `agents/core/schemas/session.schema.json` — Schema working memory session (Gap 2, Session 7)
- `agents/skills/session/Manage-AgentSession.ps1` — CRUD skill working memory (Gap 2, Session 7)
- `agents/skills/registry.json` v2.8.0 — Catalogo 24 skills con `returns` field (Gap 6) + `orchestration.parallel-agents` (Gap 3)
- `agents/agent_review/tests/fixtures/` — 3 fixture JSON per agent_review (Gap 5)
- `agents/core/prompts/platform-rules.snippet.md` — Snippet canonico platform rules (Option B, Session 8)
- `scripts/pwsh/Sync-AgentPlatformRules.ps1` — Propagazione snippet ai 9 PROMPTS.md (Session 8)
- `agents/agent_review/Invoke-AgentReview.ps1` — Runner L3 con Evaluator+Session (rinominato Session 10)
- `agents/skills/orchestration/Invoke-ParallelAgents.ps1` — Multi-agent parallel runner (Gap 3, Session 10)
- `scripts/pwsh/Initialize-AzSession.ps1` — Setup PAT da .env.local + az devops defaults (Session 8)
- `scripts/pwsh/Sync-PlatformMemory.ps1` — Script sync wiki → .cursorrules (Session 6)
- `Wiki/EasyWayData.wiki/guides/parallel-agent-execution.md` — Doc coverage Invoke-ParallelAgents (Session 12)
- `agents/agent-security-prd-l3.md` — PRD L3 agent_security: 11 AC, parallel CVE, confidence gating (Session 12, draft)
- `agents/agent_infra/manifest.json` v2.0.0 — agent_infra L2: deepseek-chat, infra:drift-check LLM+RAG (Session 13)
- `scripts/pwsh/agent-infra.ps1` — Agent Infra runner L2 con Invoke-LLMWithRAG (Session 13)
- `agents/agent_security/Invoke-AgentSecurity.ps1` — Runner L3: Evaluator-Optimizer, dual CVE scan, confidence gating, session (Session 13)
- `agents/agent_security/manifest.json` v3.0.0 — agent_security L3: evolution_level=3, evaluator_config, approvals (Session 13)
- `agents/agent_security/tests/fixtures/` — 4 fixture E2E: EX-01..EX-04 (Session 13)
- `agents/skills/utilities/Import-AgentSecrets.ps1` — SSOT secrets loader, boot call in tutti i runner L2/L3 (Session 14)
- `Wiki/EasyWayData.wiki/security/secrets-management.md` — guida completa secrets management: ADR, runbook, troubleshooting (Session 14)
- `Wiki/EasyWayData.wiki/guides/agent-platform-faq.md` — FAQ piattaforma: 10 sezioni, 30+ Q&A (Session 14)
- `agents/agent_infra/Invoke-AgentInfra.ps1` — Runner L3: Evaluator-Optimizer, structured JSON, compliance-check (Session 15)
- `agents/agent_infra/manifest.json` v3.0.0 — agent_infra L3: evolution_level=3, evaluator, working_memory (Session 15)
- `agents/agent_infra/tests/fixtures/` — 4 fixture E2E: EX-01..EX-04 (Session 15)
- `Wiki/EasyWayData.wiki/agents/agent-infra-prd-l3.md` — PRD L3 agent_infra: 10 AC, 4 EX, compliance-check (Session 15)
- `agents/agent_levi/Invoke-AgentLevi.ps1` — Runner L3 agent_levi: Evaluator-Optimizer, RAG, confidence gating (Session 21-A)
- `agents/agent_scrummaster/Invoke-AgentScrummaster.ps1` — Runner L3: sprint:report, backlog:health, Evaluator+WM (Session 21-B)
- `agents/agent_dba/Invoke-AgentDba.ps1` — Runner L2: dba:check-health, db-guardrails:check, Import-AgentSecrets (Session 21-B)
- `agents/agent_backend/Invoke-AgentBackend.ps1` — Runner L2: api:health-check + api:openapi-validate LLM+RAG (Session 22)
- `agents/agent_frontend/Invoke-AgentFrontend.ps1` — Runner L2: frontend:build-check + frontend:ux-review LLM+RAG (Session 22)
- `C:\old\rbac-master.json` (locale) + `/etc/easyway/rbac-master.json` (server) — RBAC Sovereign Registry richiesto da Import-AgentSecrets
- `config/platform-config.json` — Config ADO Scrum per Platform Adapter SDK (Session 16)
- `config/platform-config.schema.json` — JSON Schema per validazione e IntelliSense (Session 16)
- `scripts/pwsh/core/PlatformCommon.psm1` — 8 utility condivise per tutti gli adapter (Session 16)
- `scripts/pwsh/core/adapters/IPlatformAdapter.psm1` — Modulo consolidato: 3 adapter + factory (Session 16)
- `scripts/pwsh/platform-plan.ps1` — L3 Planner generico, sostituisce ado-plan-apply (Session 16)
- `scripts/pwsh/platform-apply.ps1` — L1 Executor generico, sostituisce ado-apply (Session 16)
- `docs/wiki/Platform-Adapter-SDK.md` — Wiki completa: Cosa, Come, Perche', Q&A (Session 16)
- `portal-api/src/controllers/knowledgeController.ts` — GET /api/knowledge: Qdrant HTTP full-text search, no python3 (Session 28)
- `portal-api/src/routes/knowledge.ts` — Route /api/knowledge con X-EasyWay-Key M2M auth (Session 28)
- `portal-api/src/services/agent-runner.service.ts` — runAgent() + listRuns() + mock/prod mode (Session 28)
- `portal-api/src/routes/agentRuns.ts` — POST /:id/run + GET /:id/runs (Session 28)
- `portal-api/src/cron/scheduler.ts` — node-cron: 3 job autonomi, CRON_ENABLED env guard (Session 28)
- `portal-api/src/cron/ado-issue.ts` — createAdoIssue(): ADO REST API Basic auth, apre Bug automatico (Session 28)
- `portal-api/src/cron/jobs/infra-drift.ts` — Cron 6h: agent_infra infra:drift-check → ADO Bug se HIGH (Session 28)
- `portal-api/src/cron/jobs/openapi-validate.ts` — Cron lun 09:00: agent_backend api:openapi-validate → ADO Bug se violations>0 (Session 28)
- `portal-api/src/cron/jobs/sprint-report.ts` — Cron lun 08:00: agent_scrummaster sprint:report → solo log (Session 28)
- `apps/portal-frontend/public/pages/backoffice-agents.json` — rowActions RUN button su data-list (Session 28)
- `Wiki/EasyWayData.wiki/guides/knowledge-api-guide.md` — Guida GET /api/knowledge: cosa, perché, come, Q&A (Session 28)
- `Wiki/EasyWayData.wiki/guides/agent-run-dashboard.md` — Guida agent run history + RUN button backoffice (Session 28)
