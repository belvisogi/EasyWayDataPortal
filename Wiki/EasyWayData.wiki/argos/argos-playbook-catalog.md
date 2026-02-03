---
id: argos-playbook-catalog
title: ARGOS – Playbook Catalog (v1)
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  pii: none
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
entities: []
---
[Home](./start-here.md) >  > 

title: ARGOS – Playbook Catalog (v1)
tags: [argos, dq, agents, domain/control-plane, layer/reference, audience/ops, audience/dev, privacy/internal, language/it]
updated: '2026-01-16'
status: active
redaction: [email, phone]
id: ew-argos-playbook-catalog
chunk_hint: 250-400
entities: []
include: true
summary: Catalogo playbook di remediation/prevenzione per Data Quality, con modalità (AUTO_SAFE/ASSIST), guardrail, backout e criteri di certificazione.
llm: 
  pii: none
owner: team-platform
---

# ARGOS – Playbook Catalog (v1)

## Domande a cui risponde
1. Qual è la struttura standard di un Playbook ARGOS?
2. Cosa significano le modalità AUTO_SAFE e ASSIST?
3. Come vengono governati e certificati i Playbook?

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









