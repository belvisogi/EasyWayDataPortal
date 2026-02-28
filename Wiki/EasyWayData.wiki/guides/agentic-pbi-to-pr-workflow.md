# Agentic PBI-to-PR Workflow

**Versione**: 1.0
**Data**: 2026-02-28
**Owner**: Giuseppe Belviso
**Stato**: Design — implementazione in corso (Session 40)
**Fonte**: ragionamento Session 40 + `#innovazione_agenti/EASYWAY_AGENTIC_SDLC_MASTER.md`

---

## Indice

1. [Il Problema](#1-il-problema)
2. [L'Intuizione](#2-lintuizione)
3. [La Regola Antifragile](#3-la-regola-antifragile)
4. [Il Flusso End-to-End](#4-il-flusso-end-to-end)
5. [Architettura Componenti](#5-architettura-componenti)
6. [Decisioni di Design (Perché)](#6-decisioni-di-design-perché)
7. [Gap Analysis — Cosa Esiste vs Cosa Manca](#7-gap-analysis)
8. [Piano di Implementazione](#8-piano-di-implementazione)
9. [Lessons Learned](#9-lessons-learned)

---

## 1. Il Problema

Oggi le PR arrivano senza PBI. Il ciclo di vita è spezzato in tre punti:

```
Idea → [vuoto] → Developer crea branch a intuito
                → Lavora
                → Apre PR senza riferimento ADO
                → Reviewer non sa a quale requisito si riferisce
                → PBI creato dopo (o mai)
```

Conseguenze concrete:
- **Traceability zero**: non si sa quale PR soddisfa quale requisito.
- **Review inefficace**: il reviewer non ha gli Acceptance Criteria davanti.
- **Board ADO orfana**: i PBI restano "New" anche quando il lavoro è fatto.
- **Release notes manuali**: si ricostruisce a posteriori cosa è stato fatto.

---

## 2. L'Intuizione

Non si tratta di "automatizzare i PBI". Si tratta di **invertire l'ordine**:

> Il PBI deve esistere **prima** che il developer apra il branch.
> La PR non crea il collegamento — lo **eredita** dal branch.

Il flusso corretto:

```
Requisito → PBI in ADO (con AC) → Branch PBI-123-slug → PR con AB#123 + AC
```

Questo è già descritto nel documento `EASYWAY_AGENTIC_SDLC_MASTER.md` (Fase 2 + Fase 3).
Questo documento traduce quella visione in **componenti implementabili**.

---

## 3. La Regola Antifragile

Il sistema deve funzionare **anche quando i pezzi automatici falliscono**.

Principio applicato a ogni step:

| Step | Automazione | Fallback manuale |
|------|-------------|-----------------|
| Discovery → PRD | `agent_discovery` con RAG su Wiki | Umano scrive il PRD |
| PRD → PBI in ADO | `agent-ado-prd.ps1` (WhatIf → Apply) | Umano crea PBI manualmente in ADO |
| PBI → Branch + PR template | `New-PbiBranch.ps1` | Umano esegue `git checkout -b feat/PBI-<id>-...` e copia AC a mano |
| PR → Merge | `agent_pr_gate` + gate umano | Umano approva come sempre |

**Regola di antifragilità**: ogni step deve aggiungere valore **in isolamento**, senza richiedere che lo step precedente sia automatizzato. Un developer può creare il PBI manualmente in ADO e usare `New-PbiBranch.ps1` — il sistema funziona lo stesso.

**Gate umani obbligatori** (non negoziabili):
- PRD validato dall'umano prima di creare PBI
- WhatIf preview prima di Apply su ADO
- Approvazione PR prima del merge

---

## 4. Il Flusso End-to-End

### Visione completa

```
┌─────────────────────────────────────────────────────────────────┐
│  FASE 1 — Discovery / PRD                                       │
│                                                                 │
│  Input: requisito in linguaggio naturale                        │
│         oppure documento esistente (wiki, email, nota)          │
│                                                                 │
│  Agent: agent_discovery  →  RAG su Wiki + repo                  │
│  Output: PRD.md con:                                            │
│    - Obiettivo business                                         │
│    - Impatti tecnici (API, DB, frontend, ETL)                   │
│    - Evidence + Confidence score (H/M/L)                        │
│    - Draft AC per ogni area                                     │
│                                                                 │
│  ✅ GATE UMANO: validazione PRD prima di procedere              │
└────────────────────────┬────────────────────────────────────────┘
                         │ PRD.md validato
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  FASE 2 — Decomposizione Backlog                                │
│                                                                 │
│  Agent: agent_backlog_planner / agent_ado_userstory             │
│  Script: agent-ado-prd.ps1                                      │
│                                                                 │
│  WhatIf → mostra: "Creo 1 Epic, 3 Feature, 12 PBI"             │
│  Apply  → crea in ADO:                                          │
│    Epic  → Feature → PBI (con title, description, AC)           │
│                                                                 │
│  Output: lista PBI creati [{ id: 123, title, ac }, ...]         │
│                                                                 │
│  ✅ GATE UMANO: approvazione backlog prima di Apply             │
└────────────────────────┬────────────────────────────────────────┘
                         │ PBI ID + AC
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  FASE 3 — Branch + PR Template  ← IL GAP ATTUALE               │
│                                                                 │
│  Skill: New-PbiBranch.ps1  (DA COSTRUIRE — priorità 1)          │
│                                                                 │
│  Input:  --pbi-id 123                                           │
│  Fetch:  titolo + AC da ADO API                                  │
│  Esegue: git checkout -b feat/PBI-123-short-title               │
│  Output: PR description template con:                           │
│    - Title:  [PBI-123] Short title                              │
│    - Body:   AB#123                                             │
│              ## Acceptance Criteria                             │
│              [AC dal PBI ADO]                                   │
│              ## Test Plan                                       │
│              [ ] AC1 verificato                                 │
│              [ ] AC2 verificato                                 │
│                                                                 │
│  ✅ GATE: developer verifica il branch e il template prima      │
│           di iniziare a lavorare                                │
└────────────────────────┬────────────────────────────────────────┘
                         │ Developer lavora
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  FASE 4 — PR Review & Merge                                     │
│                                                                 │
│  La PR aperta dal developer contiene già:                       │
│    - Branch: feat/PBI-123-short-title                           │
│    - Title:  [PBI-123] Short title                              │
│    - Body:   AB#123 → link automatico ADO Boards                │
│              Acceptance Criteria → reviewer sa cosa verificare  │
│                                                                 │
│  Agent: agent_pr_gate → review automatica                       │
│  ✅ GATE UMANO: approvazione PR                                 │
│  → Merge → ADO work item si chiude automaticamente              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Architettura Componenti

### 5.1 Componenti esistenti (manifest ✓, implementazione da verificare)

| Componente | Path | Stato |
|-----------|------|-------|
| `agent_discovery` | `agents/agent_discovery/` | Manifest ✓ — impl. da verificare |
| `agent_backlog_planner` | `agents/agent_backlog_planner/` | Manifest + backlog-run.ps1 ✓ — platform-plan/apply.ps1 mancanti |
| `agent_ado_userstory` | `agents/agent_ado_userstory/` | Manifest ✓ — `agent-ado-prd.ps1` **mancante** |
| `agent_pr_gate` | `agents/agent_pr_gate/` | Presente ✓ |

### 5.2 Componenti mancanti (da costruire)

| Componente | Priorità | Dipendenze |
|-----------|----------|-----------|
| `New-PbiBranch.ps1` | **1 — Immediata** | Nessuna (funziona con qualsiasi PBI esistente) |
| `agent-ado-prd.ps1` | 2 — Prossima sessione | ADO API, PRD.md validato |
| `platform-plan.ps1` + `platform-apply.ps1` | 3 — Sessione futura | agent_backlog_planner |

### 5.3 Skills da importare da `.agents/skills/`

| Skill | Da | Dove | Perché |
|-------|-----|------|--------|
| `business-analyst/` | `C:\old\.agents\skills\business-analyst\` | `agents/skills/skill_ba_discovery/` | Struttura la discovery Phase 1 — framework interviste + template requisiti |
| `product-manager/` | `C:\old\.agents\skills\product-manager\` | `agents/skills/skill_pm_prd/` | PRD template + MoSCoW/RICE prioritization — Phase 2 |
| `azure-devops/` | `C:\old\.agents\skills\azure-devops\` | reference interno `New-PbiBranch.ps1` | 847 righe di ADO REST API reference — fetch AC da work item |

---

## 6. Decisioni di Design (Perché)

### 6.1 Perché `New-PbiBranch.ps1` prima di `agent-ado-prd.ps1`

**Ragionamento antifragile**: `New-PbiBranch.ps1` funziona oggi, con qualsiasi PBI già esistente in ADO — creato dall'umano, dall'agente, o da un altro tool. Non ha dipendenze upstream.

Se costruissimo prima `agent-ado-prd.ps1`, avremmo un sistema che crea PBI in ADO ma lo sviluppatore continua ad aprire PR senza link. Il "last mile" resterebbe rotto.

**Principio**: risolvi il punto di frizione più vicino all'utente finale (developer → PR), poi costruisci a ritroso verso l'automazione upstream.

### 6.2 Perché WhatIf obbligatorio prima di Apply

La decomposizione PRD → PBI è un'operazione **irreversibile** su ADO (eliminare work item è distruttivo e lascia tracce). Il WhatIf mostra il piano completo prima di qualsiasi scrittura. L'umano approva il numero di PBI, la struttura delle Feature, i titoli.

**Principio**: "Misura due, taglia uno" — il sistema avvisa, l'umano decide.

### 6.3 Perché il link ADO viene dal branch, non dalla PR

ADO riconosce automaticamente `AB#<id>` nel titolo o nel body della PR e collega il work item. Se il branch si chiama `feat/PBI-123-...`, il developer **non può dimenticare** l'ID — è nel nome del branch da cui fa il push.

**Principio**: rendere la cosa sbagliata (dimenticare il PBI) più difficile della cosa giusta.

### 6.4 Perché non un unico mega-agente

Un singolo agente che fa Discovery → PRD → PBI → Branch → PR sarebbe fragile: se qualsiasi step fallisce, tutto si blocca. La composizione di script piccoli e indipendenti permette:
- Test isolato di ogni componente
- Fallback manuale su ogni step
- Riuso in contesti diversi (es. `New-PbiBranch.ps1` usato da dev senza passare dall'agente discovery)

---

## 7. Gap Analysis

### Cosa esiste oggi

```
✓ agent_discovery          — manifest, nessun runner verificato
✓ agent_backlog_planner    — manifest + backlog-run.ps1 (platform-plan/apply mancano)
✓ agent_ado_userstory      — manifest con ado:prd.decompose (script mancante)
✓ agent_pr_gate            — operativo
✓ ewctl commit / Iron Dome — operativo
✓ branch policy develop/main — operativo
```

### Cosa manca

```
❌ New-PbiBranch.ps1              — IL MISSING LINK (prio 1)
❌ agent-ado-prd.ps1              — PRD → PBI su ADO (prio 2)
❌ platform-plan.ps1              — WhatIf backlog (prio 3)
❌ platform-apply.ps1             — Apply backlog (prio 3)
❌ skill_ba_discovery/            — importazione da .agents/skills (prio 2)
❌ skill_pm_prd/                  — importazione da .agents/skills (prio 2)
```

### Il gap critico (causa root del problema originale)

Il collegamento `PBI ID → branch name → PR body` non è mai stato implementato. Il developer non ha un tool che faccia questo automaticamente, quindi lo dimentica.

---

## 8. Piano di Implementazione

### Step 1 — `New-PbiBranch.ps1` (Session 40, priorità immediata)

**Cosa fa:**
```powershell
pwsh agents/skills/git/New-PbiBranch.ps1 -PbiId 123 [-DryRun]
```

**Comportamento:**
1. Fetch work item `123` da ADO API → title + acceptance criteria
2. Genera slug: `feat/PBI-123-<title-kebab-case>`
3. `git checkout -b feat/PBI-123-<slug>`
4. Stampa PR description template (copy-paste ready):
   ```
   [PBI-123] Title

   AB#123

   ## Acceptance Criteria
   <AC dal work item ADO>

   ## Test Plan
   - [ ] <AC1>
   - [ ] <AC2>
   ```
5. Con `-DryRun`: mostra senza creare il branch

**Registrazione**: in `agents/skills/registry.json` come `git.new-pbi-branch`

---

### Step 2 — `agent-ado-prd.ps1` (Sessione futura)

**Cosa fa:**
Legge un `PRD.md`, lo decompone in Epic/Feature/PBI (con LLM), mostra WhatIf, crea su ADO dopo conferma.

**Input:** path PRD.md
**Output:** lista PBI ID + AC per ogni PBI → feed automatico verso `New-PbiBranch.ps1`

---

### Step 3 — Import skill BA + PM (Sessione futura)

Copia `business-analyst/` e `product-manager/` da `.agents/skills/` in `agents/skills/` con adattamento alle convenzioni EasyWay (manifest `registry.json`, path, naming).

---

## 9. Lessons Learned

| # | Lesson | Applicazione |
|---|--------|-------------|
| L1 | Risolvi il "last mile" prima dell'upstream | `New-PbiBranch.ps1` prima di `agent-ado-prd.ps1` |
| L2 | Ogni tool deve funzionare in isolamento | Fallback manuale per ogni step del flusso |
| L3 | WhatIf obbligatorio per operazioni irreversibili su ADO | WhatIf gate prima di ogni Apply |
| L4 | La cosa giusta deve essere più facile di quella sbagliata | Branch naming con PBI ID rende il link ADO automatico |
| L5 | Non costruire il mega-agente — componi script piccoli | Pipeline: `New-PbiBranch` + `agent-ado-prd` + `agent_discovery` come pezzi separati |

---

## Riferimenti

- `#innovazione_agenti/EASYWAY_AGENTIC_SDLC_MASTER.md` — visione SDLC agentico
- `agents/agent_ado_userstory/manifest.json` — ado:prd.decompose
- `agents/agent_backlog_planner/manifest.json` — backlog WhatIf/Apply
- `Wiki/EasyWayData.wiki/agents/platform-operational-memory.md` — sessioni operative
- `Wiki/EasyWayData.wiki/guides/ado-session-awareness.md` — ADO briefing Layer 0
- `C:\old\.agents\skills\` — skill staging area (business-analyst, product-manager, azure-devops)
