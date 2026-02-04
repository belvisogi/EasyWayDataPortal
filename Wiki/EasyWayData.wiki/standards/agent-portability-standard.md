---
id: ew-standards-agent-portability-standard
title: Agent Architecture Standard: The "Portable Brain" Pattern 🧠
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/spec, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# Agent Architecture Standard: The "Portable Brain" Pattern 🧠

## 1. Core Principle
Agents MUST be designed to separate **Function** (Tools/RAG) from **Intelligence** (LLM).
The Intelligence layer MUST be swappable via configuration, never hardcoded.

## 2. Implementation Standard (PowerShell/Python)
Every Agent Script MUST support the following standard parameters:

```powershell
param(
    # The input query/task
    [string]$Query,

    # The Intelligence Provider (Switch)
    [ValidateSet("Ollama", "DeepSeek", "OpenAI", "AzureOpenAI")]
    [string]$Provider = "Ollama",

    # The specific model identifier (Model Agnostic)
    [string]$Model = "deepseek-r1:7b",

    # API Key (Optional, for Cloud Providers)
    [string]$ApiKey
)
```

## 3. The "Hybrid RAG" Pattern
- **Data (Memory)**: ALWAYS Local (ChromaDB/SQLite) on the Node.
- **Compute (Brain)**: 
    - **Development/Test**: Local LLM (Ollama/TinyLlama) -> Zero Cost.
    - **Production**: Cloud API (DeepSeek/OpenAI) -> High IQ, Low Latency.
    - **High Security**: On-Prem GPU -> Local Smart Model.

## 4. Why?
This ensures EasyWay Agents are **Infrastructure Agnostic**.
We can deploy the *exact same code* on a free Oracle server (using API) or a high-end GPU workstation (using Local LLM) just by changing a CLI flag.



