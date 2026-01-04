---
id: ew-argos-playbook-catalog
title: ARGOS – Playbook Catalog (v1)
summary: Catalogo playbook di remediation/prevenzione con MODE/guardrail/backout/KPI e integrazione EasyWay.
status: active
owner: team-platform
tags: [argos, dq, agents, domain/control-plane, layer/reference, audience/ops, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []---

# ARGOS – Playbook Catalog (v1)

> Scopo: catalogo dei playbook operativi di ARGOS per remediation e prevenzione. Documento agnostico, con struttura standard, criteri AUTO_SAFE, guardrail, backout e metriche. Integrato con Quality Gates, Policy DSL, Alerting, Coach, Tech Profiling.

Integrazione EasyWay
- Repository: serializzare le schede in YAML (`argos/pb/*.yaml`) con MODE/guardrail/backout/KPI e versionarle.
- ChatOps: comandi `/argos pb list|open` integrati con i ticket del portale e con Decision Trace.
- CI: validazione schema YAML dei PB e verifica campi minimi (owner, backout, privacy, guardrail).
---

## Principi essenziali
Safety‑first (AUTO_SAFE/ASSIST), minimo intervento, backout pronto, misurabilità, privacy.

## Struttura standard Playbook
Metadati (PB_ID, TITLE, VERSION, OWNER, MODE, SCOPE, TAGS), trigger, precondizioni & guardrail, procedura (diagnosi, azione, verifica, backout, chiusura), output & telemetria.

## Indice Playbook (selezione v1)
- PB‑ENRICH‑02 — Arricchimento referenziale
- PB‑UNIQ‑04 — Dedup controllato
- PB‑FRESH‑01 — Backfill partizioni tardive
- PB‑REF‑KEY‑03 — Ripristino chiavi referenziali
- PB‑FORMAT‑ENC‑01 — Re‑parse encoding/delimiter
- PB‑DOMAIN‑WL‑02 — Whitelist temporanea valori
- PB‑PARTITION‑LATE‑01 — Quarantena & re‑ingest partizione
- PB‑SMALL‑FILES‑01 — Compaction small files

## ChatOps & Template messaggi
Comandi `/argos pb ...`; notifica apertura/chiusura con Δ Noise e MTTR.

## Governance & Versioning
OWNER chiaro; manutenzione trimestrale; AUTO_SAFE solo per PB certificati.

## DoD (v1)
Schede minime pubblicate, integrazione Alerting/Gates, KPI raccolti, flag AUTO_SAFE/guardrail/backout definiti, privacy rispettata.




