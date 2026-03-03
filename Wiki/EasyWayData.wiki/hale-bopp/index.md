---
title: HALE-BOPP — Open-Source Data Infrastructure
id: ew-hale-bopp-index
status: active
tags:
  - domain/hale-bopp
  - layer/architecture
  - language/en
owner: team-data-platform
created: '2026-03-03'
updated: '2026-03-03'
summary: >
  HALE-BOPP is the open-source "muscles" layer of the EasyWay ecosystem —
  three deterministic engines for schema governance, ETL orchestration, and
  policy gating, designed to work standalone or as EasyWay's execution tier.
type: reference
llm:
  include: true
  pii: none
  chunk_hint: 350
  redaction: []
related:
  - '[[./strategy-and-architecture.md|Strategy & Architecture]]'
  - '[[./api-contracts.md|API Contracts]]'
  - '[[./hale-bopp-db/index.md|DB-HALE-BOPP]]'
  - '[[./hale-bopp-etl/index.md|ETL-HALE-BOPP]]'
  - '[[./hale-bopp-argos/index.md|ARGOS-HALE-BOPP]]'
  - '[[../architecture/sovereign-gap-fillers.md|Sovereign Gap Fillers]]'
entities: []
---
# HALE-BOPP — Open-Source Data Infrastructure

## Questions answered
- What is HALE-BOPP and how does it relate to EasyWay?
- What are the three HALE-BOPP engines?
- How do the "Brain" (EasyWay) and "Muscles" (HALE-BOPP) work together?
- Can HALE-BOPP be used without EasyWay?

## Overview

HALE-BOPP is an ecosystem of **three deterministic, AI-free engines** that handle the heavy-lifting of data infrastructure. It follows the **"Brain vs Muscles"** paradigm:

| Layer | Repository | Nature | Role |
|-------|-----------|--------|------|
| **Brain** | EasyWay (private) | AI agents, RAG, UI | Decides, reasons, communicates |
| **Muscles** | HALE-BOPP (open-source) | Deterministic engines | Executes, enforces, moves data |

The engines are blind and mute — they produce structured events but never interpret them. EasyWay agents consume those events and translate them into human-readable insights.

## The Three Engines

### DB-HALE-BOPP — Schema Governance
The **flagship** module. A deterministic schema governance engine for PostgreSQL (and eventually multi-DB). Positioned as a "Flyway killer" with drift detection.

- CLI tool: `halebopp diff | deploy | drift | snapshot`
- REST API on port **8100**
- Key capabilities: schema diff, transactional deploy with rollback, drift detection, baseline snapshots
- Stack: Python, FastAPI, SQLAlchemy, Click
- [[./hale-bopp-db/index.md|Full documentation]]

### ETL-HALE-BOPP — Data Orchestration
Config-driven ETL orchestration. Currently built on Airflow scaffolding, planned to be rewritten as a lightweight custom runner (~300 lines).

- Pipeline definitions via YAML
- DAG generation from configuration
- Webhook integration for external automation
- [[./hale-bopp-etl/index.md|Full documentation]]

### ARGOS-HALE-BOPP — Policy & Gating Engine
The governance control plane. Evaluates metadata (never touches raw data) to make pass/fail decisions on pipelines and schema changes.

- Three pillars: **M1** (Fast-Ops gating), **M2** (Biz-Learning coach), **M3** (Tech-Profiling)
- REST API on port **8200**
- Rule engine with configurable policies
- Strategic direction: will become a Python library (not a standalone HTTP service)
- [[./hale-bopp-argos/index.md|Full documentation]]

## Composable Architecture

Every module is opt-in. An organization can install:
- Only **DB-HALE-BOPP** to govern database schemas
- Only **ETL-HALE-BOPP** to orchestrate pipelines
- Any combination — ARGOS adds quality gates when present, but nothing breaks without it

## Integration with EasyWay

When deployed together, the flow is:

1. HALE-BOPP engines emit structured events (Universal Event Schema)
2. EasyWay agents (`agent_dba`, `agent_infra`) listen for those events
3. Agents use LLM intelligence to interpret, decide, and communicate to humans

See [[./api-contracts.md|API Contracts]] for the full event schema and integration flows.

## Port Allocation

| Service | Port | Protocol |
|---------|------|----------|
| DB-HALE-BOPP | 8100 | HTTP/REST |
| ARGOS-HALE-BOPP | 8200 | HTTP/REST |
| ETL-HALE-BOPP | 3000 | HTTP/GraphQL |
| PostgreSQL (shared metadata) | 5432 | TCP |

## Project Status

- **ADO**: Epic #30, 7 PBIs (#31-#37)
- **Sprint 1**: Completed — CLI tool, baseline management, deploy with audit log, 17 tests passing
- **Next**: PostgreSQL integration tests, pip packaging, ETL rewrite PRD
- **Source**: `C:\old\HALE-BOPP\` (local), GitHub mirror planned
