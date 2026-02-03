---
id: ew-archive-imported-docs-2026-01-30-architecture-sovereign-stack-overview
title: The Sovereign Stack: Architecture Overview 🏛️
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
---
# The Sovereign Stack: Architecture Overview 🏛️

> **"Ownership is the only true security."**

Questo documento unifica i concetti dell'infrastruttura EasyWay One installata.

## 1. The Foundation (Il Ferro) 🏗️
Gestito via `docker-compose.infra.yml`.
Questi servizi sono "Stateful" (contengono i dati preziosi).

*   **MinIO (The Vault)** 🎒
    *   *Ruolo*: Object Storage S3-Compatible.
    *   *Dati*: PDF, Docx, Immagini, Backup.
    *   *Perché*: Sovranità sui file, Air-Gap capable.
    *   *Doc*: [MinIO Concept](../concepts/minio_sovereign_storage.md)

*   **ChromaDB (The Memory)** 🧠
    *   *Ruolo*: Vector Database.
    *   *Dati*: Embeddings (concetti matematici estratti dai file).
    *   *Perché*: Permette la Ricerca Semantica ("Cerca il significato, non la keyword").

*   **SQL Edge (The Ledger)** 📒
    *   *Ruolo*: Relational DB (SQL Server).
    *   *Dati*: Utenti, Log, Transazioni strutturate.
    *   *Perché*: Compatibilità Legacy con i sistemi aziendali esistenti.

## 2. The Application (L'Intelligenza) 💡
Gestito via `docker-compose.apps.yml`.
Questi servizi sono "Stateless" (logica pura).

*   **EasyWay Frontend (The Pulse)** 💓
    *   *Ruolo*: L'Interfaccia Umana (Single Page App).
    *   *Tech*: Vanilla JS/Vite (No Framework bloat).
    *   *Funzione*: Drag & Drop, Chat, Visualization.

*   **n8n (The Nervous System)** ⚡
    *   *Ruolo*: Orchestratore di Flussi.
    *   *Funzione*: Collega il Pulse al Vault e alla Memory. Esegue la logica di business.

## 3. The Data Flow (Il Flusso) 🌊
Vedi [RAG Visual Flow](../design/rag_visual_flow.md) per il dettaglio.
1.  **Ingestion**: Pulse -> n8n -> MinIO -> Chroma.
2.  **Retrieval**: Pulse -> n8n -> Chroma -> MinIO -> LLM -> Pulse.

## 4. Why We Exist (Philosophy)
Vedi [Market Gap](../concepts/market_gap.md).
Siamo qui per democratizzare l'architettura Enterprise, rendendola accessibile (Docker) e Sovrana (No SaaS lock-in).


