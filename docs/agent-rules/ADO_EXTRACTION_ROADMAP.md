# 📊 ADO Extraction Roadmap - Possibili Estrazioni

**Date**: 2026-01-13  
**Purpose**: Identificare ulteriori tipologie di estrazione ADO utili  
**Status**: Analysis & Recommendations

---

## ✅ Già Implementato

### Work Items
- ✅ PBI, User Stories, Tasks, Bugs
- ✅ Export con WIQL custom
- ✅ Filtri per tag, stato, progetto
- ✅ Deploy items (pattern matching)
- ✅ Export 2-step approach

### Sprint/Iterations
- ✅ Lista iterations (ADO API)
- ✅ Sprint attivo
- ✅ Backlog sprint
- ✅ Storico sprint

### Pipeline Basic
- ✅ Pipeline list
- ✅ Pipeline history
- ✅ Build/release linked to work items

**Coverage Attuale**: ~40% delle capacità ADO

---

## 🎯 Nuove Estrazioni Possibili

### 1. 🧪 Test Management (Priority: HIGH)

**API**: `/test/plans`, `/test/suites`, `/test/runs`

**Queries Utili**:
- **Test Plans per progetto**
  ```
  GET https://dev.azure.com/{org}/{project}/_apis/test/plans
  ```

- **Test Cases per Suite**
  ```
  GET .../test/plans/{planId}/suites/{suiteId}/testcases
  ```

- **Test Runs con risultati**
  ```
  GET .../test/runs?buildIds={buildId}
  ```

- **Test Coverage per Sprint**
  ```
  Query test cases + filter by IterationPath
  Calculate passed/failed/blocked ratio
  ```

**Use Cases**:
- "test cases sprint attivo"
- "test runs falliti ultima settimana"
- "coverage test per progetto AIR"
- "test plan IFRS9"

**Benefit**: Quality tracking, test automation analytics

---

### 2. 🔀 Pull Requests (Priority: HIGH)

**API**: `/git/repositories/{repo}/pullrequests`

**Queries Utili**:
- **PR Aperti**
  ```
  GET .../pullrequests?searchCriteria.status=active
  ```

- **PR per Autore**
  ```
  Filter by createdBy
  ```

- **Code Reviews Pending**
  ```
  GET .../pullrequests/{prId}/reviewers
  Filter status=waiting
  ```

- **PR Velocity**
  ```
  Calculate: time from creation to completion
  Group by author, team, sprint
  ```

**Use Cases**:
- "pull request aperti"
- "pr da revieware"
- "pr completati questa settimana"
- "pr velocity per team"

**Benefit**: Code review tracking, developer productivity

---

### 3. 🏗️ Builds & Releases Dettaglio (Priority: MEDIUM)

**API**: `/build/builds`, `/release/releases`

**Queries Utili**:
- **Builds per Branch**
  ```
  GET .../builds?branchName=refs/heads/main
  ```

- **Build Failures**
  ```
  Filter result=failed
  Group by definition, date
  ```

- **Release Stages**
  ```
  GET .../releases/{releaseId}/environments
  Check deployment status per stage (Dev, UAT, Prod)
  ```

- **Deployment Approvals Pending**
  ```
  GET .../approvals?statusFilter=pending
  ```

**Use Cases**:
- "build falliti ultima settimana"
- "release in prod oggi"
- "approval pending per UAT"
- "build success rate per branch"

**Benefit**: CI/CD monitoring, deployment tracking

---

### 4. 🔗 Work Item Relations (Priority: MEDIUM)

**API**: Work Items with `$expand=relations`

**Queries Utili**:
- **Parent-Child Hierarchy**
  ```
  Get Epic → Features → PBIs → Tasks
  Visualize hierarchy tree
  ```

- **Related Items**
  ```
  Get all links (Related, Successor, Predecessor)
  ```

- **Dependency Graph**
  ```
  Find blocking items
  Calculate critical path
  ```

- **Orphaned Items**
  ```
  Find PBIs without parent Feature
  Find Tasks without parent PBI
  ```

**Use Cases**:
- "figli della epic 12345"
- "dipendenze pbi 67890"
- "items bloccati"
- "epic senza feature"

**Benefit**: Portfolio management, dependency tracking

---

### 5. 📜 Work Item History (Priority: MEDIUM)

**API**: `/workitems/{id}/updates`

**Queries Utili**:
- **Change History**
  ```
  GET .../workitems/{id}/updates
  Show all state changes, assignment changes, field updates
  ```

- **Who Changed What**
  ```
  Filter updates by field
  Group by user
  ```

- **Audit Trail**
  ```
  Track changes for compliance
  Who moved item to Done? When?
  ```

**Use Cases**:
- "storico modifiche pbi 12345"
- "chi ha cambiato stato"
- "modifiche ultima settimana"

**Benefit**: Audit, compliance, debugging changes

---

### 6. 👥 Team Members & Assignments (Priority: LOW)

**API**: `/teams`, `/workitems` with AssignedTo

**Queries Utili**:
- **Team Members**
  ```
  GET .../_apis/projects/{project}/teams/{team}/members
  ```

- **Workload per Persona**
  ```
  Query work items assigned to specific user
  Calculate effort/story points sum
  ```

- **Unassigned Items**
  ```
  Filter AssignedTo = null
  ```

**Use Cases**:
- "pbi assegnati a Mario"
- "carico di lavoro team"
- "items non assegnati"

**Benefit**: Resource management, capacity planning

---

### 7. 📊 Areas & Classification (Priority: LOW)

**API**: `/wit/classificationnodes`

**Queries Utili**:
- **Area Paths**
  ```
  GET .../classificationnodes/areas
  ```

- **Items per Area**
  ```
  Query work items by System.AreaPath
  ```

**Use Cases**:
- "pbi area frontend"
- "distribuzione per component"

**Benefit**: Component-based reporting

---

### 8. 🏷️ Tags Analytics (Priority: LOW)

**Queries Utili**:
- **Tag Distribution**
  ```
  Extract all tags from work items
  Count frequency
  ```

- **Tag Trends**
  ```
  Tags over time
  New tags appeared
  ```

**Use Cases**:
- "tag più usati"
- "items senza tag"

**Benefit**: Taxonomy management

---

### 9. 📝 Saved Queries (Priority: VERY LOW)

**API**: `/wit/queries`

**Queries Utili**:
- **List Saved Queries**
  ```
  GET .../wit/queries?$depth=1
  ```

- **Execute Saved Query**
  ```
  GET .../wit/queries/{queryId}
  Then execute WIQL
  ```

**Use Cases**:
- "esegui query salvata X"

**Benefit**: Reuse existing ADO queries

---

### 10. 📈 Custom Fields (Priority: VERY LOW)

**API**: Work Item Types with fields

**Queries Utili**:
- **Custom Field Values**
  ```
  Extract custom fields from work items
  Aggregate, group, analyze
  ```

**Use Cases**:
- Depends on your custom fields

**Benefit**: Organization-specific tracking

---

## 🎯 Roadmap Priorità

### Fase 1 (Immediate - High Value)
1. ✅ **Test Management** - Quality tracking critical
2. ✅ **Pull Requests** - Dev productivity important

### Fase 2 (Short-term - Medium Value)
3. **Builds/Releases Dettaglio** - CI/CD monitoring
4. **Work Item Relations** - Dependency management

### Fase 3 (Long-term - Nice to Have)
5. Work Item History
6. Team Members & Assignments
7. Areas & Tags Analytics

### Fase 4 (Optional)
8. Saved Queries
9. Custom Fields
10. Advanced Analytics

---

## 💡 Implementazione Suggerita

### Test Management (Esempio)
```powershell
# Script: get-ado-testplans.ps1
GET https://dev.azure.com/{org}/{project}/_apis/test/plans

# Ricette:
- "lista test plans"
- "test cases sprint attivo"
- "test runs falliti"
```

### Pull Requests (Esempio)
```powershell
# Script: get-ado-pullrequests.ps1
GET .../pullrequests?searchCriteria.status=active

# Ricette:
- "pr aperti"
- "pr da revieware"
- "pr velocity"
```

---

## 📊 Impact Assessment

| Estrazione | Priority | Effort | Value | Users |
|------------|----------|--------|-------|-------|
| **Test Management** | HIGH | Medium | High | QA, Dev |
| **Pull Requests** | HIGH | Medium | High | Dev |
| **Builds Detail** | MEDIUM | Low | Medium | DevOps |
| **Work Relations** | MEDIUM | Medium | Medium | PM |
| **History** | MEDIUM | Low | Low | Audit |
| **Team/Assignments** | LOW | Low | Medium | PM |
| **Areas** | LOW | Very Low | Low | PM |
| **Tags Analytics** | LOW | Very Low | Low | All |
| **Saved Queries** | VERY LOW | Medium | Low | Power Users |
| **Custom Fields** | VERY LOW | Varies | Varies | Custom |

---

## 🎯 Recommendation

**Implementa prima**:
1. **Test Management** (massimo ROI per QA)
2. **Pull Requests** (dev workflow optimization)

**Poi considera**:
3. Builds/Releases dettaglio (se CI/CD monitoring importante)
4. Work Item Relations (se portfolio management critical)

**Il resto**: Nice-to-have, bassa priorità

---

**Total Possible Extractions**: ~15-20 tipologie  
**Currently Covered**: ~7-8 (40%)  
**High Priority Gap**: Test Management, Pull Requests
