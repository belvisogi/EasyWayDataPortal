---
type: architecture
status: draft
tags:
  - domain/devops
  - pattern/agentic
  - tool/gitlab
created: 2026-02-05
---

# 🏗️ Sovereign Gap Fillers Architecture

> **Obiettivo**: Emulare feature GitLab Premium (Approvals, Roadmap) usando Agenti e Logging Strutturato.
> **Strategia**: Action -> JSON Log -> DB Analytics.

---

## 1. 🛡️ The CI Gatekeeper (Code Owners Emulation)

Invece di usare il pulsante "Approvals" (Premium), usiamo una **Pipeline CI Job** che fa fallire la build se mancano le firme.

### Workflow
1.  **Trigger**: Merge Request aperta/aggiornata.
2.  **Agent**: `agent_guard` (CI Mode).
3.  **Check**:
    *   Legge i file cambiati (es. `infrastructure/**`).
    *   Legge i commenti della MR.
    *   Cerca pattern: `LGTM @admin` o `Approved by @admin`.
4.  **Decision**:
    *   ✅ Trovato: Exit 0 (Green).
    *   ❌ Mancante: Exit 1 (Red) + Commento "Wait! Missing approval from Infra Team".
5.  **LOGGING**: Salva l'evento.

### JSON Schema (`audit/approvals.jsonl`)
```json
{
  "timestamp": "2026-02-05T10:00:00Z",
  "event_type": "gatekeeper_check",
  "mr_id": 123,
  "project": "EasyWay/Platform",
  "changed_paths": ["infrastructure/main.tf"],
  "required_role": "maintainer",
  "found_approvals": ["mario.rossi"],
  "outcome": "BLOCKED",
  "reason": "Missing signature from team-infra"
}
```

---

## 2. 📅 The Mermaid Painter (Epics/Gantt Emulation)

Invece di usare "Epics" (Premium), generiamo grafici Gantt dinamici.

### Workflow
1.  **Trigger**: Nightly Schedule (o Webhook su Issue Update).
2.  **Agent**: `agent_governance`.
3.  **Action**:
    *   Scansiona tutte le Issue aperte.
    *   Legge Date (Due Date) e Milestone.
    *   Aggrega per "Scope" (es. Levi, Finance).
4.  **Output**:
    *   Genera Markdown con Mermaid Chart.
    *   Pusha su `Wiki/Roadmap-Levi.md`.
5.  **LOGGING**: Storicizza lo stato di avanzamento.

### JSON Schema (`audit/roadmap_snapshots.jsonl`)
```json
{
  "timestamp": "2026-02-05T00:00:00Z",
  "snapshot_id": "SNAP-20260205",
  "scope": "Project Levi",
  "total_pbies": 50,
  "completed_pbies": 35,
  "progress_percent": 70,
  "burned_hours": 120,
  "estimated_completion": "2026-03-15",
  "risk_level": "low"
}
```

---

## 3. 📊 The Data Valve (From JSON to Insight)

Tutti questi file JSONL non muoiono nel filesystem.
Il **Data Portal** (EasyWay) li ingerisce:

1.  **Source**: `agents/logs/*.jsonl`
2.  **ETL**: Caricamento su DB SQL / Data Lake.
3.  **Dashboard**: Grafana / PowerBI.
    *   "Quante volte il Guard ha bloccato un deploy?" (Security KPI)
    *   "Come evolve la velocity di Levi?" (Governance KPI)

> **Risultato**: Non hai solo le feature, hai i **DATI** su come vengono usate.

---

## 4. 🧠 The Oracle (RAG Layer)

Il salto di qualità finale: **Conversational Governance**.
Carichiamo questi JSONL (e la Wiki) nel Vector Store (v. Obsidian/RAG).

### Use Cases (Chat con i Log)
1.  **Project Manager**: *"Perché la velocity di Levi è crollata settimana scorsa?"*
    *   *RAG*: Trova i log di `agent_guard` -> "Ho notato 15 blocchi CI per 'Missing Approvals' Venerdì sera."
2.  **Auditor**: *"Chi ha approvato la modifica al firewall su Platform?"*
    *   *RAG*: Query su `audit/approvals.jsonl` -> "Approvato da `admin` il 05/02, MR !123."

### Pipeline
`JSONL` -> `Text Chunks` (Format: "Event [Timestamp]: Action") -> `Embeddings` -> **Q&A Bot**.
Trasformi i log tecnici in una narrazione comprensibile.
