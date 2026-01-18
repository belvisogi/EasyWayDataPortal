---
title: "Agent Runtime Lifecycle & Memory Architecture"
category: concept
domain: agent-core
tags: architecture, memory, concurrency, runtime
priority: high
last-updated: 2026-01-17
---

# 🧠 Agent Runtime Lifecycle & Memory

Questo documento definisce come gli agenti "pensano", "ricordano" e "cooperano" a runtime. Definisce il sistema nervoso dell'ecosistema EasyWay.

## 1. The 3-Layer Memory Architecture

Proponiamo una struttura di memoria a 3 livelli, ispirata alla cognizione umana:

### Layer 1: Working Memory (Short-Term) ⚡
*   **Scopo**: Mantenere lo stato del task corrente. "Cosa sto facendo ora?".
*   **Persistence**: Effimera (dura quanto il task/sessione).
*   **Location**: `agents/<agent_name>/memory/session_active.json`
*   **Struttura**:
    ```json
    {
      "session_id": "uuid-1234",
      "start_time": "2026-01-17T21:00:00Z",
      "intent": "Scaffold new API agent",
      "plan": [
        { "step": 1, "desc": "Create Dir", "status": "done" },
        { "step": 2, "desc": "Write Manifest", "status": "pending" }
      ],
      "variables": { "target_dir": "agents/agent_new" }
    }
    ```

### Layer 2: Episodic/Context Memory (Medium-Term) 📂
*   **Scopo**: Ricordare preferenze, contesto del progetto corrente o risultati recenti. "Cosa so di questo utente/progetto?".
*   **Persistence**: Persistente (dura tra le sessioni).
*   **Location**: `agents/<agent_name>/memory/context.json`
*   **Struttura**:
    ```json
    {
      "user_preferences": { "language": "it", "theme": "dark" },
      "last_interaction": "2026-01-16",
      "project_context": { "current_sprint": "Sprint 42" }
    }
    ```

### Layer 3: Semantic Knowledge (Long-Term) 📚
*   **Scopo**: Conoscenza cristallizzata, fatti, storia. "Cosa so del mondo?".
*   **Persistence**: Permanente (Wiki, Graph).
*   **Location**:
    *   **History**: `Wiki/EasyWayData.wiki/concept/history.md` (Gestito da *Chronicler*).
    *   **Map**: `Wiki/EasyWayData.wiki/concept/dependency-graph.md` (Gestito da *Cartographer*).
    *   **Docs**: Intera Wiki.

---

## 2. Concurrency & Locking (The "Traffic Light") 🚦

Quando due agenti operano simultaneamente, rischiano conflitti (es. scelgono lo stesso nome file o modificano lo stesso documento).

### File-Based Locking Strategy
Per evitare complessità di database, usiamo lock su file system.

1.  **Lock Acquisition**: Prima di un'azione critica (es. scrittura), l'agente controlla se esiste `path/to/resource.lock`.
2.  **Wait**: Se esiste, attende (backoff esponenziale).
3.  **Action**: Se libero, crea `.lock`, scrive, rimuove `.lock`.

### The "Dopamine Dispatcher" (Future)
In futuro, un *Orchestrator Agent* centralizzato gestirà una `Input Queue`.
*   Tutti gli input vanno in `work/queue/incoming/`.
*   L'Orchestrator assegna il task all'agente libero.
*   L'agente sposta il task in `work/queue/processing/`.

---

## 3. Runtime Lifecycle (OODA Implementation)

Il ciclo di vita di ogni esecuzione Brain segue questi step:

1.  **Boot**: Carica `manifest.json` + `memory/context.json`.
2.  **Observe**: Legge l'input utente.
3.  **Orient**:
    *   Consulta `dependency-graph.md` (Impact Analysis).
    *   Consulta `agent-architecture-standard.md` (Rules).
4.  **Decide**:
    *   Aggiorna `memory/session_active.json` con il piano.
    *   Consulta GEDI (se necessario).
5.  **Act**: Esegue gli script Arm.
6.  **Reflect**:
    *   Aggiorna `memory/context.json` (es. "L'utente ha approvato X").
    *   Se successo importante -> Chiama *Chronicler*.
    *   Pulisce `memory/session_active.json`.

---
**Stato**: Proposal
**Owner**: Platform Team
