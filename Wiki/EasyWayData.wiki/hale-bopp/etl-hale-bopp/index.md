---
title: ETL-HALE-BOPP — Data Orchestration Engine
id: ew-hale-bopp-etl
status: active
tags:
  - domain/hale-bopp
  - module/etl-hale-bopp
  - layer/reference
  - language/en
owner: team-data-platform
created: '2026-03-03'
updated: '2026-03-03'
summary: >
  ETL-HALE-BOPP is the data movement engine of the HALE-BOPP ecosystem.
  Config-driven pipeline orchestration, currently Airflow-based, planned
  rewrite as lightweight custom runner (~300 lines).
type: reference
llm:
  include: true
  pii: none
  chunk_hint: 300
  redaction: []
related:
  - '[[../index.md|HALE-BOPP Overview]]'
  - '[[../api-contracts.md|API Contracts]]'
  - '[[../argos-hale-bopp/index.md|ARGOS-HALE-BOPP]]'
entities: []
---
# ETL-HALE-BOPP — Data Orchestration Engine

## Questions answered
- What is ETL-HALE-BOPP?
- How are pipelines defined?
- What is the planned rewrite?
- How does it integrate with ARGOS quality gates?

## Overview

ETL-HALE-BOPP is the **data movement** engine. It orchestrates the physical transfer of data — from FTP downloads to Spark jobs to SQL procedures. It does not decide *if* data is correct; it simply moves it from A to B.

When ARGOS is present, ETL calls quality gates before writing to the data warehouse. Without ARGOS, ETL operates normally — the architecture is fully composable.

## Current Architecture (Airflow-based)

The current scaffolding uses Apache Airflow with a config-driven approach:

```
Pipeline YAML -> Config Loader -> Schema Validator -> DAG Factory -> Airflow DAGs
```

### Key Components
- **Pipeline YAML** (`config/orchestration/pipelines.yaml`): Declarative pipeline definitions
- **Config Loader** (`core/`): Reads and validates configuration
- **DAG Factory**: Generates Airflow DAGs from validated config
- **Task types**: `bash`, `python`, `http` (limited set for control)
- **n8n integration**: Webhook callbacks for external automation

### Local Setup
```bash
pwsh ./scripts/bootstrap.ps1 -Mode init
pwsh ./scripts/bootstrap.ps1 -Mode up
# UI at http://127.0.0.1:8080 (admin/admin)
```

## Planned Rewrite: Lightweight Custom Runner

**Strategic decision**: Airflow is too heavy for HALE-BOPP's needs. The ETL module will be rewritten as a custom runner of approximately 300 lines of Python.

Goals:
- Remove Dagster/Airflow dependency
- Keep YAML-driven pipeline definitions
- Maintain webhook integration for ARGOS quality gates
- Simple enough to embed in any project

This rewrite is tracked under ADO PBI #36-#37 and requires a dedicated PRD (PRD 2).

## Cloud Portability

Being built on pure open-source (Python, PostgreSQL, Docker), the ETL engine is cloud-agnostic:

1. **IaaS**: Runs on any Linux VM (AWS EC2, GCE, on-premise)
2. **CaaS**: Scalable on Kubernetes via Helm charts
3. **PaaS**: Business logic (YAML + Python blocks) portable to Google Cloud Composer or Amazon MWAA

## Source

- **Path**: `C:\old\HALE-BOPP\ETL-HALE-BOPP\`
- **ADO**: PBI #36 (runner rewrite), #37 (integration)
- **Status**: Scaffolding complete, rewrite pending PRD 2
