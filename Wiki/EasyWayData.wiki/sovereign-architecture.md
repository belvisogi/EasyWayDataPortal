# Sovereign Architecture (The Brain) 🧠

> **"Ownership is the only true security."**

Questa sezione documenta l'infrastruttura "Sovereign" di EasyWay One.

## 1. Core Concepts
*   **[Market Gap & Philosophy](../docs/concepts/market_gap.md)**: Perché abbiamo costruito questo stack invece di usare SaaS.
*   **[MinIO Sovereign Storage](../docs/concepts/minio_sovereign_storage.md)**: Il nostro "Vault" locale (vs Azure Data Lake).
*   **[RAG Visual Flow](../docs/design/rag_visual_flow.md)**: Come un documento diventa intelligenza (Diagramma).

## 2. Architecture Reference
*   **[Sovereign Appliance Model](architecture/appliance_model.md)**: The "Mac Mini" Concept. One Server = Public Website + Private Intranet.
*   **[Sovereign Stack Overview](../docs/architecture/sovereign_stack_overview.md)**: MinIO + ChromaDB + n8n + Docker.
*   **[Docker Compose (Infra)](../docker-compose.infra.yml)**: La definizione dello stack "Ferro".
*   **[Docker Compose (Apps)](../docker-compose.apps.yml)**: La definizione dello stack "Applicativo".

## 3. Developer Standards
*   **[n8n Workflow Standards](../docs/standards/n8n_workflow_standard.md)**: Naming convention, Error Handling, e struttura delle cartelle.
*   **[Templates](../agents/core/n8n/Templates)**: I pattern standard da clonare (Master, Pipeline).

## 4. Production Environment (Oracle ARM) ☁️
*   **Infrastructure**: Oracle Cloud Free Tier (ARM Ampere).
*   **IP**: `80.225.86.168`
*   **Access Control (Split-Router Strategy)**:
    *   **Public Zone** (`/`, `/demo.html`): Marketing Website (Free Access).
    *   **Private Zone** (`/memory.html`, `/n8n/`): Sovereign Intranet (Protected by Basic Auth).
*   **[Frontend Architecture](../frontend/hextech_ui_framework.md)**: The "Hextech" Design System & Page Catalog.
*   **[🚨 DISASTER RECOVERY PROTOCOL](../Runbooks/SERVER-REBUILD-PROTOCOL.md)**: How to rebuild the server in < 15 mins.

## 5. Operational Manuals
*   **Porte Firewall**: 80/443 (Public), others blocked by UFW.
*   **Utenti Default**: `ubuntu` (SSH), `easywayadmin` (MinIO).

