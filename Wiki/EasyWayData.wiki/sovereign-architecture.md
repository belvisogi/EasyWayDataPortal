# Sovereign Architecture (The Brain) 🧠

> **"Ownership is the only true security."**

Questa sezione documenta l'infrastruttura "Sovereign" di EasyWay One.

## 1. Core Concepts
*   **[Market Gap & Philosophy](../docs/concepts/market_gap.md)**: Perché abbiamo costruito questo stack invece di usare SaaS.
*   **[MinIO Sovereign Storage](../docs/concepts/minio_sovereign_storage.md)**: Il nostro "Vault" locale (vs Azure Data Lake).
*   **[RAG Visual Flow](../docs/design/rag_visual_flow.md)**: Come un documento diventa intelligenza (Diagramma).

## 2. Architecture Reference
*   **[Sovereign Stack Overview](../docs/architecture/sovereign_stack_overview.md)**: MinIO + ChromaDB + n8n + Docker.
*   **[Docker Compose (Infra)](../docker-compose.infra.yml)**: La definizione dello stack "Ferro".
*   **[Docker Compose (Apps)](../docker-compose.apps.yml)**: La definizione dello stack "Applicativo".

## 3. Developer Standards
*   **[n8n Workflow Standards](../docs/standards/n8n_workflow_standard.md)**: Naming convention, Error Handling, e struttura delle cartelle.
*   **[Templates](../agents/core/n8n/Templates)**: I pattern standard da clonare (Master, Pipeline).

## 4. Operational Manuals
*   **Porte Firewall**: 9000 (API), 9001 (Console MinIO), 8080 (Frontend), 5678 (n8n).
*   **Utenti Default**: `easywayadmin` (MinIO).
