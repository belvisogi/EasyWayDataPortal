---
id: user-guide
title: Guida Utente EasyWay
summary: Manuale operativo per interagire con l'Intelligenza Artificiale EasyWay.
audience: Data Analysts, Developers
status: stable
updated: 2026-01-27
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

# 📘 Guida Utente EasyWay (The Hitchhiker's Guide to the Data Portal)

> **"Don't Panic. Ask the Agent."**

## 1. Che cos'è EasyWay? 🧠
EasyWay non è solo un "database". È un sistema dotato di **Memoria Semantica** (RAG).
Lui *legge* la documentazione (Wiki, PDF, Codice) e *risponde* alle tue domande.

**Cosa può fare:**
*   🔍 **Rispondere**: "Come configuro Azure DevOps?"
*   📝 **Scrivere**: "Generami un template per una User Story."
*   ⚙️ **Agire**: "Estrai i dati dall'ultimo Sprint." (Tramite n8n).

---

## 2. Come parlarci? (Interfacce) 🗣️

Attualmente ci sono 3 modi per interagire con il sistema.

### Modo A: La "Matrix" (Terminale SSH) 💻
Per gli utenti tecnici che hanno accesso al server.

1.  Collegati in SSH: `ssh easyway@server`
2.  Lancia il comando magico:
    ```powershell
    easyway-ask "Come faccio a creare un nuovo agente?"
    ```
3.  **Opzioni Avanzate**:
    *   `-Model "deepseek"`: Usa il cervello superiore (Cloud).
    *   `-Model "llama"`: Usa il cervello locale (Privacy totale).

### Modo B: Il "Flusso" (n8n) 🌊
Per chi vuole automatizzare i processi.
L'agente vive dentro **n8n** come un nodo "HTTP Request".

*   **Endpoint**: `http://localhost:5678/webhook/ask-agent`
*   **Method**: `POST`
*   **Body**: `{"query": "La tua domanda"}`

### Modo C: La "Faccia" (GUI) 🖼️
*(Coming Soon - Phase 14)*
Stiamo costruendo un'interfaccia web moderna ("Iron Man Suit").
Sarà accessibile da browser senza bisogno di SSH o n8n.

---

## 3. Esempi Pratici (Cosa chiedere?) 💡

### Scenario 1: Onboarding
> **Q**: *"Cos'è lo standard TESS?"*
> **A**: *"TESS (The EasyWay Server Standard) è l'insieme di regole che definisce come devono essere configurati i server..."*

### Scenario 2: DevOps
> **Q**: *"Dammi il comando per fare il prune di Docker."*
> **A**: *"Puoi usare `docker system prune -f`. Attenzione: rimuove tutte le immagini non usate..."*

### Scenario 3: Business Understanding
> **Q**: *"Qual è la vision del progetto EasyWay?"*
> **A**: *"Democratizzare l'accesso ai dati tramite un'interfaccia a linguaggio naturale..."*

---

## 4. Troubleshooting (Se si rompe) 🔧

*   **Risposte Lente**: Se usa il modello locale su CPU ARM, può impiegare 30-60 secondi. Porta pazienza.
*   **Allucinazioni**: Se inventa cose, prova a chiedergli di "citare la fonte" o usa il modello `deepseek` via API.
*   **Errori 500**: Contatta il team DevOps (o controlla se il container n8n è su).

---
*Manuale aggiornato al: 2026-01-27*

