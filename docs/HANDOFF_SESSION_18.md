# HANDOFF Session 18 — Agent Evolution Sprint

> **Data**: 2026-02-23
> **Branch corrente**: `feature/skills-framework-agents` (da mergere → develop)
> **Main allineato a**: PR #118 (PBI #19/#20/#21 + extra fields)

---

## 📌 Stato Pre-Sessione

### Da completare (prima di iniziare)
1. **Merge PR**: `feature/skills-framework-agents` → develop
   - Skills Framework doc + Agent_Discovery v2 + Agent_Backlog_Planner + Telemetria integrata
2. Se si vuole chiudere ciclo: **Release PR** develop → main

### Già in main
| PR | Contenuto |
|---|---|
| #114 | Extra fields (effort, priority, businessValue, targetDate) + input validation |
| #115 | Adapter Conformance Tests (PBI #19, 20/20 Pester) |
| #116 | Telemetry Event Schema + Logger (PBI #21, 8/8 Pester) |
| #117 | State Machine Orchestrator (PBI #20, 17/17 Pester) |
| #118 | Release batch |

---

## 🎯 Obiettivo Sessione 18: Agent Evolution Sprint

### Batch 1 — Upgrade 5 agenti a L2 (~3h)

| Agente | Versione | Runner esistente? | Da fare |
|---|---|---|---|
| `agent_review` | v3.0 | ❌ | Manifest v2 + runner L2 (PR audit) |
| `agent_release` | v1.2 | ✅ `agent-release.ps1` | Manifest v2 + wrap runner |
| `agent_pr_manager` | v2.0 | ❌ | Manifest v2 + runner L2 (PR create) |
| `agent_developer` | v2.0 | ❌ | Manifest v2 + runner L2 (branch-per-PBI) |
| `agent_observability` | v1.0 | ✅ health check | Manifest v2 + runner L2 |

Per ogni agente:
1. Aggiornare `manifest.json` → v2 (level, skills, actions)
2. Creare/adattare runner `.ps1` con telemetria
3. Verificare PROMPTS.md
4. Commit su feature branch

### Batch 2 — Upgrade 3 agenti a L3 (se tempo)

| Agente | Target | Logica L3 |
|---|---|---|
| `agent_security` v3.0 | L3 | Orchestra Iron Dome + CVE + secret scan |
| `agent_scrummaster` | L3 | Sprint planning intelligence con state machine |
| `agent_dba` v2.0 | L2 | Health check + query analysis |

### Batch 3 — Pulizia

- Rimuovere/marcare agent placeholder (`agent_template`, stub con `{{AGENT_ROLE}}`)
- Aggiornare `agents/skills/registry.json` con nuove skill globali

---

## 📁 File chiave da conoscere

| File | Scopo |
|---|---|
| `docs/wiki/Skills-Framework.md` | Modello ibrido global/agent-specific |
| `docs/wiki/Work-Item-Field-Spec.md` | Campi obbligatori per Epic/Feature/PBI |
| `config/state-machine.json` | Pipeline SDLC (11 stati, 16 transizioni) |
| `config/telemetry-event.schema.json` | Schema eventi OpenTelemetry |
| `scripts/pwsh/core/StateMachine.psm1` | 5 funzioni state machine |
| `scripts/pwsh/core/TelemetryLogger.psm1` | 4 funzioni telemetria JSONL |
| `scripts/pwsh/core/adapters/IPlatformAdapter.psm1` | Adapter factory + Build-AdoJsonPatch |
| `agents/manifest.schema.json` | Schema manifest v2 agenti |

---

## 🧮 Metriche sessione 17

- **Pester tests totali**: 45/45 PASSED
- **PR create/merge**: 7 (PR #112-#118)
- **File nuovi**: ~15
- **Agenti formalizzati**: 2 su 34 (agent_discovery, agent_backlog_planner)
- **PBI ADO chiusi**: #19, #20, #21
