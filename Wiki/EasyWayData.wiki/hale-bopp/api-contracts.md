---
title: HALE-BOPP — API Contracts
id: ew-hale-bopp-api-contracts
status: active
tags:
  - domain/hale-bopp
  - layer/reference
  - language/en
owner: team-data-platform
created: '2026-03-03'
updated: '2026-03-03'
summary: >
  Universal Event Schema and REST API contracts for inter-module communication
  between DB-HALE-BOPP, ETL-HALE-BOPP, and ARGOS-HALE-BOPP.
type: reference
llm:
  include: true
  pii: none
  chunk_hint: 300
  redaction: []
related:
  - '[[./index.md|HALE-BOPP Overview]]'
  - '[[./db-hale-bopp/index.md|DB-HALE-BOPP]]'
  - '[[./etl-hale-bopp/index.md|ETL-HALE-BOPP]]'
  - '[[./argos-hale-bopp/index.md|ARGOS-HALE-BOPP]]'
entities: []
---
# HALE-BOPP — API Contracts v1.0.0

## Questions answered
- How do the three HALE-BOPP engines communicate?
- What is the Universal Event Schema?
- What REST endpoints does each module expose?
- What are the standard integration flows?

## Universal Event Schema

Every inter-module message follows this JSON envelope:

```json
{
  "event_id": "uuid-v4",
  "timestamp": "2026-03-03T12:00:00Z",
  "source": "etl | db | argos",
  "event_type": "string (see Event Types)",
  "payload": { }
}
```

## Event Types

| Source | Event Type | Emitted When | Consumer |
|--------|-----------|--------------|----------|
| ETL | `etl.pipeline.started` | Pipeline run begins | ARGOS (audit) |
| ETL | `etl.pipeline.completed` | Pipeline run succeeds | ARGOS (audit) |
| ETL | `etl.pipeline.failed` | Pipeline run fails | ARGOS (gating) |
| ETL | `etl.quality_gate.request` | ETL asks "can I proceed?" | ARGOS (decision) |
| DB | `db.schema.diff.completed` | Schema diff computed | ARGOS (review) |
| DB | `db.schema.deploy.completed` | Schema change applied | ARGOS (audit), ETL (trigger) |
| DB | `db.drift.detected` | Actual schema != desired | ARGOS (alert) |
| ARGOS | `argos.gate.pass` | Quality gate passed | ETL (continue) |
| ARGOS | `argos.gate.fail` | Quality gate failed | ETL (abort), EasyWay agents |
| ARGOS | `argos.alert.drift` | Drift requires attention | EasyWay agents |

## Module Endpoints

### DB-HALE-BOPP (port 8100)

```
POST /api/v1/schema/diff
  Body: { "connection_string": "...", "desired_schema": { ... } }
  Returns: { "changes": [...], "risk_level": "low|medium|high" }

POST /api/v1/schema/deploy
  Body: { "connection_string": "...", "changes": [...], "dry_run": true|false }
  Returns: { "applied": [...], "rollback_sql": "..." }

POST /api/v1/drift/check
  Body: { "connection_string": "...", "baseline_id": "..." }
  Returns: { "drifted": true|false, "diffs": [...] }

GET /api/v1/health
  Returns: { "status": "ok", "version": "..." }
```

### ARGOS-HALE-BOPP (port 8200)

```
POST /api/v1/gate/check
  Body: { "event": <Universal Event>, "policy": "default|strict|permissive" }
  Returns: 200 { "decision": "pass", "reason": "..." }
       or 403 { "decision": "fail", "violations": [...] }

POST /api/v1/events
  Body: <Universal Event>
  Returns: 202 Accepted (async processing, audit log)

GET /api/v1/health
  Returns: { "status": "ok", "version": "..." }
```

### ETL-HALE-BOPP (port 3000)

```
POST /api/v1/webhook
  Body: <Universal Event>
  Returns: 202 Accepted (triggers sensor evaluation)

GET /api/v1/health
  Returns: { "status": "ok", "version": "..." }
```

Note: ETL also exposes Dagster's native UI and GraphQL API (to be replaced by custom runner).

## Integration Flows

### Flow A: ETL Pipeline with Quality Gate
```
ETL starts pipeline
  -> ETL emits etl.pipeline.started -> ARGOS /events (audit)
  -> ETL reaches quality gate step
  -> ETL calls ARGOS POST /gate/check { event: etl.quality_gate.request }
  -> ARGOS evaluates policies
  -> 200 pass -> ETL continues
  -> 403 fail -> ETL aborts, emits etl.pipeline.failed
```

### Flow B: Schema Drift Detection
```
Cron / Agent triggers DB POST /drift/check
  -> DB compares actual vs baseline
  -> If drifted: DB emits db.drift.detected -> ARGOS /events
  -> ARGOS evaluates severity
  -> ARGOS emits argos.alert.drift -> EasyWay agents (webhook)
```

### Flow C: Schema Migration
```
Agent / Human calls DB POST /schema/diff
  -> DB returns changes + risk_level
  -> Caller reviews, then calls DB POST /schema/deploy { dry_run: false }
  -> DB applies changes, emits db.schema.deploy.completed -> ARGOS /events
  -> ARGOS logs audit trail
  -> ARGOS notifies ETL webhook -> ETL sensor triggers dependent pipelines
```
