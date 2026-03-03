---
title: "ADO PR Structural Validation"
category: guides
domain: ado, devops
tags: [domain/devops, layer/guide, privacy/internal, language/it, audience/dev]
priority: critical
audience:
  - developers
  - ai-assistants
  - scrum-masters
last-updated: 2026-03-03
id: ew-guides-ado-pr-structural-validation
summary: Come il modulo ewctl.ado-pr.psm1 rende strutturali conflict check, work item linking e merge strategy in ogni PR.
status: active
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: []
entities: []
type: guide
---

# ADO PR Structural Validation

**Modulo**: `scripts/pwsh/modules/ewctl/ewctl.ado-pr.psm1`
**Versione**: 1.1.0 (Session 56)
**Script che lo usano**: Create-ReleasePR, Publish-WikiPages, New-PbiBranch

---

## 1. Il Problema

Prima di Session 56, ogni PR creata manualmente o via script falliva per almeno uno di questi motivi:

| Errore | Causa root | Frequenza |
|--------|-----------|-----------|
| "Work Items must be linked" | `workItemRefs` nel body PR non soddisfa la branch policy ADO | Ogni PR |
| Conflitti scoperti dopo la PR | Nessun pre-check prima della creazione | ~30% delle PR |
| Merge strategy errata | `mergeStrategy` fuori da `completionOptions` o assente | Silenzioso |
| PAT 401 Unauthorized | Script diversi usano PAT diversi senza logica condivisa | Intermittente |
| Work items non trovati | Regex `[PBI-(\d+)]` nei titoli PR — nessuna PR ha quel pattern | 100% |

**Costo**: 15-30 minuti per PR per risolvere manualmente. Moltiplicato per ~5 PR/sessione = 1-2 ore perse.

---

## 2. La Soluzione: ewctl.ado-pr.psm1

Un modulo PowerShell condiviso che rende **strutturali** i controlli che prima erano manuali.

### 2.1 Funzioni esportate

| Funzione | Scopo | Sostituisce |
|----------|-------|-------------|
| `Resolve-AdoPat` | Carica PAT da parametro / env var / .env file | 4x duplicazione PAT loading |
| `New-AdoAuthHeaders` | Costruisce header `Authorization: Basic` | 4x duplicazione header |
| `Invoke-AdoApi` | GET/POST/PATCH con error handling standard | `Invoke-RestMethod` sparsi |
| `Get-PrWorkItemIds` | Scopre WI linkati a PR via API (non regex) | Regex fragile `[PBI-(\d+)]` |
| `Test-MergeConflicts` | Pre-flight conflict check senza toccare il working tree | Nessuno (nuovo) |
| `New-AdoPullRequest` | Crea PR + ArtifactLink + noFastForward + conflict check | 3x duplicazione POST |

### 2.2 Architettura

```
┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
│  Create-ReleasePR.ps1   │     │  Publish-WikiPages.ps1  │     │  New-PbiBranch.ps1      │
│  develop -> main        │     │  docs/* -> develop      │     │  feat/PBI-* -> develop  │
└────────────┬────────────┘     └────────────┬────────────┘     └────────────┬────────────┘
             │                               │                               │
             └───────────────┬───────────────┴───────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ ewctl.ado-pr    │
                    │ .psm1           │
                    │                 │
                    │ 1. Resolve PAT  │
                    │ 2. Conflict chk │
                    │ 3. Create PR    │
                    │ 4. ArtifactLink │
                    └─────────────────┘
```

---

## 3. Il Meccanismo ArtifactLink (Scoperta Chiave)

### 3.1 Perche workItemRefs non basta

ADO ha **due livelli** di work item linking:

| Livello | Come si crea | Soddisfa branch policy? |
|---------|-------------|------------------------|
| `workItemRefs` nel body della PR | Incluso nel POST `/pullrequests` | **NO** |
| `ArtifactLink` sul work item | PATCH sul work item con relazione `ArtifactLink` | **SI** |

La branch policy "Work Items must be linked" verifica l'esistenza di una relazione `ArtifactLink` **sul work item** che punta alla PR. Il campo `workItemRefs` nel body della PR crea un riferimento lato PR ma **non** la relazione inversa sul work item.

### 3.2 Come il modulo lo risolve

Dopo aver creato la PR con successo, `New-AdoPullRequest` esegue automaticamente:

1. **Resolve project ID** — `GET _apis/projects/{Project}` (usa PR creator PAT con Code Read)
2. **Resolve repo GUID** — `GET _apis/git/repositories/{RepoId}` (il RepoId puo essere un nome, serve il GUID)
3. **Per ogni Work Item ID**:
   ```
   PATCH _apis/wit/workitems/{id}
   Content-Type: application/json-patch+json

   [{
     "op": "add",
     "path": "/relations/-",
     "value": {
       "rel": "ArtifactLink",
       "url": "vstfs:///Git/PullRequestId/{projectId}%2f{repoGuid}%2f{prId}",
       "attributes": { "name": "Pull Request" }
     }
   }]
   ```

### 3.3 URI dell'ArtifactLink

Il formato e fisso:
```
vstfs:///Git/PullRequestId/{projectId}%2f{repoGuid}%2f{prId}
```

Valori per EasyWayDataPortal:
- **Project ID**: `d8c907d2-dae1-4db1-9dcf-40c2931b6dc7`
- **Repo GUID**: `e29d5c59-28d0-4815-8f62-6f5c1465855c`

Esempio per PR #253:
```
vstfs:///Git/PullRequestId/d8c907d2-dae1-4db1-9dcf-40c2931b6dc7%2fe29d5c59-28d0-4815-8f62-6f5c1465855c%2f253
```

---

## 4. PAT Identity Governance

Il modulo rispetta la separazione di identita tra service account:

| PAT env var | Service Account | Scope | Usato per |
|---|---|---|---|
| `ADO_PR_CREATOR_PAT` | ew-svc-pr-creator | Code Read + PR Contribute | Creare PR, leggere branch/repo |
| `ADO_WORKITEMS_PAT` | scrum-master | Work Items R/W | PATCH ArtifactLink sui work items |
| `AZURE_DEVOPS_EXT_PAT` | ew-svc-azuredevops-agent | Code R/W | git push, resolve conflicts |

### Perche servono PAT separati

- **PR creator** ha Code Read (per leggere refs branch e repo GUID) + PR Contribute (per creare PR)
- **Scrum-master** ha Work Items R/W (per il PATCH ArtifactLink) ma **non** Code Read
- Il modulo usa `$Headers` (PR creator) per i lookup project/repo, e `$wiAuth` (auto-resolved da `ADO_WORKITEMS_PAT`) per il PATCH WI

### Priorita di risoluzione PAT

`Resolve-AdoPat` cerca in ordine:
1. Parametro esplicito `-Pat`
2. Environment variables (in ordine di priorita configurabile)
3. File `.env.local` (Windows) o `.env.secrets` (Linux/server)

---

## 5. Conflict Pre-Check

`Test-MergeConflicts` esegue un dry-run merge locale senza modificare il working tree:

```
1. git stash                              # salva modifiche locali
2. git fetch origin source target         # aggiorna refs
3. git checkout --detach origin/target    # detach HEAD su target
4. git merge --no-commit --no-ff origin/source  # tenta merge
5. Se conflitto: git merge --abort + cattura file in conflitto
6. Se ok: git merge --abort + git reset --hard HEAD
7. git checkout <branch-originale>        # ripristina
8. git stash pop                          # ripristina modifiche
```

**Escape hatch**: `-SkipConflictCheck` per emergenze (es. PR wiki che non rischiano conflitti).

---

## 6. Script Refactored

### 6.1 Create-ReleasePR.ps1

```powershell
# Dry-run: mostra delta, work items, titolo
pwsh scripts/pwsh/Create-ReleasePR.ps1 -WhatIf

# Crea Release PR develop -> main
pwsh scripts/pwsh/Create-ReleasePR.ps1

# Con label sessione esplicito
pwsh scripts/pwsh/Create-ReleasePR.ps1 -SessionLabel "Session 56"
```

**Flusso**:
1. Risolve PAT via `Resolve-AdoPat`
2. Auto-detect SessionLabel dall'ultima Release PR su main
3. Query PR mergiate su develop dal ultimo release
4. Scopre work items via `Get-PrWorkItemIds` (API, non regex)
5. Conflict pre-check via `Test-MergeConflicts`
6. Crea PR via `New-AdoPullRequest` (include ArtifactLink automatico)

### 6.2 Publish-WikiPages.ps1

```powershell
# Dry-run: mostra file wiki modificati
pwsh scripts/pwsh/Publish-WikiPages.ps1 -WhatIf

# Pubblica wiki + crea PR + opzionale reindex Qdrant
pwsh scripts/pwsh/Publish-WikiPages.ps1 [-Reindex]
```

**Flusso**:
1. Rileva file nuovi/modificati sotto `Wiki/EasyWayData.wiki/`
2. Crea branch `docs/wiki-<slug>` da develop
3. git add + commit (Iron Dome pre-commit)
4. git push
5. Crea PR via `New-AdoPullRequest -SkipConflictCheck` (wiki non ha conflitti tipicamente)
6. (Opzionale) SSH al server per Qdrant re-index

### 6.3 New-PbiBranch.ps1 -CreatePR

```powershell
# Crea branch + PR per PBI specifico
pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 41 -CreatePR
```

**Bug fix Session 56**: `mergeStrategy` era fuori da `completionOptions` — ora corretto nel modulo condiviso.

---

## 7. Troubleshooting

### "Work Items must be linked" dopo aver creato la PR

**Causa**: il PATCH ArtifactLink ha fallito (401, PAT scaduto, o scope insufficiente).

**Verifica**:
```powershell
# Controlla se il WI ha il link alla PR
$wiId = 41; $prId = 253
$resp = Invoke-AdoApi -Url "$RepoBase/../../../_apis/wit/workitems/$wiId`?`$expand=relations&api-version=7.1" -Headers $headers
$resp.relations | Where-Object { $_.url -match "PullRequestId.*$prId" }
```

**Fix manuale** (se il modulo non riesce):
```bash
PAT=$(grep '^ADO_WORKITEMS_PAT=' /c/old/.env.local | cut -d= -f2)
B64=$(printf ":%s" "$PAT" | base64 -w0)
curl -X PATCH "https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/wit/workitems/$WI_ID?api-version=7.1" \
  -H "Authorization: Basic $B64" \
  -H "Content-Type: application/json-patch+json" \
  -d '[{"op":"add","path":"/relations/-","value":{"rel":"ArtifactLink","url":"vstfs:///Git/PullRequestId/d8c907d2-dae1-4db1-9dcf-40c2931b6dc7%2fe29d5c59-28d0-4815-8f62-6f5c1465855c%2f'"$PR_ID"'","attributes":{"name":"Pull Request"}}}]'
```

### Conflict pre-check fallisce ma la PR non ha conflitti reali

**Causa**: il check locale usa `origin/` refs — se non hai fetchato di recente, i refs sono stale.

**Fix**: `git fetch origin develop main` prima di lanciare lo script.

### PAT 401 su tutte le operazioni

**Verifica scadenza**:
```powershell
pwsh agents/skills/utilities/Invoke-SecretsScan.ps1 -RegistryPath /opt/easyway/secrets-registry.json
```

**Rinnovo**: ADO > User Settings > Personal Access Tokens > rinnova con stessi scope.

---

## 8. Lessons Learned (Session 56)

| # | Lesson | Impatto |
|---|--------|---------|
| L1 | `workItemRefs` nel body PR **non** soddisfa la branch policy "Work Items must be linked" | Serve ArtifactLink bidirezionale |
| L2 | L'ArtifactLink richiede project GUID + repo GUID + PR ID nel formato `vstfs:///` | URI non e' intuitivo |
| L3 | Il PATCH WI richiede `Content-Type: application/json-patch+json` (non `application/json`) | 415 Unsupported Media Type se sbagliato |
| L4 | Il PAT per PATCH WI (scrum-master) non ha Code Read -> non puo risolvere repo GUID | Usare PR creator PAT per lookup, WI PAT solo per PATCH |
| L5 | Regex `[PBI-(\d+)]` per scoprire work items fallisce nel 100% dei casi | Usare API `pullrequests/{id}/workitems` |
| L6 | `mergeStrategy` deve stare DENTRO `completionOptions`, non al top level del body PR | Bug silenzioso — ADO ignora il campo senza errore |

---

## Riferimenti

- `scripts/pwsh/modules/ewctl/ewctl.ado-pr.psm1` — modulo condiviso (source of truth)
- `scripts/pwsh/Create-ReleasePR.ps1` — Release PR develop->main
- `scripts/pwsh/Publish-WikiPages.ps1` — Wiki publishing
- `agents/skills/git/New-PbiBranch.ps1` — PBI branch + PR
- `Wiki/EasyWayData.wiki/guides/agentic-pbi-to-pr-workflow.md` — flusso PBI-to-PR concettuale
- `Wiki/EasyWayData.wiki/standards/ado-workflow.md` — regole esecuzione ADO
- `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md` — memoria operativa
