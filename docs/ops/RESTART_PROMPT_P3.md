# EasyWay Agentic Platform — Prompt di Ripartenza Chat

**Data:** 2026-02-16  
**Chat precedente:** P3 Workflow Intelligence — Implementazione  
**Branch attivo:** `feature/p3-workflow-intelligence` (NON mergiato)

---

## Contesto rapido

Stai lavorando su **EasyWay Agentic Platform** (`c:\old\EasyWayDataPortal`).
- **P1** (Foundation): LLM Router, provider abstraction, cost tracking — DONE
- **P2** (Advanced): Orchestration, Factory Kit, Governance — DONE
- **P3** (Workflow Intelligence): Decision Profiles, COSTAR Skills, n8n — IMPLEMENTATO, DA MERGIARE

PRD completo: `docs/PRD_EASYWAY_AGENTIC_PLATFORM.md`
Handoff P2: `docs/HANDOFF_P2_ADVANCED_PLATFORM.md`
Handoff P3: `docs/HANDOFF_P3_WORKFLOW_INTELLIGENCE.md`

---

## Stato P3 — Cosa è FATTO

| Componente | File principali | Test |
|---|---|---|
| Decision Profile UX | `agents/core/schemas/decision-profile.schema.json`, `scripts/pwsh/New-DecisionProfile.ps1`, `agents/config/decision-profiles/*.json` | ✅ 8/8 |
| COSTAR Skills (Summarize, SQLQuery, ClassifyIntent) | `agents/skills/analysis/Invoke-*.ps1`, `registry.json` aggiornato | ✅ 8/8 |
| n8n Visual Orchestration | `agents/core/schemas/n8n-agent-node.schema.json`, `agents/core/tools/Invoke-N8NAgentWorkflow.ps1`, `agents/core/n8n/Templates/agent-composition-example.json` | ✅ 5/5 |
| Branch Pre-Flight Rule | `PRD §22.19`, `.agent/workflows/start-feature.md` | N/A |

Test totali: **21 passed, 0 failed** (`agents/tests/Test-P3-WorkflowIntelligence.ps1`, Pester v3.4)

---

## TASK APERTI (Priorità)

### 🔴 P0 — Bloccanti per merge

1. **PR e merge del branch P3**
   - `feature/p3-workflow-intelligence` → PR → `develop`
   - Poi `develop` → PR → `main` (se deploy prod)
   - Il branch contiene TUTTO il codice P3 + la regola §22.19

2. **Test server**
   - Dopo merge, fare pull sul server (`ubuntu@80.225.86.168`)
   - Testare: Decision Profile wizard, COSTAR skills con `-DryRun`, n8n bridge
   - Verificare che i path del bridge (`Invoke-N8NAgentWorkflow.ps1`) funzionino nell'ambiente server

### 🟡 P1 — Da completare

3. **Q&A / Documentazione errori sessione**
   - Errore commesso: lavoro diretto su `develop` senza feature branch
   - Fix applicato: aggiunta regola PRD §22.19 + workflow `.agent/workflows/start-feature.md`
   - Da valutare: aggiungere un documento `docs/ops/Q&A-sessions.md` per tracciare errori ricorrenti delle sessioni agentiche?

4. **Aggiornare sezione P3 nel PRD** (`docs/PRD_EASYWAY_AGENTIC_PLATFORM.md`)
   - Attualmente nel PRD, P2 items 5 e 8 citano P3 come futuro
   - Aggiornare con stato `[DONE]` e risultati

### 🟢 P2 — Idee per P4

5. **Agent Memory & Learning** — persistenza contesto tra sessioni
6. **Multi-Agent Negotiation** — agenti che si coordinano su task complessi
7. **Production n8n Deploy** — deploy dei workflow agent-composition su n8n prod
8. **COSTAR Skills expansion** — Invoke-Translate, Invoke-Anomaly, Invoke-ExtractEntities

---

## File chiave per riferimento rapido

```
c:\old\EasyWayDataPortal\
├── .agent/workflows/start-feature.md          ← LEGGI PRIMA DI LAVORARE (pre-flight branch check)
├── docs/
│   ├── PRD_EASYWAY_AGENTIC_PLATFORM.md        ← PRD completo (§22.19 = branch rule)
│   ├── HANDOFF_P3_WORKFLOW_INTELLIGENCE.md     ← Riepilogo P3
├── agents/
│   ├── config/decision-profiles/*.json         ← 3 profili starter
│   ├── core/schemas/decision-profile.schema.json
│   ├── core/schemas/n8n-agent-node.schema.json
│   ├── core/tools/Invoke-N8NAgentWorkflow.ps1  ← Bridge n8n→agent
│   ├── skills/analysis/Invoke-Summarize.ps1    ← COSTAR skill
│   ├── skills/analysis/Invoke-SQLQuery.ps1     ← COSTAR skill (safety firewall)
│   ├── skills/analysis/Invoke-ClassifyIntent.ps1 ← COSTAR skill
│   ├── skills/registry.json                    ← Aggiornato con costar_prompt
│   ├── tests/Test-P3-WorkflowIntelligence.ps1  ← Pester v3.4 — 21 test
├── scripts/pwsh/
│   ├── agent-llm-router.ps1                    ← Wizard aggiornato (Step 3 = Decision Profile)
│   ├── New-DecisionProfile.ps1                 ← Wizard interattivo
```

---

## Regole operative attive

1. **Branch pre-flight**: verificare `git branch --show-current` prima di ogni modifica (PRD §22.19)
2. **Local-first**: proporre/validare in locale, server solo dopo conferma (PRD §22.1)
3. **RAG retrieval**: interrogare RAG server prima di task operativi (PRD §22.14)
4. **.agent/workflows/**: istruzioni macchina per agenti, NON documentazione umana

---

## Come usare questo prompt

Copia tutto questo testo e incollalo come primo messaggio nella nuova chat.
Poi scrivi cosa vuoi fare, ad esempio:
- "Facciamo le PR per mergiare P3"
- "Testiamo P3 sul server"
- "Iniziamo P4 — Agent Memory"
- "Documentiamo gli errori nel Q&A"
