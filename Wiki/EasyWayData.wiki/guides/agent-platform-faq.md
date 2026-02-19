---
title: "Agent Platform — FAQ & Q&A"
created: 2026-02-19
updated: 2026-02-19
status: active
category: guide
domain: platform
tags: [faq, qa, agents, secrets, l2, l3, rag, qdrant, deepseek, troubleshooting]
priority: high
audience: [platform-engineers, agent-developers, ops]
---

# Agent Platform — FAQ & Q&A

Risposte alle domande più frequenti sull'agent platform EasyWay.
Organizzato per area tematica. Aggiornato a Session 14.

---

## Indice

1. [Secrets & Environment](#1-secrets--environment)
2. [RAG & Qdrant](#2-rag--qdrant)
3. [Livelli agenti (L1 / L2 / L3)](#3-livelli-agenti)
4. [Invoke-LLMWithRAG](#4-invoke-llmwithrag)
5. [Evaluator-Optimizer](#5-evaluator-optimizer)
6. [Working Memory](#6-working-memory)
7. [Deploy & Server](#7-deploy--server)
8. [Git & PR Workflow](#8-git--pr-workflow)
9. [Iron Dome & Pre-commit](#9-iron-dome--pre-commit)
10. [Troubleshooting E2E](#10-troubleshooting-e2e)

---

## 1. Secrets & Environment

### Q: Dove vanno i platform secrets?
**A:** In un unico file su server: `/opt/easyway/.env.secrets`.
Tutti e tre i platform secrets devono essere presenti:
```
DEEPSEEK_API_KEY=...
GITEA_API_TOKEN=...
QDRANT_API_KEY=...
```
Mai committare questo file. Mai hardcodarlo nel codice.

### Q: Come funziona `Import-AgentSecrets`?
**A:** È una skill PS (`agents/skills/utilities/Import-AgentSecrets.ps1`) chiamata al boot di ogni runner L2/L3. Legge `.env.secrets` e setta le env vars a livello di processo — **non-distruttiva**: se una var è già presente (Docker/CI), la skippa senza sovrascriverla.

```powershell
# Pattern standard in ogni runner:
$importSecretsSkill = Join-Path $SkillsDir 'utilities' 'Import-AgentSecrets.ps1'
if (Test-Path $importSecretsSkill) {
    . $importSecretsSkill
    Import-AgentSecrets | Out-Null
}
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }
```

### Q: Perché il param default `$ApiKey = $env:DEEPSEEK_API_KEY` non basta?
**A:** In PowerShell il default del parametro è valutato **prima** del corpo dello script (al momento del binding). Se la var non è settata in quel momento, `$ApiKey` diventa `""`. `Import-AgentSecrets` viene chiamata dopo il param block: per questo serve la seconda assegnazione `if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }`.

### Q: Devo fare `export QDRANT_API_KEY=...` prima di eseguire un agente dalla shell SSH?
**A:** No, dalla Session 14 non è più necessario. `Import-AgentSecrets` lo carica automaticamente da `.env.secrets`. Il pattern manuale è ancora supportato (override esplicito è rispettato grazie alla non-distruttività).

### Q: Cosa succede se `.env.secrets` non esiste?
**A:** `Import-AgentSecrets` ritorna silenziosamente `{}` senza errori. Questo è il comportamento corretto nel container `easyway-runner`, dove le env vars sono già iniettate da Docker.

### Q: Come aggiungo un nuovo secret alla piattaforma?
**A:** Solo 4 passi:
1. `echo "NEW_KEY=value" | sudo tee -a /opt/easyway/.env.secrets` (server)
2. Aggiornare `docker-compose.yml` se il container ne ha bisogno
3. Usare `$env:NEW_KEY` nel codice — `Import-AgentSecrets` lo carica automaticamente
4. Documentare nella tabella di `Wiki/security/secrets-management.md`

**Nessuna modifica a `Import-AgentSecrets.ps1`** — il parsing è generico.

---

## 2. RAG & Qdrant

### Q: Come funziona la RAG search?
**A:** La catena è:
```
Invoke-LLMWithRAG → Invoke-RAGSearch → rag_search.py → Qdrant (HTTP + API Key)
```
`rag_search.py` legge `os.getenv("QDRANT_API_KEY")` per autenticarsi. La chiave viene settata da `Import-AgentSecrets` al boot del runner.

### Q: `rag_chunks: 0` — cosa significa?
**A:** Il RAG ha fallito in modo non bloccante (graceful degradation). Il LLM ha risposto ugualmente, ma senza contesto dalla wiki. Cause comuni:
- `QDRANT_API_KEY` non settata → 401 Unauthorized
- Qdrant non raggiungibile (porta 6333 bloccata fuori container)
- Query troppo vaga → score < `min_score` (0.3 default)

### Q: `rag_chunks: 0` ma il rischio è comunque corretto — è un problema?
**A:** Sì, perché il modello lavora solo con la sua knowledge base pre-training, senza contesto wiki aggiornato. Il RAG è fondamentale per threat analysis contestuale (policy locali, infrastruttura specifica). Da fixare sempre.

### Q: Come faccio un re-index di Qdrant dopo aver aggiunto file?
**A:** Dal server:
```bash
cd ~/EasyWayDataPortal/scripts
export QDRANT_API_KEY=wgs6XqCt8qglELghWG6IE4kvzdDgh3Kk
export WIKI_PATH=../Wiki/EasyWayData.wiki/<subfolder>
node --experimental-vm-modules ingest_wiki.js
```
Usare sempre una **directory** come `WIKI_PATH` (il glob aggiunge `/**/*.md`).

### Q: Quanti chunk ci sono in Qdrant?
**A:** Post Session 14: **~40,072 chunk** nella collection `easyway_wiki`.
- Wiki agents/: ~455 chunk
- Wiki security/: in crescita
- Codice agents/: ~1,304 chunk

### Q: Qual è il punteggio minimo per un chunk RAG?
**A:** `min_score: 0.3` (configurato in `manifest.json` di ogni agente L2/L3). Chunk con score inferiore vengono scartati.

---

## 3. Livelli Agenti

### Q: Qual è la differenza tra L1, L2, L3?

| Livello | Pattern | Caratteristiche |
|---------|---------|-----------------|
| **L1** | Scripted | Logica deterministica pura, no LLM, no RAG |
| **L2** | LLM+RAG | DeepSeek + Qdrant, single-pass, no auto-miglioramento |
| **L3** | Self-Improving | L2 + Evaluator-Optimizer + Working Memory + Confidence Gating |

### Q: Quando promuovere un agente da L1 a L2?
**A:** Quando la logica deterministica non basta più:
- Input ambigui che richiedono comprensione del linguaggio naturale
- Output che richiedono sintesi da più sorgenti
- Edge case che crescono costantemente

### Q: Quando promuovere un agente da L2 a L3?
**A:** Quando il single-pass non garantisce qualità sufficiente:
- Output fallisce AC predicates >20% delle volte
- Task multi-step che richiedono stato tra step
- Decisioni ad alto rischio che richiedono auto-validazione

### Q: Quali agenti sono L3?
**A:** Attualmente 2:
- `agent_review` — Invoke-AgentReview.ps1 (Session 9)
- `agent_security` — Invoke-AgentSecurity.ps1 (Session 13)

### Q: Quanti agenti L2 ci sono?
**A:** 7 (post Session 13): `agent_backend`, `agent_dba`, `agent_docs_sync`, `agent_governance`, `agent_infra`, `agent_pr_manager`, `agent_vulnerability_scanner`.

### Q: Cosa serve per promuovere un agente a L3?
**A:** Checklist minima:
- [ ] PRD aggiornato con AC predicati (almeno AC-04 confidence, AC-05 findings, AC-07 risk_level)
- [ ] `Invoke-<Agent>.ps1` con Evaluator-Optimizer (`-EnableEvaluator -AcceptanceCriteria`)
- [ ] Working memory via `Manage-AgentSession`
- [ ] Confidence gating (< 0.70 → `requires_human_review: true`)
- [ ] Almeno 4 fixture test (happy path, injection, low confidence, edge case)
- [ ] `manifest.json` v3.x con `evolution_level: 3`, `evaluator_config`

---

## 4. Invoke-LLMWithRAG

### Q: Quali parametri principali accetta?
```powershell
Invoke-LLMWithRAG
  -Query           # stringa da analizzare
  -AgentId         # id agente (per logging)
  -SystemPrompt    # prompt di sistema (da PROMPTS.md)
  -TopK            # chunk RAG da recuperare (default 5)
  -SecureMode      # blocca SkipRAG, isola contesto RAG
  -EnableEvaluator # attiva loop Evaluator-Optimizer
  -AcceptanceCriteria  # array di predicati stringa per l'evaluator
  -MaxIterations   # max iterazioni loop (default 2)
  -SessionFile     # path session.json per working memory
  -Model           # deepseek-chat (default)
  -MaxTokens       # max token risposta (default 1000)
```

### Q: Cosa ritorna?
**A:** `PSCustomObject` con:
- `Success`: bool
- `Answer`: stringa risposta LLM
- `RagChunks`: numero chunk RAG usati
- `EvaluatorEnabled`: bool
- `EvaluatorIterations`: int
- `TokensIn`, `TokensOut`, `CostUSD`, `DurationSec`

### Q: Cosa fa `-SecureMode`?
**A:** Blocca `-SkipRAG` (non si può disabilitare il RAG) e inietta marcatori di isolamento del contesto (`[RAG_CONTEXT_START]...[RAG_CONTEXT_END]`) nel prompt, impedendo al modello di "uscire" dal contesto wiki. Raccomandato sempre per agenti di produzione.

### Q: Perché non passare `QdrantApiKey` come parametro a `Invoke-LLMWithRAG`?
**A:** Pattern ritirato (PR #74). Il problema è strutturale: ogni nuovo secret richiederebbe un nuovo parametro in ogni skill e ogni runner → non scalabile. La soluzione corretta è `Import-AgentSecrets` al boot del runner (vedi ADR-001 in `secrets-management.md`).

---

## 5. Evaluator-Optimizer

### Q: Come funziona il loop Evaluator-Optimizer?
**A:**
```
[Generator] → risposta raw
     ↓
[Evaluator] → score ogni AC predicato (pass/fail)
     ↓
  Tutti pass? → return risposta
  Qualcuno fail? → feedback al Generator → retry
     ↓ (max MaxIterations volte)
[Graceful degradation] → se evaluator crasha, return risposta generator
```

### Q: Cosa sono gli AC predicati?
**A:** Stringhe che descrivono criteri di accettazione. L'evaluator (chiamata LLM separata) valuta se la risposta del generator soddisfa ognuno.
Esempio per `agent_security`:
```
"AC-04: Output JSON must contain 'risk_level' with one of: CRITICAL, HIGH, MEDIUM, LOW, INFO"
"AC-05: Output JSON must contain numeric 'confidence' between 0.0 and 1.0"
"AC-07: If risk_level CRITICAL/HIGH/MEDIUM, 'findings' must be non-empty array"
```

### Q: Quante iterazioni vengono usate in produzione?
**A:** Tipicamente 1-2. Nel test E2E di `agent_review` (Session 10): 2 iterazioni. Nel test E2E di `agent_security` (Session 13): 1 iterazione (output già corretto al primo tentativo).

### Q: Cosa succede se l'evaluator fallisce (errore API)?
**A:** Graceful degradation: si ritorna la risposta del generator senza bloccare. Il campo `evaluator_passed` sarà `false` nell'output.

---

## 6. Working Memory

### Q: Cos'è la working memory in un agente L3?
**A:** Un file `session.json` creato all'avvio del task e rimosso alla fine. Conserva lo stato intermedio (step completati, risultati parziali) per workflow multi-step senza re-passare tutto il contesto.

### Q: Dove si trova il session file?
**A:** `agents/<agent_id>/memory/session.json` (path default). Può essere passato esplicitamente con `-SessionFile`.

### Q: Quali operazioni supporta `Manage-AgentSession`?
```
New      → crea session file, ritorna path
Get      → legge stato corrente
Update   → aggiorna campi
SetStep  → marca step come completato
Close    → chiude sessione, scrive durata
Cleanup  → elimina file (post-task)
```

### Q: La working memory persiste tra sessioni diverse?
**A:** No. Viene creata all'inizio e eliminata alla fine di ogni singolo task. Non è una memoria long-term (quella è Qdrant/wiki).

---

## 7. Deploy & Server

### Q: Come si fa il deploy di una modifica?
**A:** Workflow obbligatorio (mai saltare passi):
```
1. Modifica locale in C:\old\EasyWayDataPortal\
2. git commit (Iron Dome pre-commit)
3. git push origin <feature-branch>
4. PR feat→develop
5. PR develop→main [Release, Merge no fast-forward]
6. SSH server: cd ~/EasyWayDataPortal && git pull
7. Test nel container (opzionale per L1, raccomandato per L2/L3)
```

### Q: Come mi connetto al server?
```bash
"/c/Windows/System32/OpenSSH/ssh.exe" -i "/c/old/Virtual-machine/ssh-key-2026-01-25.key" ubuntu@80.225.86.168
```

### Q: Come eseguo un agente dal server?
```bash
cd ~/EasyWayDataPortal
pwsh agents/agent_security/Invoke-AgentSecurity.ps1 \
  -Action security:analyze -Query "..." -JsonOutput
# Import-AgentSecrets carica DEEPSEEK_API_KEY e QDRANT_API_KEY automaticamente
```

### Q: Quali porte sono esposte pubblicamente?
**A:** Solo `80`, `443`, `22`. Tutte le altre (Qdrant 6333, MinIO 9000/9001, SQL 1433, n8n 5678, Gitea 3100) sono bloccate dalla DOCKER-USER chain di iptables.

---

## 8. Git & PR Workflow

### Q: Da quale branch creo le feature?
**A:** Sempre da `develop`. Mai da `main` o `baseline`.

### Q: Qual è la naming convention dei branch?
```
feat/<feature-name>        # nuove funzionalità
fix/<bug-description>      # bug fix
docs/<topic>               # documentazione
refactor/<component>       # refactoring
```

### Q: Come creo una PR via API (Azure DevOps)?
```bash
source /c/old/.env.local
curl -s -u ":$AZURE_DEVOPS_EXT_PAT" -X POST \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/git/repositories/EasyWayDataPortal/pullrequests?api-version=7.1-preview.1" \
  -d '{"title":"...","sourceRefName":"refs/heads/feat/...","targetRefName":"refs/heads/develop","reviewers":[]}'
```

### Q: Come faccio il commit?
**A:** `ewctl commit -m "..."` oppure `git commit -m "..."` (Iron Dome viene triggerato in entrambi i casi via pre-commit hook).

### Q: Qual è la merge strategy per develop→main?
**A:** **Merge (no fast-forward)**. MAI Squash su questo branch — perderebbe la storia dei commit.

---

## 9. Iron Dome & Pre-commit

### Q: Cos'è Iron Dome?
**A:** Il pre-commit hook PS (`.git/hooks/pre-commit` → `scripts/pwsh/pre-commit.ps1`) che esegue:
1. PSScriptAnalyzer su tutti i file `.ps1` stagionati
2. Auto-sync `platform-operational-memory.md` → `.cursorrules` se wiki è stagionata

### Q: Iron Dome blocca su `Write-Host`?
**A:** No. `Write-Host` è un Warning, non un Error. Iron Dome blocca solo su severity `Error`. Il pattern `Write-Host` per output console degli agent runner è accettato.

### Q: Cosa fa il Sync-PlatformMemory automatico?
**A:** Se `platform-operational-memory.md` è tra i file stagionati, Iron Dome chiama `Sync-PlatformMemory.ps1` che aggiorna il blocco `AUTO-SYNC` in `.cursorrules` con il contenuto della wiki (~36K chars). Questo propaga la conoscenza operativa a tutti i tool AI-assisted che leggono `.cursorrules`.

### Q: Come verifico se `.cursorrules` è sincronizzato?
```powershell
Select-String 'Session 14|Import-AgentSecrets' .cursorrules | Measure-Object | Select-Object Count
# Deve essere > 0
```

---

## 10. Troubleshooting E2E

### Q: Il test E2E mostra `rag_chunks: 0` — cosa faccio?
**A:**
1. Verifica `QDRANT_API_KEY` in `.env.secrets`: `grep QDRANT_API_KEY /opt/easyway/.env.secrets`
2. Verifica che il runner chiami `Import-AgentSecrets`: cerca `Import-AgentSecrets` nello script
3. Verifica Qdrant raggiungibile: `curl -s http://localhost:6333/collections/easyway_wiki -H "api-key: ..."  | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['points_count'])"`

### Q: "DEEPSEEK_API_KEY is not set" anche con `.env.secrets` configurato
**A:** Verificare che il runner abbia la seconda assegnazione post-load:
```powershell
if (-not $ApiKey) { $ApiKey = $env:DEEPSEEK_API_KEY }
```
Senza questa riga, il param default valutato prima di `Import-AgentSecrets` rimane `""`.

### Q: Injection detection triggera su query legittime?
**A:** Controllare i pattern in `$InjectionPatterns` in `Invoke-AgentSecurity.ps1`. Il pattern `(?i)ignore\s+(all\s+)?(previous\s+)?instructions?` è case-insensitive e può dare falsi positivi se la query contiene "ignore" in contesto legittimo. Raffinare il pattern se necessario.

### Q: L'Evaluator-Optimizer non migliora l'output dopo 2 iterazioni — normale?
**A:** Sì. Il massimo è `MaxIterations: 2` per default. Se non soddisfa gli AC dopo 2 tentativi, ritorna comunque il miglior output disponibile (graceful degradation). Per casi complessi, aumentare a `MaxIterations: 3` oppure rifinire i predicati AC.

### Q: Come testo un singolo fixture senza LLM?
**A:** I fixture `ex-02-injection` e `ex-04-kv-naming-violation` non richiedono LLM (vengono respinti a livello PS prima della chiamata API). Test veloce:
```bash
pwsh Invoke-AgentSecurity.ps1 -Action kv-secret:set \
  -VaultName test-vault -SecretName badname -SecretValue x -JsonOutput -WhatIf
# → status: ERROR, action_taken: REJECT (AC-08)
```

---

## References

- `agents/skills/utilities/Import-AgentSecrets.ps1` — skill SSOT secrets
- `Wiki/EasyWayData.wiki/security/secrets-management.md` — guida completa secrets
- `Wiki/EasyWayData.wiki/agents/agent-evolution-roadmap.md` — roadmap L1/L2/L3
- `Wiki/EasyWayData.wiki/agents/agent-roster.md` — elenco agenti corrente
- `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md` — memoria operativa
- `Wiki/EasyWayData.wiki/guides/parallel-agent-execution.md` — guida parallelizzazione
- `agents/skills/retrieval/Invoke-LLMWithRAG.ps1` — skill LLM+RAG core
- `agents/agent_security/Invoke-AgentSecurity.ps1` — runner L3 reference
- `agents/agent_review/Invoke-AgentReview.ps1` — runner L3 reference
