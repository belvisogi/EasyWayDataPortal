# Specifica Campi Work Item — EasyWay Platform Adapter SDK

> **Scopo**: Questo documento definisce i campi attesi per ogni tipo di work item
> nel backlog input JSON usato da `platform-plan.ps1`. Referenziato dal JSON Schema
> `config/backlog-input.schema.json`.

---

## Legenda

| Simbolo | Significato |
|---|---|
| 🔴 | **Obbligatorio** — il planner rifiuta l'input se manca |
| 🟡 | **Raccomandato** — accettato senza ma genera warning |
| ⚪ | **Opzionale** — usato se presente, ignorato se assente |

---

## Epic (Livello 1)

> **Cosa rappresenta**: un'iniziativa strategica o macro-area di lavoro. Durata tipica: 1-3 mesi.

| Campo | Obbligo | Tipo | Mapping ADO | Note |
|---|---|---|---|---|
| `title` | 🔴 | string | `System.Title` | Prefisso `[Epic]` aggiunto automaticamente |
| `description` | 🔴 | string (min 50 char) | `System.Description` | Obiettivo strategico, scope, valore atteso |
| `businessValue` | 🟡 | string | `Microsoft.VSTS.Common.BusinessValue` | Valore di business misurabile |
| `features` | 🔴 | array di Feature | — | Almeno 1 Feature |

### Esempio
```json
{
  "title": "[Phase 9] Core Agentic Framework (Runtime & SDK)",
  "description": "Transition the agentic architecture from loosely-coupled scripts into a formalized SDK with config-driven adapters, state machine orchestration, and structured observability.",
  "businessValue": "Riduzione lead time backlog 60%, eliminazione vendor lock-in",
  "features": [...]
}
```

---

## Feature (Livello 2)

> **Cosa rappresenta**: una funzionalita' concreta e deliverable. Durata tipica: 1-2 sprint.

| Campo | Obbligo | Tipo | Mapping ADO | Note |
|---|---|---|---|---|
| `title` | 🔴 | string | `System.Title` | Prefisso `[Feature]` aggiunto automaticamente |
| `description` | 🔴 | string (min 30 char) | `System.Description` | Cosa fa, perche' serve, come si integra |
| `targetDate` | ⚪ | string (ISO date) | `Microsoft.VSTS.Scheduling.TargetDate` | Data target completamento |
| `pbis` | 🟡 | array di PBI | — | Decomposizione in unita' di lavoro |

### Esempio
```json
{
  "title": "Platform Adapter SDK (IPlatformAdapter)",
  "description": "Config-driven adapter pattern for multi-platform support. Enables switching between ADO, GitHub, Jira, Forgejo, BusinessMap, Witboost by changing only platform-config.json.",
  "targetDate": "2026-03-15",
  "pbis": [...]
}
```

---

## Product Backlog Item — PBI (Livello 3)

> **Cosa rappresenta**: unita' di lavoro assegnabile a uno sprint. Deve essere completabile in 1-3 giorni.

| Campo | Obbligo | Tipo | Mapping ADO | Note |
|---|---|---|---|---|
| `title` | 🔴 | string | `System.Title` | Prefisso `[PBI]` aggiunto automaticamente |
| `description` | 🔴 | string (min 50 char) | `System.Description` | Cosa implementare, contesto tecnico, dipendenze |
| `acceptanceCriteria` | 🔴 | string (min 20 char) | `Microsoft.VSTS.Common.AcceptanceCriteria` | Condizioni verificabili e testabili |
| `effort` | ⚪ | integer (1-13) | `Microsoft.VSTS.Scheduling.Effort` | Story points Fibonacci. Se omesso, da stimare in sprint planning |
| `priority` | ⚪ | integer (1-4) | `Microsoft.VSTS.Common.Priority` | 1=Critical, 2=High, 3=Medium (default), 4=Low |

### Esempio
```json
{
  "title": "Adapter Conformance Test Suite",
  "description": "Implement contract-first test suite that runs the same assertions against all platform adapters (ADO, GitHub stub, BusinessMap stub). Ensures new adapters pass the canonical interface contract.",
  "acceptanceCriteria": "All 4 interface methods tested. ADO adapter passes all tests. Stub adapters throw NotImplemented. Test runner works via Invoke-Pester.",
  "effort": 5,
  "priority": 2
}
```

---

## Campi auto-generati dal planner

Questi campi vengono aggiunti automaticamente da `platform-plan.ps1` e **NON devono essere nel backlog input**:

| Campo | Mapping ADO | Generato da |
|---|---|---|
| `areaPath` | `System.AreaPath` | `platform-config.json → paths.areaPath` |
| `iterationPath` | `System.IterationPath` | `platform-config.json → paths.iterationPath` |
| `tags` | `System.Tags` | `AutoPRD` + `PRD:<prdId>` (per dedup) |
| `parentId` | `System.LinkTypes.Hierarchy-Reverse` | Risolto dal planner (gerarchia backlog) |

---

## Regole di validazione

1. **Ogni Epic deve avere almeno 1 Feature** — un Epic senza Feature non ha senso operativo.
2. **Ogni campo `description` deve avere contenuto reale** — non placeholder come "TBD" o "TODO".
3. **L'`acceptanceCriteria` del PBI deve essere verificabile** — evitare frasi vaghe come "funziona bene".
4. **Il `prdId` deve essere unico e stabile** — usato come chiave di dedup. Non cambiarlo dopo la prima creazione.
5. **I titoli devono essere concisi** (max ~80 char) — i prefissi `[Epic]`/`[Feature]`/`[PBI]` vengono aggiunti automaticamente.
