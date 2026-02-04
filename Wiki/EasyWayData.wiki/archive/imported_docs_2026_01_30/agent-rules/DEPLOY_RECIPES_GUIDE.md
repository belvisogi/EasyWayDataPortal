---
id: ew-archive-imported-docs-2026-01-30-agent-rules-deploy-recipes-guide
title: 🚀 Deploy Recipes - Quick Reference
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# 🚀 Deploy Recipes - Quick Reference

**Created**: 2026-01-13  
**Total Recipes**: 12  
**Location**: `Rules.Vault/agents/kb/deploy-recipes.jsonl`

> [!IMPORTANT]
> **SAFE EXECUTION STRATEGY**: Per evitare blocchi o loop infiniti, usa **SEMPRE** l'approccio a 2 step per query pesanti:
> 1. **Export massivo** (Command: `ado export -WorkItemType "All"`)
> 2. **Filtro locale** (Command: `pwsh Rules/scripts/filter-export.ps1`)
> EVITA di eseguire query complesse con troppi join/WIQL direttamente su ADO se non necessario.

---

## 📋 Ricette Disponibili

### 1. Deploy Generali

**Trigger**: `"dammi i deploy 2025"`  
**Intent**: `ado:deploy.list`  
**Cosa fa**: 
1. `ado export -WorkItemType "All" -Query "...ChangedDate >= '2025-01-01'..."`
2. `pwsh Rules/scripts/filter-export.ps1 -Latest -TagContains "Deploy"`
**Flags**: autoExecute=true, safe=true

---

### 2. Deploy PROD Only

**Trigger**: `"deploy prod 2025"`  
**Intent**: `ado:deploy.prod`  
**Cosa fa**: Export → filtra WorkItemType='Deploy' (esclude Test Suite)  
**Use Case**: Solo deploy effettivi in produzione

---

### 3-5. Deploy per Progetto

**Triggers**:
- `"deploy air 2025"` → Tags contains 'AIR'
- `"deploy ifrs9 2025"` → Tags contains 'IFRS9'
- `"deploy ddt 2025"` → Tags contains 'DDT'

**Intent**: `ado:deploy.project`  
**Use Case**: Filtrare deploy per progetto specifico

---

### 6. Deploy Completati

**Trigger**: `"deploy completati 2025"`  
**Intent**: `ado:deploy.completed`  
**Cosa fa**: Export → filtra State='Done'  
**Use Case**: Solo deploy già andati in produzione

---

### 7. Deploy Attivi

**Trigger**: `"deploy attivi 2025"`  
**Intent**: `ado:deploy.active`  
**Cosa fa**: Export → filtra State IN ('New', 'Business Approved', 'In Progress')  
**Use Case**: Deploy in corso o pianificati

---

### 8. Release Focus

**Trigger**: `"release 2025"`  
**Intent**: `ado:deploy.release`  
**Cosa fa**: Export → filtra Tags/Title contains 'Release'  
**Use Case**: Include sia Deploy che Test Suite

---

### 9. Deploy per Quarter

**Trigger**: `"deploy q1 2025"`  
**Intent**: `ado:deploy.quarter`  
**Cosa fa**: Export → filtra CreatedDate tra 2025-01-01 e 2025-03-31  
**Use Case**: Analisi temporale per trimestre

---

### 10. Deploy Recenti

**Trigger**: `"ultimi deploy"`  
**Intent**: `ado:deploy.recent`  
**Cosa fa**: Export ultimi 30 giorni → top 10 deploy  
**Use Case**: Quick check deploy recenti

---

### 11. Statistiche Deploy

**Trigger**: `"quanti deploy 2025"`  
**Intent**: `ado:deploy.count`  
**Cosa fa**: Count items + breakdown per Type e State  
**Output**:
```
Deploy Type: X items
Test Suite: Y items
State Done: Z items
State In Progress: W items
```

---

### 12. Timeline Deploy

**Trigger**: `"deploy per mese 2025"`  
**Intent**: `ado:deploy.timeline`  
**Cosa fa**: Raggruppa per mese CreatedDate  
**Output**: Distribuzione temporale mensile

---

## 🔍 Pattern Matching

Tutte le ricette usano questi pattern per identificare deploy:

**Tags matching**:
- `Deploy`
- `Release`
- `Prod` / `Production`
- `Rilascio`

**Title matching**:
- Case-insensitive search
- Wildcards supportati

**WorkItemType**:
- `Deploy` (deploy effettivi)
- `Test Suite` (validation pre-deploy)

---

## 💡 Esempi d'Uso

### Scenario 1: Status Deploy Anno
```
User: "dammi i deploy 2025"
AI: Esegue export → applica pattern → mostra 70+ items
```

### Scenario 2: Deploy Progetto Specifico
```
User: "deploy air completati 2025"
AI: Combina filtri: AIR tag + State=Done + 2025
```

### Scenario 3: Analisi Temporale
```
User: "deploy per mese 2025"
AI: Raggruppa per mese → mostra distribuzione
```

---

## 🎯 Integrazione

Le ricette sono integrate in:
- ✅ `recipes.jsonl` (19 + 12 = 31 totali)
- ✅ ADO_EXPORT_GUIDE.md (sezione deploy identification)
- ✅ DOCS_INDEX.yaml (metadata aggiornato)

**L'AI ora riconosce automaticamente** tutte le varianti di richieste deploy!

---

## 📊 Coverage

**Dimensioni**:
- Temporale: Anno, Quarter, Ultimi X giorni
- Progetto: AIR, IFRS9, DDT, ecc.
- Stato: Done, Active, All
- Tipo: Deploy only, Test Suite, All

**Combinazioni**: ~50+ varianti coperte

---

## 🔧 Manutenzione

**Per aggiungere nuove ricette**:
1. Aggiungi line a `deploy-recipes.jsonl`
2. Rispetta formato JSON
3. Includi autoExecute/safe flags
4. Test con trigger phrase

**Pattern ID**: `kb-deploy-<variant>`

---

**Status**: ✅ Production Ready


