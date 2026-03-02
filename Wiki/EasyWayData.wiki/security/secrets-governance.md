---
title: "Secrets Governance Bible - EasyWay Agent Platform"
created: 2026-03-02
status: active
category: security
domain: governance
tags: [secrets, rbac, pat, governance, rotation, lifecycle]
priority: critical
audience: [platform-engineers, agent-developers, security-team]
---

# Secrets Governance Bible

> Documento normativo. Definisce CHI fa COSA con i secret, DOVE vivono, e COME si gestiscono.
> Nessun valore reale di secret deve MAI apparire in questo documento.

---

## 1. Identity Model

### 1.1 Service Account Matrix

| Identity | ADO Display Name | PAT Env Var | Scopo | Scope ADO |
|---|---|---|---|---|
| svc-agent-pr-creator | svc-agent-pr-creator | `ADO_PR_CREATOR_PAT` | Crea PR, posta commenti PR, push branch | Code R/W, PR Contribute |
| svc-agent-ado-executor | svc-agent-ado-executor | `AZURE_DEVOPS_EXT_PAT` | Git ops (branch, commit, fetch) | Code R/W |
| svc-agent-scrum-master | svc-agent-scrum-master | `ADO_WORKITEMS_PAT` | Crea/aggiorna PBI, User Story, Task | Work Items R/W |
| ew-svc-azuredevops-agent | ew-svc-azuredevops-agent | `SYSTEM_ACCESSTOKEN` | CI/CD pipeline agent | Pipeline-scoped |
| giuseppe belviso | giuseppe.belviso | (interattivo) | Approva PR, release, merge | Full access |

### 1.2 Separation of Duties

- L'identity che **CREA** una PR NON PUO' essere nell'approver group
- L'identity che **CREA** Work Items NON DEVE avere scope Code Write
- NESSUNA identity ha full-access scope -- privilegi minimi sempre
- L'approvazione PR e' SEMPRE umana (giuseppe belviso)

---

## 2. Script-to-PAT Matrix

### 2.1 Mapping Obbligatorio

| Script | Operazione | PAT Primario | Fallback | Stato |
|---|---|---|---|---|
| `Create-ReleasePR.ps1` | Crea Release PR | `ADO_PR_CREATOR_PAT` | `AZURE_DEVOPS_EXT_PAT` | Compliant |
| `New-PbiBranch.ps1` (PR) | Crea branch + PR | `ADO_PR_CREATOR_PAT` | `AZURE_DEVOPS_EXT_PAT` | Compliant |
| `New-PbiBranch.ps1` (WI) | Legge stato PBI | `ADO_WORKITEMS_PAT` | `AZURE_DEVOPS_EXT_PAT` | Compliant |
| `Resolve-PRConflicts.ps1` | Push + commenti PR | `ADO_PR_CREATOR_PAT` | `AZURE_DEVOPS_EXT_PAT` | Da allineare |
| `Convert-PrdToPbi.ps1` | Crea PBI su ADO | `ADO_WORKITEMS_PAT` | `AZURE_DEVOPS_EXT_PAT` | Da allineare |
| `Get-ADOBriefing.ps1` | Read-only briefing | `AZURE_DEVOPS_EXT_PAT` | -- | Compliant |
| `Invoke-ParallelAgents.ps1` | Propaga env vars | Tutti e 3 | -- | Da allineare |

### 2.2 Pattern di Fallback

Ogni script DEVE implementare il pattern:
```powershell
[string] $Pat = ($env:PAT_PRIMARIO ?? $env:AZURE_DEVOPS_EXT_PAT)
```
Con fallback da `.env.local` se env var vuota:
```powershell
$line = $lines | Where-Object { $_ -match '^PAT_PRIMARIO=' } | Select-Object -First 1
if (-not $line) {
    $line = $lines | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | Select-Object -First 1
}
```

---

## 3. Secret Storage Rules

### 3.1 Dove i Secret DEVONO Vivere

| Location | Contenuto | Accesso | Chi gestisce |
|---|---|---|---|
| `/opt/easyway/.env.secrets` | API keys piattaforma (DeepSeek, Qdrant, Gitea) | `ubuntu:ubuntu 600` sul server | Platform engineer |
| `C:\old\.env.local` | PAT sviluppatore locale (tutti e 3) | Solo macchina dev locale | Developer |
| ADO Variable Groups | CI/CD secrets (`GITHUB_PAT`) | Pipeline-scoped | ADO admin |
| n8n Credential Store | `microsoftAzureDevOpsApi`, SSH keys | n8n UI only | Platform engineer |

### 3.2 Dove i Secret NON DEVONO MAI Stare

| Location | Perche' | Severita' Violazione |
|---|---|---|
| Qualsiasi file tracciato da git | Esposto a tutti i cloner del repo (incluso GitHub mirror) | **CRITICAL** |
| `.cursorrules` | Auto-synced, inviato a LLM come contesto | **CRITICAL** |
| `MEMORY.md` (Claude memory) | Persistente, inviato a LLM come contesto | **CRITICAL** |
| `platform-operational-memory.md` | RAG-indexed, inviato a LLM tramite Qdrant | **CRITICAL** |
| Workflow n8n JSON (`agents/n8n/*.json`) | Tracciati in git come infrastruttura | **CRITICAL** |
| Docker Compose files (valori inline) | Devono usare `${VAR}` references | **HIGH** |
| Wiki pages (qualsiasi) | Searchable, indexed, RAG-accessible | **HIGH** |
| Argomenti CLI | Visibili in `ps aux` / process list | **HIGH** |

### 3.3 Pattern Sicuri nei File Tracciati

Questi pattern sono ACCETTABILI nei file git-tracked:
- `${QDRANT_API_KEY}` — variable reference Docker/bash
- `$env:ADO_PR_CREATOR_PAT` — variable reference PowerShell
- `$QDRANT_API_KEY` — variable reference bash
- `source /opt/easyway/.env.secrets` — loading pattern
- `(vedi /opt/easyway/.env.secrets sul server)` — reference documentale

---

## 4. Secret Lifecycle

### 4.1 Creazione
1. Generare valore strong: 32+ char, mixed case + numeri + simboli
2. Salvare in `/opt/easyway/.env.secrets` (server) come `KEY=value`
3. Documentare il NOME (mai il valore) in questa wiki
4. Aggiornare `Import-AgentSecrets` consumer list se applicabile
5. Aggiornare `rbac-master.json` se necessario

### 4.2 Distribuzione
1. `Import-AgentSecrets.ps1` carica da `.env.secrets` (SSOT)
2. Container Docker ricevono via `env_file` o `environment: ${VAR}`
3. CI/CD riceve via ADO Variable Groups
4. n8n riceve via Credential Store (configurazione SOLO da UI)
5. **MAI** passare secret come argomenti CLI

### 4.3 Rotazione (max 90 giorni)
1. Generare nuovo valore
2. Aggiornare `/opt/easyway/.env.secrets` sul server
3. Aggiornare ADO Variable Groups se applicabile
4. Aggiornare n8n credentials se applicabile
5. Restart container interessati: `docker compose restart <service>`
6. Eseguire `agent_sentinel` scan per verificare zero hardcoded references
7. Revocare il vecchio valore nel provider (ADO portal, DeepSeek, etc.)

### 4.4 Revoca
1. Revocare nel provider originale
2. Rimuovere da tutte le location di storage
3. Verificare che nessuno script dipenda dal valore revocato
4. Eseguire scan sentinel

---

## 5. Regole per N8N Workflows

1. I secret DEVONO essere configurati via n8n Credential Store (UI)
2. I workflow JSON NON DEVONO contenere valori secret inline
3. I comandi SSH nei workflow DEVONO usare `source /opt/easyway/.env.secrets`
4. Gli export di workflow DEVONO essere revisionati per secret leaked prima di `git add`
5. Le credenziali n8n usano `svc-agent-pr-creator` per operazioni PR/ADO

---

## 6. Regole per CI/CD Pipeline

1. Secret SOLO via ADO Variable Groups (mai in `azure-pipelines.yml`)
2. Il pattern `${GITHUB_PAT}` nell'`env:` block e' corretto (env var injection)
3. MAI usare `$(VAR)` (command substitution) per secret — risulta vuoto
4. `SYSTEM_ACCESSTOKEN` e' pipeline-scoped e NON va in `.env.local`

---

## 7. Classificazione Violazioni

| Severita' | Descrizione | Tempo Risposta | Esempio |
|---|---|---|---|
| **CRITICAL** | Valore secret in file tracciato git | Immediato (< 1h) | API key in `.json`, password in `.md` |
| **HIGH** | Identity PAT sbagliata per operazione | < 24h | Executor PAT usato per creare PR |
| **MEDIUM** | Missing `${VAR}` reference (valore inline) | < 1 settimana | Docker compose con valore diretto |
| **LOW** | Documentazione obsoleta | < 2 settimane | Script mancante nella PAT matrix |

---

## 8. Agent Sentinel

L'agente `agent_sentinel` (L2, rule-based) esegue scan automatici per verificare conformita':
- **Schedule**: nightly alle 02:00 via n8n
- **On-demand**: webhook POST `/n8n/webhook/sentinel-secrets-scan`
- **Output**: JSON report con findings[], compliance[], summary{}
- **Azione su CRITICAL**: crea ADO Work Item tipo Task
- **Skill**: `security.secrets-scan` (`agents/skills/security/Invoke-SecretsScan.ps1`)

---

## 9. Checklist Rapida per Sviluppatori

- [ ] I miei file staged contengono valori secret? → `ewctl commit` li blocca
- [ ] Sto usando il PAT corretto nello script? → Vedi Sezione 2.1
- [ ] Il mio workflow n8n ha secret inline? → Usa Credential Store
- [ ] Ho documentato un secret nel wiki? → Solo NOMI, mai VALORI
- [ ] Devo ruotare un PAT? → Segui Sezione 4.3

---

> **Riferimenti**:
> - `agents/skills/utilities/Import-AgentSecrets.ps1` — RBAC secret broker
> - `C:\old\rbac-master.json` / `/etc/easyway/rbac-master.json` — Sovereign Registry
> - `Wiki/security/secrets-management.md` — Dettaglio tecnico gestione secret
> - `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md` — Checklist governance operativa
