# Q&A Sessioni Agentiche — Errori Ricorrenti

Tracciamento errori commessi durante sessioni agentiche per prevenire ricorrenze.

## Template Entry

| Campo | Valore |
|-------|--------|
| **Data** | YYYY-MM-DD |
| **Sessione** | P1/P2/P3/... |
| **Errore** | Descrizione breve |
| **Impatto** | Cosa è successo |
| **Fix applicato** | Cosa è stato fatto per correggere |
| **Prevenzione** | Regola/guardrail aggiunto |

---

## Registro

### 2026-02-16 — Lavoro diretto su develop senza feature branch

| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | P3 — Workflow Intelligence |
| **Errore** | L'agente ha iniziato a lavorare direttamente su `develop` invece di creare un feature branch |
| **Impatto** | Commit su branch protetto, rischio di merge non governato |
| **Fix applicato** | Creato `feature/p3-workflow-intelligence`, cherry-pick dei commit, reset di develop |
| **Prevenzione** | Aggiunta regola PRD §22.19 (Agent Pre-Flight Branch Check) + workflow `.agent/workflows/start-feature.md` |

### 2026-02-16 — Branch scompare da origin dopo push riuscito

| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | P3 — Merge Preparation |
| **Errore** | `feature/p3-workflow-intelligence` pushato con successo ma poi non visibile su `origin` via `git ls-remote` |
| **Impatto** | Impossibilità di creare PR — branch assente su ADO |
| **Fix applicato** | Re-push con `git push -u origin feature/p3-workflow-intelligence` |
| **Prevenzione** | Sempre verificare con `git ls-remote --heads origin <branch>` dopo il push. Monitorare ADO branch policies che possono eliminare branch automaticamente. Vedi anche PRD §22.13 (Branch Governance anti-sparizione) |

### 2026-02-16 — az devops login richiesto separatamente da az login

| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | P3 — Merge Preparation |
| **Errore** | `az repos pr create` fallisce con auth error anche se `az account show` funziona |
| **Impatto** | Impossibilità di creare PR via CLI |
| **Fix applicato** | Eseguire `az devops login --org https://dev.azure.com/EasyWayData` con PAT token |
| **Prevenzione** | **Prerequisito obbligatorio**: prima di usare qualsiasi comando `az repos` o `az devops`, eseguire `az devops login`. Il login Azure (`az login`) NON copre i comandi DevOps. Il PAT deve avere permessi: Code (Read & Write) + Pull Requests (Read & Write) |

### 2026-02-16 — Commit diretto su develop (Violazione Processo)

| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | P3 — Merge Preparation |
| **Errore** | Durante la scrittura della documentazione sulle policy di merge, ho committato direttamente su `develop` (`99900b0`) invece di usare un feature branch. |
| **Impatto** | Violazione del Gitflow (Rule: No direct commits to eternal branches). Nessun impatto sul codice (solo docs), ma crea un precedente errato. |
| **Fix applicato** | Nessuno (accettato il rischio visto che erano solo docs). Il merge su `main` includerà comunque questi commit. |

### 2026-02-16 — Hybrid Core: Shell Parsing Errors
 
| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | Governance & Hybrid Core Tests |
| **Errore** | `Invoke-AgentTool -Target (git diff)` fallisce perché PowerShell interpreta caratteri speciali (`---`, `/dev/null`) nel diff come operatori. |
| **Impatto** | Impossibile generare descrizioni PR o review automatiche. |
| **Fix applicato** | Adozione del **Pipeline Pattern**: `git diff | Invoke-AgentTool`. Il tool legge da Stdin, bypassando il parser della shell. |
| **Prevenzione** | Regola esplicita in `.cursorrules` + warning in `ewctl commit`. Documentazione in `Wiki/Hybrid-Core-Usage.md`. |
 
### 2026-02-16 — Commit Dimenticati / Audit mancante
 
| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | Governance & Hybrid Core Tests |
| **Errore** | Rischio di committare senza aver runnato l'audit o controllato i pattern vietati. |
| **Impatto** | Regressioni nel codice o Violazioni di policy (es. uso errato di tool). |
| **Fix applicato** | Creato **Smart Commit Wrapper** (`ewctl commit`). |
| **Prevenzione** | Obbligo (via `.cursorrules`) di usare `ewctl commit` invece di `git commit`. Il wrapper esegue pre-flight checks (Anti-pattern scan + Rapid Audit). |
