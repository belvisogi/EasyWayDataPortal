---
title: "Documentation Audit Guide"
category: standards
domain: docs
tags: docs, audit, governance, wiki
priority: high
audience:
  - technical-writers
  - developers
last-updated: 2026-01-17
---

# 📝 Documentation Audit & Review

Guida all'utilizzo degli strumenti automatici per garantire la qualità della Wiki e della documentazione tecnica.

## 🕵️‍♂️ Consultant Mode (Audit Plan)

Il sistema offre una modalità "Consulente" che analizza lo stato della documentazione senza applicare modifiche massive alla cieca.

### Come Eseguire
```powershell
pwsh scripts/agent-docs-review.ps1 -Interactive
```
Selezionando "Wiki Normalize & Review", l'agente genererà un **Audit Plan** in `out/docs/audit_plan_wiki.md`.

### Cosa Analizza
1.  **Tag Taxonomy**: Verifica che i tag usati nel frontmatter siano conformi alla lista approvata.
2.  **Broken Links**: Analizza tutti i link interni, inclusi i link stile Obsidian (`[[Page]]` o `[[Page|Label]]`).
    - Supporta path relativi e assoluti (Wiki root).
    - Rileva ancore mancanti (`#section`).
3.  **Visual Hierarchy**: Ricostruisce l'albero logico della documentazione basandosi su path e contenuto.
4.  **Health Score**: Fornisce un punteggio sintetico di salute della Wiki (KPI).

## 🔗 Link Checker (Obsidian Support)

Lo script `wiki-links-anchors-lint.ps1` è stato potenziato per supportare nativamente la sintassi Wiki-Link:
- **Standard**: `[Label](path/to/file.md)`
- **Obsidian**: `[[Page Name]]` (risolto come `Page Name.md` nella directory corrente o root).

## 🛠️ Automated Fixes

Dopo aver visionato l'Audit Plan, è possibile lanciare gli script in modalità "Fix":
- **Metadati**: `wiki-frontmatter-autofix.ps1`
- **Indici**: `generate-master-index.ps1` (rigenera `index.md` e cataloghi JSONL per RAG).

## 🎲 Il "Game Gerarchico" (Tag Inference)

Il sistema utilizza una logica a 3 livelli ("The Hierarchy Game") per inferire e validare i tag:

1.  **Livello 1: Path Inference (Context)** 📂
    *   **Logica**: "Dimmi dove sei e ti dirò chi sei".
    *   **Tool**: `wiki-tags-lint.ps1`.
    *   **Esempio**: Un file in `domains/db/` riceve automaticamente `domain/db`.

2.  **Livello 2: Content Scanning (Semantics)** 📝
    *   **Logica**: "Dimmi cosa scrivi e ti dirò cosa tratti".
    *   **Tool**: `agent-docs-scanner.ps1`.
    *   **Esempio**: Se il testo contiene "SELECT", "Table", "FK", il sistema suggerisce `domain/db` anche se il file è altrove.

3.  **Livello 3: Hierarchy Audit (Governance)** ⚖️
    *   **Logica**: "Conformità alla Legge (Tassonomia)".
    *   **Tool**: `agent-docs-scanner.ps1 -Action AuditHierarchy`.
    *   **Azione**: Verifica che i tag usati esistano nel Grafo della Conoscenza (`knowledge-graph.json`) e segnala "Tag Orfani" o "Exotic Tags" da normare.
