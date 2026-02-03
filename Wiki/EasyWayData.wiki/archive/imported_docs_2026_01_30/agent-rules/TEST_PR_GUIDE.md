---
id: ew-archive-imported-docs-2026-01-30-agent-rules-test-pr-guide
title: 🧪🔀 Test Management & Pull Requests - Guide
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# 🧪🔀 Test Management & Pull Requests - Guide

**Created**: 2026-01-13  
**New Capabilities**: Test Plans/Runs + PR Tracking ✨  
**Coverage**: ADO 40% → 60% (+20pp)

---

## 🎯 Nuove Funzionalità

### A. Test Management (4 queries)
### B. Pull Requests (5 queries)

**Total**: 9 nuove ricette + 2 scripts PowerShell

---

## 🧪 A. TEST MANAGEMENT

### 1. Lista Test Plans

**Command**:
```powershell
pwsh Rules/scripts/get-ado-testplans.ps1 -ListPlans
```

**Output**:
```
Id    Name                  State   StartDate   EndDate
123   Sprint 2 Test Plan    Active  2025-01-15  2025-01-28
124   Regression Tests      Active  2025-01-01  2025-12-31
```

**Use Case**: Vedere tutti i test plan del progetto

---

### 2. Test Runs Ultimi Giorni

**Command**:
```powershell
pwsh Rules/scripts/get-ado-testplans.ps1 -ListRuns -DaysBack 7
```

**Output**:
```
Id    Name               State      TotalTests  PassedTests  FailedTests
567   Sprint 2 Run 1     Completed  45          42           3
568   Smoke Tests        InProgress 10          8            0

📊 Summary:
  Total Runs: 2
  Pass Rate: 93.3%
```

**Use Case**: Monitorare test execution e quality

---

### 3. Test Cases per Plan

**Command**:
```powershell
pwsh Rules/scripts/get-ado-testplans.ps1 -PlanId 123 -ListTestCases
```

**Output**:
```
Suite: Functional Tests
  - [1001] Login test
  - [1002] Dashboard load test
  ... and 15 more
```

**Use Case**: Vedere dettaglio test cases di un plan

---

### 4. Coverage Test Sprint

**Approach**: Combina iterations + test runs

**Steps**:
```powershell
# 1. Get sprint attivo
$sprint = pwsh get-ado-iterations.ps1 -OnlyActive

# 2. Get test runs del periodo
pwsh get-ado-testplans.ps1 -ListRuns -DaysBack 14

# 3. Calcola coverage
# Compare work items vs test cases
```

**Use Case**: Quality metrics per sprint

---

## 🔀 B. PULL REQUESTS

### 1. PR Aperti

**Command**:
```powershell
pwsh Rules/scripts/get-ado-pullrequests.ps1 -Status active
```

**Output**:
```
Repository  Id    Title                         Status  CreatedBy
MyRepo      234   Feature: Add login            Active  Mario Rossi
MyRepo      235   Fix: Dashboard bug            Active  Luigi Verdi
  
📈 Summary:
  Active: 2
```

**Use Case**: Dashboard PR aperti

---

### 2. PR da Revieware

**Command**:
```powershell
pwsh Rules/scripts/get-ado-pullrequests.ps1 -Status active -IncludeReviewers
```

**Output**:
```
Id    Title              Reviewers          Status
234   Feature: Login     Pending (Anna)     Active
235   Fix: Bug           Approved (2/2)     Active
```

**Use Case**: Tracking code reviews

---

### 3. PR Velocity

**Command**:
```powershell
pwsh Rules/scripts/get-ado-pullrequests.ps1 -Status completed -CalculateVelocity
```

**Output**:
```
⚡ PR Velocity Analysis:
  Average PR Duration: 14.5 hours
  
  Top 5 Fastest PRs:
  Id    Title              DurationHours
  230   Hotfix: CSS        2.3
  231   Docs update        3.1
  ...
```

**Use Case**: Dev productivity metrics

---

### 4. PR per Autore

**Command**:
```powershell
pwsh Rules/scripts/get-ado-pullrequests.ps1 -CreatedBy "mario.rossi@example.com"
```

**Use Case**: Contributi individuali

---

### 5. PR Completati

**Command**:
```powershell
pwsh Rules/scripts/get-ado-pullrequests.ps1 -Status completed
```

**Use Case**: Storico merge

---

## 📊 Ricette Disponibili (9)

| Trigger | Intent | Script | Flags |
|---------|--------|--------|-------|
| `lista test plans` | ado:test.plans | get-ado-testplans.ps1 | ✅ auto, safe |
| `test runs ultimi giorni` | ado:test.runs | get-ado-testplans.ps1 | ✅ auto, safe |
| `test cases plan` | ado:test.cases | get-ado-testplans.ps1 | ✅ auto, safe |
| `coverage test sprint` | ado:test.coverage | Combined | ✅ auto, safe |
| `pull request aperti` | ado:pr.active | get-ado-pullrequests.ps1 | ✅ auto, safe |
| `pr da revieware` | ado:pr.pending | get-ado-pullrequests.ps1 | ✅ auto, safe |
| `pr velocity` | ado:pr.velocity | get-ado-pullrequests.ps1 | ✅ auto, safe |
| `pr di un autore` | ado:pr.author | get-ado-pullrequests.ps1 | ✅ auto, safe |
| `pr completati` | ado:pr.completed | get-ado-pullrequests.ps1 | ✅ auto, safe |

---

## 🔧 Script Parameters

### get-ado-testplans.ps1

```powershell
-Organization <string>   # Auto from config
-Project <string>        # Auto from config
-PAT <string>            # Auto from secrets
-PlanId <string>         # Test plan ID
-ListPlans               # List all plans
-ListSuites              # List suites
-ListTestCases           # List test cases
-ListRuns                # List test runs
-IterationPath <string>  # Filter by iteration
-DaysBack <int>          # Days back for runs (default: 7)
```

### get-ado-pullrequests.ps1

```powershell
-Organization <string>   # Auto from config
-Project <string>        # Auto from config
-Repository <string>     # Specific repo (default: all)
-PAT <string>            # Auto from secrets
-Status <string>         # active, completed, abandoned, all
-CreatedBy <string>      # Filter by author email
-Reviewer <string>       # Filter by reviewer
-Top <int>               # Max results (default: 100)
-IncludeReviewers        # Include reviewer status
-CalculateVelocity       # Compute PR duration stats
```

---

## 💡 Use Cases Reali

### Scenario 1: Daily Standup (QA)
```
QA: "test runs ultimi giorni"
AI: Mostra runs + pass rate 93%

QA: "coverage test sprint"
AI: Combina sprint items + test coverage
```

### Scenario 2: Code Review Triage
```
Dev: "pr da revieware"
AI: Lista PR pending review

Dev: "pr aperti"
AI: Overview PR attivi team
```

### Scenario 3: Sprint Retrospective
```
PM: "pr velocity"
AI: Average 14.5 hours, mostra fastest PRs

PM: "test runs ultimi giorni"
AI: Pass rate trend
```

---

## 🎯 Integration con Existing Tools

### Con Sprint Queries
```powershell
# Test coverage sprint attivo
get-ado-iterations.ps1 -OnlyActive
get-ado-testplans.ps1 -ListRuns

# Compare items vs tests
```

### Con Deploy Queries
```powershell
# Deploy con PR tracking
get-ado-pullrequests.ps1 -Status completed
# Match PR to deploy work items
```

---

## 📈 Metrics & Analytics

### Test Management KPIs
- **Pass Rate**: % test passed vs total
- **Test Coverage**: % work items with tests
- **Execution Frequency**: Runs per sprint
- **Failed Tests Trend**: Track over time

### PR Metrics
- **PR Velocity**: Avg hours creation → merge
- **Review Throughput**: PRs reviewed/day
- **Active PR Count**: Open PRs by repo
- **Top Contributors**: PRs by author

---

## 🔐 Authentication

Usa stessa config di altri script ADO:

```json
// connections.json
{
  "ado": {
    "organization": "YourOrg",
    "project": "YourProject",
    "repository": "YourRepo"
  }
}

// secrets.json
{
  "ado_pat": "your-pat"
}
```

**PAT Scope Required**:
- **Test Management**: `vso.test` (read)
- **Pull Requests**: `vso.code` (read)

---

## 📊 Output Formats

### JSON Export
Entrambi script esportano in `out/devops/`:
- `testplans_YYYYMMDDHHMMSS.json`
- `pullrequests_YYYYMMDDHHMMSS.json`

**Automation ready**: Parse JSON per dashboards, reports, CI/CD

---

## ✅ Benefits

**Test Management**:
- ✅ Quality visibility
- ✅ Test automation tracking
- ✅ Sprint coverage metrics
- ✅ Failed tests monitoring

**Pull Requests**:
- ✅ Code review tracking
- ✅ Dev productivity metrics
- ✅ PR velocity analytics
- ✅ Bottleneck identification

**Overall**:
- ✅ ADO Coverage: 40% → 60%
- ✅ 9 new recipes (48 total)
- ✅ QA + Dev workflows optimized

---

## 🔮 Future Enhancements

**Possibili**:
- Test plan templates
- PR auto-assignment rules
- Burndown test execution
- Code coverage integration
- PR conflict detection
- Automated test run triggers

---

**Status**: ✅ Production Ready  
**API**: ADO REST API v7.0  
**Coverage**: Test Plans, Test Runs, Pull Requests  
**Dependencies**: PowerShell 7+, ADO PAT with test+code scopes


