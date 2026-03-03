---
title: DB-HALE-BOPP — Schema Governance Engine
id: ew-hale-bopp-db
status: active
tags:
  - domain/hale-bopp
  - module/db-hale-bopp
  - layer/reference
  - language/en
owner: team-data-platform
created: '2026-03-03'
updated: '2026-03-03'
summary: >
  DB-HALE-BOPP is a deterministic schema governance engine for PostgreSQL.
  CLI tool and REST API for schema diff, deploy, drift detection, and snapshots.
  Positioned as a "Flyway killer" with drift detection capabilities.
type: reference
llm:
  include: true
  pii: none
  chunk_hint: 350
  redaction: []
related:
  - '[[../index.md|HALE-BOPP Overview]]'
  - '[[../api-contracts.md|API Contracts]]'
  - '[[../argos-hale-bopp/index.md|ARGOS-HALE-BOPP]]'
entities: []
---
# DB-HALE-BOPP — Schema Governance Engine

## Questions answered
- What does DB-HALE-BOPP do?
- How do I use the CLI tool?
- What REST API endpoints are available?
- How does drift detection work?
- What makes this different from Flyway or Liquibase?

## Overview

DB-HALE-BOPP is the **flagship** module of the HALE-BOPP ecosystem. It is a deterministic schema governance engine that:

- **Compares** actual database schema against a desired state (diff)
- **Deploys** schema changes transactionally with automatic rollback SQL
- **Detects drift** — unauthorized manual changes to production schemas
- **Snapshots** current schema as a JSON baseline for future comparison

### Why not Flyway/Liquibase?

| Feature | Flyway/Liquibase | DB-HALE-BOPP |
|---------|-----------------|--------------|
| Migration approach | Sequential versioned scripts | Desired-state diffing |
| Drift detection | No | Built-in |
| Risk assessment | No | Per-change risk level |
| Rollback generation | Manual | Automatic |
| AI agent integration | No | Event-driven (Universal Event Schema) |
| Audit trail | Basic | Cryptographic hash |

## CLI Reference

Install: `pip install hale-bopp-db` (packaging in progress)

### `halebopp diff`
Compare actual schema with a desired schema definition.

```bash
halebopp diff --connection "postgresql://user:pass@host/db" --desired schema.json
halebopp diff -c "postgresql://..." -d schema.json --json-output
```

Returns non-zero exit code if changes are detected.

### `halebopp deploy`
Apply schema changes transactionally. Default is dry-run mode.

```bash
# Dry run (default) — shows what would change
halebopp deploy -c "postgresql://..." --changes changes.json

# Actually apply changes
halebopp deploy -c "postgresql://..." --changes changes.json --execute
```

### `halebopp drift`
Detect unauthorized schema changes against a saved baseline.

```bash
halebopp drift -c "postgresql://..." --baseline baseline.json
halebopp drift -c "postgresql://..." -b baseline.json --json-output
```

Returns non-zero exit code if drift is detected.

### `halebopp snapshot`
Save the current database schema as a JSON file for future comparisons.

```bash
halebopp snapshot -c "postgresql://..." -o baseline.json
```

## REST API (FastAPI)

When running as a service (port 8100):

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/schema/diff` | Compute structural diff |
| POST | `/api/v1/schema/deploy` | Apply changes (with `dry_run` flag) |
| POST | `/api/v1/drift/check` | Detect drift against baseline |
| POST | `/api/v1/schema/validate` | Validate schema against rule engine |
| POST | `/api/v1/impact/analyze` | Dependency tree for a given diff |
| GET | `/api/v1/health` | Health check |

See [[../api-contracts.md|API Contracts]] for full request/response schemas.

## Technology Stack

- **Python 3.10+**
- **FastAPI** — REST API
- **SQLAlchemy 2.0** — database introspection and abstraction
- **Click** — CLI framework
- **Pydantic** — data validation and serialization
- **psycopg2** — PostgreSQL driver

## Project Status

- **Sprint 1 (Done)**: CLI tool, baseline management, deploy with audit log — 17 tests passing
- **Sprint 2 (Next)**: PostgreSQL integration tests (docker-compose), pip packaging
- **Sprint 3 (Planned)**: FastAPI service mode, multi-database support
- **Source**: `C:\old\HALE-BOPP\DB-HALE-BOPP\`
- **ADO**: PBI #31 (CLI), #32 (baseline), #33 (deploy) Done; #34 (integration tests), #35 (packaging) pending
