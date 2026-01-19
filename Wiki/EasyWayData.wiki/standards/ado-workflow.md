---
title: "ADO Execution Rules"
category: standards
domain: ado
tags: ado, devops, governance, workflow
priority: critical
audience:
  - developers
  - scrum-masters
  - ai-assistants
last-updated: 2026-01-17
---

# ⚡ ADO Execution Rules

Regole di ingaggio per l'interazione con Azure DevOps (ADO) tramite script e AI.

> **REGOLA D'ORO**: Governance First. Le interrogazioni ambigue devono passare dal livello di Governance per risolvere il contesto (Area/Team) prima dell'esecuzione.

## 🎯 Workflow Operativo

### 1. Visualizzazione (Read-Only)
Le operazioni di lettura specifiche sono **sempre sicure** e possono essere eseguite direttamente.
- **PBI ID**: `axctl --intent pbi <ID>`
- **Children**: `axctl --intent children -- <ID>`
- **Pipeline**: `axctl --intent pipeline <ID>`

### 2. Export & Query (Governance Managed)
Le operazioni di export massivo o query generiche devono seguire il flusso **Governance First**:
1.  **Request**: Utente chiede "Dammi i PBI di..."
2.  **Governance Check**: 
    - Se l'utente specifica un ID o una query precisa -> **Execute**.
    - Se la richiesta è ambigua ("Dammi i PBI del team") -> **Stop & Suggest**.
3.  **Suggestion**:
    - Il sistema elenca i Team disponibili (`ado:teams.list`).
    - L'utente seleziona Team -> Area -> Iteration.
4.  **Execution**: Il sistema lancia la query precisa (`agent-ado-scrummaster.ps1`).

### 3. Modifiche (Write)
Le operazioni di creazione/modifica/cancellazione richiedono **sempre** conferma esplicita (SafeToAutoRun=false).

## 🛠️ Tools & Scripts

| Tool | Scopo | Note |
|------|-------|------|
| `adosearch.ps1` | Wizard Interattivo | Guida l'utente nella selezione Team/Area/Iteration |
| `agent-ado-scrummaster.ps1` | Esecutore Backlog | Gestisce User Stories, PBI, Bugs. Include "Smart Guardrail". |
| `agent-ado-governance.ps1` | Orchestratore | Risolve intenti, liste Team, strutture di progetto. |

## 📋 Decision Tree (AI Logic)

```sql
User Request
├─ Richiesta di VISUALIZZAZIONE? (ID Specifico)
│  └─ ESEGUI DIRETTO (Fast Lane)
│
├─ Richiesta di EXPORT/QUERY?
│  ├─ "Export PBI SID" (Query Precisa) → ESEGUI
│  └─ "Dammi i PBI..." (Generica)      → GOVERNANCE (Mostra Team -> Chiedi Area)
│
└─ Richiesta di MODIFICA?
   └─ CHIEDI CONFERMA
```sql
