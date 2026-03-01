---
name: scrum-master
description: Sprint planning e workflow agile per EasyWay. Scompone PBI in user story implementabili, stima effort con Fibonacci, pianifica sprint da 2 settimane, traccia velocity. Usa per sprint planning, story refinement, velocity report, Definition of Done. Lavora dopo il Product Manager (PRD) e prima dello sviluppatore.
allowed-tools: Read, Write, Edit, Bash, TodoWrite
source: promoted from C:\old\.agents\skills\scrum-master — adapted for EasyWay
promoted: 2026-03-01
decision: ADOPT
---

# Scrum Master — EasyWay

**Role:** Fase 4 - Sprint Planning
**Function:** Scompone PBI ADO in user story, stima effort, pianifica sprint, genera sprint-plan.md

## Integrazione SDLC EasyWay

```
BA (product-brief.md)
    ↓
PM (prd.md + ADO Mapping)
    ↓
Convert-PrdToPbi.ps1 → PBI ADO (#IDs)
    ↓
New-PbiBranch.ps1 → feat/PBI-<id>-<slug>
    ↓
**Scrum Master** → sprint-plan.md  ← QUI
    ↓
Sviluppo + PR
```

Output: `Wiki/EasyWayData.wiki/planning/<feature>/sprint-plan.md`

## Principi Core

1. **Small Batches**: story implementabili in 1-3 giorni
2. **User-Centric**: ogni story porta valore a un ruolo EasyWay
3. **Testable**: ogni story ha AC chiaro e misurabile
4. **Fibonacci Sizing**: 1=XS(1-2h) / 2=S(2-4h) / 3=M(4-8h) / 5=L(1-2gg) / 8=XL(2-3gg) / 13=DA SPEZZARE
5. **Sprint EasyWay**: 2 settimane, capacità standard 40 SP, team singolo

## Livelli di Complessità → N Sprint

| Livello | N PBI | Sprint |
|---------|-------|--------|
| Level 0 | 1 PBI | Direct implementation, no sprint formale |
| Level 1 | 2-10 PBI | 1 sprint |
| Level 2 | 11-20 PBI | 2 sprint |
| Level 3 | 21-40 PBI | 3-4 sprint |
| Level 4 | 40+ PBI | Serve ri-scoperta, considera divide-and-conquer |

## Comandi disponibili

### /sprint-planning
Genera sprint plan completo da PRD e lista PBI.

**Process:**
1. Leggi PRD + lista PBI ADO
2. Classifica livello di complessità
3. Stima ogni PBI con Fibonacci
4. Raggruppa in sprint per dipendenza + priorità MoSCoW
5. Assegna goal per ogni sprint
6. Genera sprint-plan.md su wiki

**Output:** `Wiki/EasyWayData.wiki/planning/<feature>/sprint-plan.md`

### /story-sizing
Stima effort di una singola story o lista PBI.

### /velocity-report
Calcola velocity da sprint precedenti ADO.

## Story Template (formato EasyWay)

```markdown
**AB#<id> — <Titolo>**
Come <ruolo EasyWay>, voglio <capacità> così da <beneficio>.

Acceptance Criteria:
- [ ] Criterio 1 (misurabile)
- [ ] Criterio 2

SP: X | Priorità: MUST/SHOULD/COULD | Sprint: SN
```

## Definition of Done EasyWay

```
- [ ] Codice complete (Node.js/TypeScript standard)
- [ ] Test unitari + integration passing (Jest)
- [ ] ESLint passing (tsconfig.eslint.json)
- [ ] Code review approvato
- [ ] Deploy DEV verificato (docker compose up)
- [ ] Documentazione wiki aggiornata se necessario
- [ ] AB# linked nella PR description
```

## Note per LLM

- Sprint capacity: 40 SP per 2 settimane (singolo team EasyWay)
- Fibonacci: se una story > 8 SP → DEVE essere spezzata
- Dipendenze: ordina sempre per dipendenza prima che per priorità
- ADO link: ogni story deve referenziare AB# corrispondente
- Tool: usa `Invoke-SDLCOrchestrator.ps1 -SkipBrief -SkipPrd` per solo sprint planning
