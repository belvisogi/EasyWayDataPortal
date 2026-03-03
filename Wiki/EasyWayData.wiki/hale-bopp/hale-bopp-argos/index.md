---
title: ARGOS-HALE-BOPP — Policy & Gating Engine
id: ew-hale-bopp-argos
status: active
tags:
  - domain/hale-bopp
  - module/hale-bopp-argos
  - layer/reference
  - language/en
owner: team-data-platform
created: '2026-03-03'
updated: '2026-03-03'
summary: >
  ARGOS-HALE-BOPP is the governance control plane of the HALE-BOPP ecosystem.
  A zero-data policy engine that evaluates metadata to make pass/fail decisions
  on pipelines and schema changes. Strategic direction: Python library.
type: reference
llm:
  include: true
  pii: none
  chunk_hint: 350
  redaction: []
related:
  - '[[../index.md|HALE-BOPP Overview]]'
  - '[[../api-contracts.md|API Contracts]]'
  - '[[../hale-bopp-db/index.md|DB-HALE-BOPP]]'
  - '[[../../argos/argos-overview.md|ARGOS (EasyWay context)]]'
entities: []
---
# ARGOS-HALE-BOPP — Policy & Gating Engine

## Questions answered
- What is ARGOS-HALE-BOPP?
- What are the three pillars (M1, M2, M3)?
- How does ARGOS interact with ETL and DB-HALE-BOPP?
- Can ARGOS be used standalone?
- What is the strategic direction (library vs service)?

## Overview

ARGOS-HALE-BOPP sits at the top of the HALE-BOPP trinity. It is a **zero-data** framework — it never processes actual data rows, only **metadata** — to make governance decisions.

If ETL moves the data and DB governs the schema, ARGOS answers: **"Who governs the orchestration?"**

## The Three Pillars

### M1 — Fast-Ops (Gating)
The wall guard. Evaluates incoming events against policies and makes immediate pass/fail decisions.

- DB-HALE-BOPP reports unauthorized drift -> M1 blocks the pipeline
- ETL fails a data quality check -> M1 quarantines the data
- HTTP 200 = pass, HTTP 403 = fail with violation details

### M2 — Biz-Learning (Coach)
The emotional intelligence layer. Analyzes error patterns and generates human-readable "nudges" — educational notifications to reduce recurrence.

- Identifies that supplier X frequently sends malformed files
- Generates a report with the corrective playbook
- Notifies the responsible Data Steward via Slack/Teams

### M3 — Tech-Profiling (IT Health)
The analyst. Maintains the structural "medical record" of servers and databases, predicting problems before M1 needs to intervene.

## Composable Design

ARGOS is fully opt-in within the ecosystem:

- **Without ARGOS**: ETL and DB-HALE-BOPP work normally, without advanced quality gates
- **Modules within ARGOS**: M1, M2, M3 can each be enabled/disabled via configuration (`enabled: true/false`)
- **Database agnostic**: Works with any DB that DB-HALE-BOPP supports (PostgreSQL, Oracle, SQL Server, Snowflake)

## Example Flow: Data Ingestion with Quality Alert

1. ETL starts downloading a CSV with 1M rows
2. Before writing to the warehouse, ETL asks ARGOS: "Can I write?"
3. ARGOS evaluates the policy (M3). Finds 30% nulls vs 5% threshold
4. M1 closes the gate (Quarantine). ETL receives HTTP 403 and stops gracefully
5. M2 analyzes the cause, generates a nudge notification for the Data Steward

## REST API (port 8200)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/gate/check` | Evaluate event against policy |
| POST | `/api/v1/events` | Ingest event for audit/processing |
| GET | `/api/v1/health` | Health check |

See [[../api-contracts.md|API Contracts]] for full request/response schemas.

## Strategic Direction

ARGOS will evolve from a standalone HTTP service into a **Python library** that can be embedded directly into ETL and DB-HALE-BOPP. This reduces operational complexity (fewer containers) while maintaining the same policy evaluation capabilities.

## Current State

- **Scaffolding**: FastAPI service with rule engine (4 rules + 3 policies), 14 tests passing
- **Source**: `C:\old\HALE-BOPP\ARGOS-HALE-BOPP\`
- **ADO**: Part of Epic #30
