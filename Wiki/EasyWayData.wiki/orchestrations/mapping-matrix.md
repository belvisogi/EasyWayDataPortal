---
id: ew-mapping-matrix
title: Mapping Matrix - Workflow → Intent → Implementazione
summary: Tabella unica per collegare orchestrazioni, intent, agenti, entrypoint (ewctl/n8n), artefatti e doc.
status: draft
owner: team-platform
tags: [orchestration, governance, mapping, domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---

# Mapping Matrix - Workflow → Intent → Implementazione

Nota
- Censimento agent (ownership + domini + entrypoint): control-plane/agents-registry.md.

## Control Plane

| Item | Tipo | Owner | Entrypoint | Artefatti | KB | Wiki |
|---|---|---|---|---|---|---|
| orchestrator.n8n.dispatch | intent | Control-plane | n8n + `scripts/ewctl.ps1` | `agents/logs/events.jsonl` | `orchestrator.n8n.deploy` | `orchestrations/orchestrator-n8n.md` |

## Orchestrazioni (use case)

| Item | Tipo | Owner | Entrypoint | Artefatti | KB | Wiki |
|---|---|---|---|---|---|---|
| wf.excel-csv-upload | orchestration | Orchestrator | manifest + intents | diary + decision trace | (da agganciare) | `orchestrations/wf-excel-csv-upload.md` |

## Intents (già implementati via agent + ewctl)

| Item | Tipo | Owner | Entrypoint | Artefatti | KB | Wiki |
|---|---|---|---|---|---|---|
| db-user:create | intent | Agent_DBA | `pwsh scripts/ewctl.ps1 --engine ps --intent db-user-create` | output JSON (action-result) + `agents/logs/events.jsonl` | `db-user-create` | `db-user-access-management.md` |
| db-user:rotate | intent | Agent_DBA | `pwsh scripts/ewctl.ps1 --engine ps --intent db-user-rotate` | output JSON (action-result) + `agents/logs/events.jsonl` | `db-user-rotate` | `db-user-access-management.md` |
| db-user:revoke | intent | Agent_DBA | `pwsh scripts/ewctl.ps1 --engine ps --intent db-user-revoke` | output JSON (action-result) + `agents/logs/events.jsonl` | `db-user-revoke` | `db-user-access-management.md` |
| dlk-ensure-structure | intent | Agent_Datalake | `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-ensure-structure` | output JSON (action-result) + `agents/logs/events.jsonl` | `dlk-ensure-structure` | `datalake-ensure-structure.md` |
| dlk-apply-acl | intent | Agent_Datalake | `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-apply-acl` | output JSON (action-result) + `agents/logs/events.jsonl` | `dlk-apply-acl` | `datalake-apply-acl.md` |
| dlk-set-retention | intent | Agent_Datalake | `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-set-retention` | output JSON (action-result) + `agents/logs/events.jsonl` | `dlk-set-retention` | `datalake-set-retention.md` |
| dlk-export-log | intent | Agent_Datalake | `pwsh scripts/ewctl.ps1 --engine ps --intent dlk-export-log` | output JSON (action-result) + `agents/logs/events.jsonl` | (da agganciare) | `easyway-webapp/05_codice_easyway_portale/easyway_portal_api/gestione-log-and-policy-dati-sensibili.md` |
| etl-slo:validate | intent | Agent_Datalake | `pwsh scripts/ewctl.ps1 --engine ps --intent etl-slo-validate` | output JSON (action-result) + `agents/logs/events.jsonl` | `etl-governance-sla` | `etl-governance-sla.md` |
| sample:echo | intent | Agent_Template | `pwsh scripts/ewctl.ps1 --engine ps --intent sample` | output JSON (action-result) + `agents/logs/events.jsonl` | (opz.) | `agents/agent_template/README.md` |

## Gates / Lint (già implementati)

| Item | Tipo | Owner | Entrypoint | Artefatti | KB | Wiki |
|---|---|---|---|---|---|---|
| checklist | gate | Agent_Governance | `pwsh scripts/ewctl.ps1 --engine ps --checklist --noninteractive` | `checklist.json` (artifact) + `agents/logs/events.jsonl` | `predeploy-checklist` | `docs/ci/ewctl-gates.md` |
| dbdrift | gate | Agent_Governance | `pwsh scripts/ewctl.ps1 --engine ps --dbdrift --noninteractive` | `drift.json` (artifact) + `agents/logs/events.jsonl` | (da agganciare) | `docs/ci/ewctl-gates.md` |
| kbconsistency | gate | Agent_Governance | `pwsh scripts/ewctl.ps1 --engine ps --kbconsistency --noninteractive` | report (artifact) + `agents/logs/events.jsonl` | (da agganciare) | `docs/ci/ewctl-gates.md` |
| governance-gates (bundle) | gate | Agent_Governance | `pwsh scripts/ewctl.ps1 --engine ps --checklist --dbdrift --kbconsistency --noninteractive --logevent` | `gates-report.json` (artifact) + `agents/logs/events.jsonl` | (da agganciare) | `docs/ci/ewctl-gates.md` |
| doc-alignment | gate | Agent_Governance | `pwsh scripts/ewctl.ps1 --engine ps --intent doc-alignment` | report JSON | (da agganciare) | `doc-alignment-gate.md` |
| whatfirst-lint | gate | Agent_Governance | `pwsh scripts/whatfirst-lint.ps1 -FailOnError` | `whatfirst-lint.json` (artifact) | `whatfirst-lint` | `howto-what-first-team.md` |
| wiki-frontmatter-lint | gate | Agent_Governance | `pwsh scripts/wiki-frontmatter-lint.ps1 -FailOnError` | `wiki-frontmatter-lint.json` (artifact) | `whatfirst-lint` | `howto-what-first-team.md` |

## Note operative
- La colonna Entrypoint e' canonica: tutti i nuovi intent passano da `orchestrator.n8n.dispatch`.
- Molti intent hanno anche `IntentPath` sample in `agents/<agent>/templates/*.sample.json`.
- Per aggiungere un nuovo intent: aggiungi schema WHAT in `docs/agentic/templates/intents/`, aggiorna questa matrice, aggiungi ricetta KB e pagina Wiki.

