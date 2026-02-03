---
id: dual-stack-strategy
title: Architecture: Dual Stack Strategy (The Bridge) ☯️
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
entities: []
tags: [layer/reference, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
---
# Architecture: Dual Stack Strategy (The Bridge) ☯️

> "Un codice, due anime."

## Overview
EasyWayDataPortal adopts a **Dual Stack** architecture. This allows the same core agent logic to run in two distinct environments without code duplication.

1.  **Enterprise Edition (Cloud Native)**: The full-power version running on Azure Cloud.
2.  **Framework Edition (The Gift)**: The portable version running on Local Containers (Docker).

## The Core Concept: Provider Pattern 🧩
Instead of cluttering scripts with `if ($local)` checks, we use an **Abstraction Layer** for all external dependencies (Memory, Storage, Database).

```mermaid
graph TD
    A[Agent Logic] -->|Calls| B{Abstraction Interface}
    B -->|Mode: Enterprise| C[Azure Provider]
    B -->|Mode: Framework| D[Local Provider]
    
    C -->|Connects to| E[Azure SQL]
    C -->|Connects to| F[Blob Storage]
    C -->|Connects to| G[Entra ID]
    
    D -->|Connects to| H[SQL Edge Container]
    D -->|Connects to| I[Azurite Container]
    D -->|Connects to| J[ChromaDB Vector Store]
```sql

## Matrix of Responsibilities

| Feature | Enterprise (Cloud) | Framework (Local) |
| :--- | :--- | :--- |
| **Orchestration** | Azure DevOps Pipelines | `agent-runner` Docker / Local PWSH |
| **Database** | Azure SQL Database (PaaS) | Azure SQL Edge (Container) |
| **File Storage** | Azure Blob Storage | Azurite (Emulator) |
| **Memory/Search** | Azure AI Search (Optional) | ChromaDB / LanceDB (Vector) |
| **Authentication** | Entra ID (Managed Identity) | API Key / No-Auth |
| **LLM Backend** | OpenAI On Your Data | DeepSeek / Gemini / Local LLM |

## Decision Rationale
We chose **Path A (Dual Stack)** over forking the project to ensure **Antifragility**.
*   Improvements in the Core Logic benefit both editions.
*   The Enterprise version remains the "Golden Standard".
*   The Framework version serves as a "Development Kit" and a "Gift" for SMBs.

## Implementation Details
The switch is controlled by the environment variable `$env:EASYWAY_MODE`.
*   `'Enterprise'` (Default): Loads `AzureMemoryProvider`.
*   `'Framework'`: Loads `LocalMemoryProvider`.



