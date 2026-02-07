---
type: guide
status: draft
tags:
  - domain/process
  - tool/agent
created: 2026-02-04
---

# 🎬 Agentic Workflow: Use Cases

Scenari operativi per testare il "Consiglio degli Agenti" su GitLab.

---

## SCENARIO 1: The "Standard Feature" Flow 🟢

**Obiettivo**: Aggiungere una feature non critica.
**Attori**: `agent_developer`, `agent_guard`, `agent_release`.

1.  **Trigger**: Umano assegna ticket `PBI-101: Add Login` a `agent_developer`.
2.  **Action (Dev)**:
    *   `git checkout -b feature/PBI-101-login`
    *   `git push`
    *   `Open Merge Request`
3.  **Check (Guard)**:
    *   Rileva MR.
    *   Verifica pattern branch: `feature/PBI-.*` ✅.
    *   Verifica target: `develop` ✅.
    *   Esito: **PASS**.
4.  **Merge (Release)**:
    *   Pipeline passa.
    *   Reviewer Umano approva.
    *   `agent_release` esegue Merge.

---

## SCENARIO 2: The "Rogue Vendor" Flow 🔴

**Obiettivo**: Impedire a un fornitore di rompere la produzione.
**Attori**: Vendor, `agent_guard`.

1.  **Trigger**: Vendor pusha branch `fix-urgente` e apre MR verso `main`.
2.  **Check (Guard)**:
    *   Rileva MR.
    *   Verifica pattern branch: `fix-urgente` ❌ (Manca PBI).
    *   Verifica target: `main` ❌ (Vietato da feature).
    *   Esito: **BLOCK**.
3.  **Action**:
    *   Guard chiude la MR.
    *   Commenta: "Violazione Policy. Riaprire come hotfix/INC-... verso develop".

---

## SCENARIO 3: The "Release Train" Flow 🚂

**Obiettivo**: Portare le modifiche in Produzione (Giovedì).
**Attori**: `agent_release`.

1.  **Trigger**: Schedule (Giovedì 14:00).
2.  **Action**:
    *   Crea MR `Release v1.2.0` (`develop` -> `main`).
    *   Genera Release Notes dai commit.
3.  **Check**:
    *   Tutte le pipeline verdi.
4.  **Execution**:
    *   Merge su `main`.
    *   Tag `v1.2.0`.

---
