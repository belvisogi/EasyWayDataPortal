---
title: Multi-Agent Orchestration con Ponderazione e Round Table
tags: [domain/control-plane, layer/spec, audience/architect, audience/dev, privacy/internal, language/it, agents, orchestration, n8n, governance, decision-framework]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-agent-orchestration-weighting
chunk_hint: 400-600
entities: []
include: true
summary: Sistema di orchestrazione multi-agent con weighting qualità-focused, peer review a tavola rotonda, eliminazione outlier e 5-question framework per decision making robusto.
llm: 
pii: none
owner: team-platform
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

# Multi-Agent Orchestration con Ponderazione e Round Table

## Contesto

Quando un task è **complesso** o **cross-domain**, un singolo agent potrebbe non avere:
- Sufficiente expertise in tutti gli aspetti
- Prospettiva completa sui rischi
- Capacità di bilanciare trade-off

Questo sistema risolve il problema con **orchestrazione multi-agent ponderata** e **peer review a tavola rotonda**.

---

> [!IMPORTANT]
> ## ⚠️ Implementation Recommendation
> 
> **Questo documento descrive il design COMPLETO del sistema Round Table**, ma dopo analisi critica dei trade-off, **si raccomanda di NON implementare il sistema full**.
> 
> **INVECE, implementare**: **"Expert + Reviewer + Async Learning"**
> 
> **Rationale**:
> - Full round table: troppo complesso (16× API calls), latency 3-5min, ROI negativo
> - Expert + Reviewer: 80% del valore, 20% della complexity, latency < 1min
> - Async learning: accumula quality data senza impatto latency
> 
> **Vedi sezione finale**: [Raccomandazione Pragmatica](#raccomandazione-pragmatica-expert--reviewer) per dettagli implementativi.
> 
> Questo documento rimane come **reference design** per scenari futuri dove full orchestration sia giustificata.

---

## Principi Cardine

### 1. Quality over Speed
Il sistema privilegia **accuratezza** su velocità:
- Weighting basato su `historical_accuracy` (non solo success rate)
- Penalità 30% se agent non rispetta quality threshold (accuracy < 95%)

### 2. Prospettiva Esterna (Outsider Agent)
Include sempre 1 agent con **bassa expertise** nel dominio:
- Ruolo: devil's advocate, red-teaming
- Scopo: evitare groupthink, portare prospettiva critica

### 3. Eliminazione Outlier
Scarta proposte agli estremi (troppo ottimistiche o pessimistiche):
- Riduce bias
- Converge su "middle ground" realistico

### 4. Framework Strutturato (5 Domande)
Ogni agent risponde a:
1. **Che cosa?** (obiettivo, deliverables)
2. **Come?** (approach, tools, steps)
3. **Impatti?** (sistemi, stakeholder, rischi)
4. **Costi/Benefici?** (effort, value, trade-offs)
5. **Perché è importante?** (strategic value, urgency, long-term)

---

## Architettura Completa

```mermaid
graph TB
    A[User Request / Intent] --> B{Intent Analysis}
    B --> C[Load All Candidate Agents]
    
    C --> D1[Calculate Weights<br/>Quality-Focused]
    D1 --> D2[domain_expertise: 35%]
    D1 --> D3[task_complexity_fit: 25%]
    D1 --> D4[historical_accuracy: 30%]
    D1 --> D5[quality_score: 10%]
    
    D2 --> E{Decision Point}
    D3 --> E
    D4 --> E
    D5 --> E
    
    E -->|Single Agent Mode| F[Weight > 85<br/>Confidence: High<br/>Quality > 0.95]
    E -->|Multi-Agent Mode| G[Weight < 85 OR<br/>Confidence < High OR<br/>Quality < 0.95]
    
    F --> Z[Execute Single Agent]
    
    G --> H[Select Top 3 Experts]
    G --> I[Select 1 Outsider<br/>expertise < 30%]
    
    H --> J1[Agent 1: Weight=85]
    H --> J2[Agent 2: Weight=70]
    H --> J3[Agent 3: Weight=60]
    I --> J4["Agent 4 (Outsider): Weight=20 🎯"]
    
    J1 --> K[PHASE 1: 5-Question Framework]
    J2 --> K
    J3 --> K
    J4 --> K
    
    K --> L1[Agent 1 Proposal + Decision]
    K --> L2[Agent 2 Proposal + Decision]
    K --> L3[Agent 3 Proposal + Decision]
    K --> L4[Agent 4 Proposal + Decision]
    
    L1 --> M[PHASE 2: Round Table Scoring]
    L2 --> M
    L3 --> M
    L4 --> M
    
    M --> N1[Agent 1 scores<br/>P2, P3, P4]
    M --> N2[Agent 2 scores<br/>P1, P3, P4]
    M --> N3[Agent 3 scores<br/>P1, P2, P4]
    M --> N4[Agent 4 scores<br/>P1, P2, P3]
    
    N1 --> O[Aggregate<br/>Peer Scores]
    N2 --> O
    N3 --> O
    N4 --> O
    
    O --> P[Weighted Average<br/>per Proposal]
    P --> Q[Sort by<br/>Avg Score DESC]
    
    Q --> R[PHASE 3: Eliminate Outliers]
    R --> S1["❌ Highest Score<br/>(too optimistic)"]
    R --> S2["❌ Lowest Score<br/>(too pessimistic)"]
    R --> T["✅ Keep Middle 2-3<br/>Proposals"]
    
    T --> U[PHASE 4: Decision Matrix]
    U --> V[Synthesize Consensus Plan]
    
    V --> W{Requires<br/>Human Approval?}
    W -->|High Impact<br/>OR Low Confidence| X[Present to Human]
    W -->|Low Risk<br/>AND High Confidence| Y[Auto-Execute]
    
    X --> AA{Approved?}
    AA -->|No| AB[Revise Plan]
    AB --> K
    AA -->|Yes| Y
    
    Y --> AC[Execute Plan]
    AC --> AD[Log Decision Trace<br/>events.jsonl]
    
    Z --> AD
    
    style J4 fill:#ff9,stroke:#f66,stroke-width:3px
    style M fill:#f9f,stroke:#909,stroke-width:3px
    style R fill:#f99,stroke:#c00,stroke-width:2px
    style T fill:#9f9,stroke:#060,stroke-width:2px
    style V fill:#99f,stroke:#006,stroke-width:2px
```sql

---

## Flow Dettagliato per Fase

### Phase 0: Intent Analysis & Weight Calculation

```mermaid
sequenceDiagram
    participant User
    participant Orchestrator
    participant WeightEngine
    participant AgentRegistry
    
    User->>Orchestrator: Intent + Context
    Orchestrator->>Orchestrator: Infer task_type (db, security, etc.)
    Orchestrator->>AgentRegistry: Load candidates for task_type
    AgentRegistry-->>Orchestrator: List of capable agents
    
    loop For each agent
        Orchestrator->>WeightEngine: Calculate weight(agent, task_type)
        WeightEngine->>WeightEngine: domain_expertise * 0.35
        WeightEngine->>WeightEngine: complexity_fit * 0.25
        WeightEngine->>WeightEngine: historical_accuracy * 0.30
        WeightEngine->>WeightEngine: quality_score * 0.10
        WeightEngine->>WeightEngine: Apply quality penalty if needed
        WeightEngine-->>Orchestrator: Final weight + confidence
    end
    
    Orchestrator->>Orchestrator: Sort agents by weight DESC
    Orchestrator->>Orchestrator: Decision: Single vs Multi-Agent
    
    alt Single Agent Mode
        Orchestrator->>Orchestrator: Top agent (weight > 85, quality > 0.95)
    else Multi-Agent Mode
        Orchestrator->>Orchestrator: Select top 3 experts
        Orchestrator->>Orchestrator: Select 1 outsider (expertise < 30%)
    end
```sql

### Phase 1: 5-Question Framework (Parallel)

```mermaid
sequenceDiagram
    participant Orchestrator
    participant Agent1
    participant Agent2
    participant Agent3
    participant Agent4
    
    par Agent 1
        Orchestrator->>Agent1: Answer 5 questions
        Agent1->>Agent1: What? How? Impacts? Cost-Benefit? Why Important?
        Agent1->>Agent1: Generate Proposal
        Agent1-->>Orchestrator: Decision + Proposal (P1)
    and Agent 2
        Orchestrator->>Agent2: Answer 5 questions
        Agent2->>Agent2: What? How? Impacts? Cost-Benefit? Why Important?
        Agent2->>Agent2: Generate Proposal
        Agent2-->>Orchestrator: Decision + Proposal (P2)
    and Agent 3
        Orchestrator->>Agent3: Answer 5 questions
        Agent3->>Agent3: What? How? Impacts? Cost-Benefit? Why Important?
        Agent3->>Agent3: Generate Proposal
        Agent3-->>Orchestrator: Decision + Proposal (P3)
    and Agent 4 (Outsider)
        Orchestrator->>Agent4: Answer 5 questions
        Agent4->>Agent4: What? How? Impacts? Cost-Benefit? Why Important?
        Agent4->>Agent4: Generate Proposal (external perspective)
        Agent4-->>Orchestrator: Decision + Proposal (P4)
    end
    
    Orchestrator->>Orchestrator: Collect all 4 proposals
```sql

### Phase 2: Round Table Peer Scoring

```mermaid
sequenceDiagram
    participant Orchestrator
    participant Agent1
    participant Agent2
    participant Agent3
    participant Agent4
    
    Note over Orchestrator: Each agent scores ALL other proposals
    
    rect rgb(255, 240, 245)
        Note over Agent1: Agent 1 evaluates P2, P3, P4
        Orchestrator->>Agent1: Score Proposal P2
        Agent1->>Agent1: Feasibility (1-10)<br/>Completeness (1-10)<br/>Risk Mitigation (1-10)<br/>Alignment (1-10)<br/>Innovation (1-10)
        Agent1-->>Orchestrator: Score P2 = 8.5 + Justification
        
        Orchestrator->>Agent1: Score Proposal P3
        Agent1-->>Orchestrator: Score P3 = 7.0 + Justification
        
        Orchestrator->>Agent1: Score Proposal P4
        Agent1-->>Orchestrator: Score P4 = 6.0 + Justification
    end
    
    rect rgb(240, 255, 240)
        Note over Agent2: Agent 2 evaluates P1, P3, P4
        Orchestrator->>Agent2: Score Proposals
        Agent2-->>Orchestrator: P1=9.0, P3=7.5, P4=5.5
    end
    
    rect rgb(240, 240, 255)
        Note over Agent3: Agent 3 evaluates P1, P2, P4
        Orchestrator->>Agent3: Score Proposals
        Agent3-->>Orchestrator: P1=8.8, P2=8.0, P4=6.5
    end
    
    rect rgb(255, 255, 240)
        Note over Agent4: Agent 4 (Outsider) evaluates P1, P2, P3
        Orchestrator->>Agent4: Score Proposals
        Agent4-->>Orchestrator: P1=7.0, P2=6.5, P3=8.5
    end
    
    Orchestrator->>Orchestrator: Aggregate scores<br/>Weighted by evaluator weight
```sql

### Phase 3: Outlier Elimination

```mermaid
graph LR
    A[4 Proposals<br/>with Scores] --> B[Sort by<br/>Avg Score DESC]
    
    B --> C1["P1: Avg=8.6 ⬆️"]
    B --> C2["P2: Avg=7.5"]
    B --> C3["P3: Avg=7.3"]
    B --> C4["P4: Avg=6.0 ⬇️"]
    
    C1 --> D1["❌ ELIMINATED<br/>(Highest)"]
    C2 --> E["✅ KEPT"]
    C3 --> E
    C4 --> D2["❌ ELIMINATED<br/>(Lowest)"]
    
    E --> F[Final Proposals: P2, P3]
    
    style C1 fill:#fcc,stroke:#c00
    style C4 fill:#fcc,stroke:#c00
    style E fill:#cfc,stroke:#0c0
    style F fill:#9f9,stroke:#060,stroke-width:3px
```sql

### Phase 4: Decision Matrix & Consensus

```mermaid
graph TD
    A[Final Proposals<br/>P2 + P3] --> B[Extract Key Elements]
    
    B --> C1[P2: What + How + Impacts]
    B --> C2[P3: What + How + Impacts]
    
    C1 --> D[Synthesize<br/>Consensus Plan]
    C2 --> D
    
    D --> E[Merge complementary aspects]
    E --> F[Resolve conflicts<br/>weighted by agent weight]
    
    F --> G{High Impact<br/>OR<br/>Low Confidence?}
    
    G -->|Yes| H[Human Approval Required]
    G -->|No| I[Auto-Execute]
    
    H --> J[Present:<br/>- Consensus Plan<br/>- Eliminated Proposals<br/>- Scoring Matrix<br/>- Justifications]
    
    J --> K{User Approves?}
    K -->|Yes| I
    K -->|No| L[Revision Requested]
    L --> M[Return to Phase 1]
    
    I --> N[Execute Plan]
    N --> O[Log Decision Trace]
    
    style G fill:#ff9,stroke:#f90
    style H fill:#f99,stroke:#c00
    style I fill:#9f9,stroke:#060
    style O fill:#99f,stroke:#006
```sql

---

## Esempio Pratico Completo

### Scenario
**Task**: Creare tabella `USERS` con RLS multi-tenant

**Context**:
- Database: PORTAL
- Requirement: Isolamento tenant-aware
- Deadline: 2 settimane (onboarding cliente enterprise)
- Stakeholder: team-dev, team-ops, team-security

### Phase 0: Agent Selection

**Candidates loaded**:
- agent_dba (domain/db expertise: 95)
- agent_security (domain/security expertise: 90, domain/db: 60)
- agent_governance (domain/governance expertise: 80, domain/db: 40)
- agent_frontend (domain/frontend expertise: 85, domain/db: 15) ← outsider
- agent_api (domain/api expertise: 75, domain/db: 30)

**Weight calculation**:
```sql
agent_dba:      0.35*95 + 0.25*90 + 0.30*92 + 0.10*85 = 88.1
agent_security: 0.35*60 + 0.25*85 + 0.30*88 + 0.10*90 = 75.1
agent_governance: 0.35*40 + 0.25*70 + 0.30*75 + 0.10*80 = 63.5
agent_frontend: 0.35*15 + 0.25*20 + 0.30*60 + 0.10*30 = 31.3
```sql

**Decision**: Multi-Agent Mode (top weight 88.1 < threshold 90 per task critico security)

**Selected**:
1. agent_dba (88.1) - expert
2. agent_security (75.1) - expert
3. agent_governance (63.5) - expert
4. agent_frontend (31.3) - **outsider**

### Phase 1: Proposals

**Agent DBA**:
```yaml
what:
  objective: "Flyway migration per tabella USERS con RLS tenant-aware"
  deliverables: ["DDL V_xxx_create_users.sql", "RLS policy", "Unit test"]
  scope: "DB PORTAL, schema dbo"
how:
  approach: "Flyway-first, template-based DDL generation"
  tools: ["Flyway", "sqlcmd", "ewctl"]
  steps:
    - "Generate DDL da template con naming conventions"
    - "Add RLS policy CREATE SECURITY POLICY"
    - "Create Flyway migration V_020_create_users.sql"
    - "Test in staging"
impacts:
  systems_affected: ["DB PORTAL", "API auth layer (future)"]
  stakeholders: ["team-dev", "team-dba", "team-ops"]
  risks: ["Breaking change se RLS mal configurato", "Performance overhead RLS"]
  dependencies: ["Flyway baseline", "tenant_id standard column"]
cost_benefit:
  effort: "2h"
  value: {business: 7, technical: 8, security: 9}
  trade_offs: ["Pro: governance-driven", "Con: test complessi per RLS"]
why_important:
  strategic_value: "Foundation multi-tenancy scalabile"
  urgency_reason: "Cliente enterprise onboarding deadline 2 settimane"
  long_term_impact: ["Pattern riusabile", "Compliance audit ready"]
  alternatives_considered:
    - {alt: "DB separati per tenant", rejected: "Costi infra"}
```sql

**Agent Security**:
```yaml
what: "Tabella USERS + RLS + credential rotation"
how: "Flyway + RLS + post-migration secret rotation"
effort: "3h"
...
emphasis: "Security-first con audit logging"
```sql

**Agent Governance**:
```yaml
what: "Tabella USERS + RLS + KB update + Wiki + checklist"
how: "Flyway + RLS + documentation governance"
effort: "4h"
...
emphasis: "Governance completeness (KB, Wiki, gates)"
```sql

**Agent Frontend (Outsider)**:
```yaml
what: "Skip DB RLS, use API middleware for tenant isolation"
how: "Middleware layer con tenant_id injection"
effort: "1h"
...
emphasis: "Alternative approach non DB-native"
rationale: "Outsider perspective: evitare complessità DB"
```sql

### Phase 2: Peer Scoring

| Proposal | By DBA | By Security | By Governance | By Frontend | **Weighted Avg** |
|----------|---------|-------------|---------------|-------------|------------------|
| **P1 (DBA)** | - | 8.5×75.1 | 8.0×63.5 | 7.0×31.3 | **8.1** |
| **P2 (Security)** | 7.5×88.1 | - | 9.0×63.5 | 6.5×31.3 | **7.8** |
| **P3 (Governance)** | 6.5×88.1 | 7.0×75.1 | - | 8.0×31.3 | **6.9** |
| **P4 (Frontend)** | 4.0×88.1 | 3.5×75.1 | 5.0×63.5 | - | **4.2** |

**Scoring justifications** (sample):
- DBA scores Security=7.5: "Good on security but underestimates Flyway complexity"
- Security scores DBA=8.5: "Strong DDL but missing credential rotation plan"
- Frontend scores Governance=8.0: "Comprehensive but overengineered for MVP"

### Phase 3: Elimination

**Sorted**:
1. P1 (DBA): 8.1 ⬆️ **ELIMINATED** (highest)
2. P2 (Security): 7.8 ✅ KEPT
3. P3 (Governance): 6.9 ✅ KEPT
4. P4 (Frontend): 4.2 ⬇️ **ELIMINATED** (lowest)

**Rationale**:
- P1 eliminata: Troppo ottimistica, manca security hardening
- P4 eliminata: Soluzione non DB-native, mismatch con requirement

### Phase 4: Consensus

**Synthesized Plan** (da P2 + P3):
```yaml
what: "Tabella USERS con RLS, credential rotation, KB/Wiki update"
how:
  - "Flyway migration V_020_create_users.sql"
  - "RLS policy CREATE SECURITY POLICY tenant_isolation"
  - "Post-migration: Azure Key Vault credential rotation"
  - "Update agents/kb/recipes.jsonl con entry db-table-create-with-rls"
  - "Update Wiki/db-user-access-management.md con RLS example"
  - "Pre-deploy checklist: DB drift check + staging test"
impacts:
  - "DB PORTAL affected (new table + RLS policy)"
  - "API layer may need RLS-aware queries (future)"
  - "Stakeholder: dev, ops, security, dba"
cost_benefit:
  effort: "3.5h" # median tra 3h e 4h
  value: {business: 8, technical: 9, security: 10}
why_important:
  - "Strategic: multi-tenancy foundation compliance-ready"
  - "Urgency: cliente enterprise deadline 2 settimane"
  - "Long-term: pattern scalabile + audit trail"
confidence: 0.82
requires_approval: true # High impact + security critical
```sql

**Human Approval UI**:
```sql
🎯 Multi-Agent Consensus (2 agents: Security + Governance)

Eliminated Proposals:
  ❌ DBA (score 8.1): Too optimistic, missing security hardening
  ❌ Frontend (score 4.2): Non DB-native approach, rejected

Final Plan:
  ✅ Flyway + RLS + Credential Rotation + Documentation
  ⏱ Effort: 3.5h
  ⭐ Confidence: 82%
  
Critical Items:
  ⚠ RLS policy mandatory (agent_security)
  ⚠ KB/Wiki update required (agent_governance)
  
Approve to proceed?
[✓ Approve] [✗ Reject] [📝 Revise]
```sql

---

## Criteri di Scoring Dettagliati

Ogni agent valuta le proposte degli altri con **5 criteri** (1-10):

### 1. Feasibility (Fattibilità)
- **10**: Implementabile immediatamente, zero blockers
- **7-9**: Qualche challenge ma fattibile in timeframe
- **4-6**: Richiede workaround o assunzioni forti
- **1-3**: Impraticabile o missing critical dependencies

**Example**:
- P1 (DBA Flyway): 9/10 (fattibile, baseline exists)
- P4 (API middleware): 5/10 (richiede refactor API layer)

### 2. Completeness (Completezza)
- **10**: Risponde a tutte le 5 domande, copre tutti gli aspetti
- **7-9**: Minori gap, facilmente colmabili
- **4-6**: Aspetti significativi mancanti (es. testing, rollback)
- **1-3**: Incomplete, major gaps

**Example**:
- P3 (Governance): 10/10 (KB, Wiki, checklist, tutto coperto)
- P1 (DBA): 7/10 (manca credential rotation, audit log)

### 3. Risk Mitigation (Gestione Rischi)
- **10**: Tutti i rischi identificati e mitigati
- **7-9**: Rischi principali gestiti, minori accettabili
- **4-6**: Alcuni rischi non addressati
- **1-3**: Risk-blind, no mitigation

**Example**:
- P2 (Security): 9/10 (RLS + credential rotation + audit)
- P4 (Frontend): 3/10 (security risk API layer, no audit)

### 4. Alignment (Allineamento)
- **10**: Perfetto allineamento con governance, KB, best practices
- **7-9**: Allineato con minori deviazioni accettabili
- **4-6**: Parziale allineamento, richiede adjustment
- **1-3**: Ignore governance/standards

**Example**:
- P3 (Governance): 10/10 (follow tutti i gate, KB update)
- P4 (Frontend): 4/10 (non segue Flyway-first principle)

### 5. Innovation (Innovazione)
- **10**: Soluzione creativa, efficace, elegante
- **7-9**: Good approach, qualche innovazione
- **4-6**: Standard approach, no particolarità
- **1-3**: Conventional, no value-add

**Example**:
- P4 (Frontend): 7/10 (alternative approach, out-of-box thinking)
- P1 (DBA): 5/10 (standard Flyway pattern, no innovation)

---

## Limitazioni e Svantaggi (Critical Analysis)

### ❌ 1. Overhead Temporale Significativo

**Problema**:
- Single agent: 1 execution
- Multi-agent con round table: 4 executions (proposte) + 12 scoring calls (4 agent × 3 proposte ciascuno)
- **16× chiamate totali** vs single agent

**Impact**:
- Latency: 30s single agent → **3-5 minuti** multi-agent
- Cost: 16× token usage (LLM API calls)
- Risorse: parallelizzazione richiede compute capacity

**Mitigation**:
- Usare multi-agent SOLO per task complessi (non routine)
- Threshold strict per single-agent mode (weight > 85 + quality > 0.95)
- Parallelize scoring calls dove possibile
- Cache proposal templates per task simili

---

### ❌ 2. Complessità Implementativa

**Problema**:
- Ogni agent deve implementare:
  - `answer5Questions()`
  - `generateProposal()`
  - `scoreProposal()` con 5 criteri
- Orchestrator complesso:
  - Weight calculation con quality metrics
  - Round table coordination
  - Outlier detection
  - Consensus synthesis

**Impact**:
- Development effort: ~2-3 settimane per implementazione completa
- Testing complexity: combinatorial explosion (4 agent × 4 proposals × 5 criteri = 80 test cases)
- Manutenzione: più componenti = più surface area per bugs

**Mitigation**:
- Phased rollout (start con 3 pilot agents)
- Template-based implementation per `scoreProposal()`
- Extensive unit testing su weight calculation logic
- Logging dettagliato per debug

---

### ❌ 3. Rischio di "Consensus Mediocrity"

**Problema**:
- Eliminando gli estremi (outlier), si scartano anche:
  - Soluzioni innovative (score alto = troppo ottimistiche?)
  - Alternative radicali (score basso = troppo diverse?)
- Consensus potrebbe convergere su **soluzione "safe" ma subottimale**

**Impact**:
- Manca brilliance delle soluzioni top-rated
- Evita rischi ma anche opportunità
- "Design by committee" anti-pattern

**Mitigation**:
- **Non eliminare SEMPRE**: se variance bassa (< 1.5), significa consensus forte → keep all proposals
- Human review degli outlier eliminati (transparent log)
- Exception per task innovation-driven (es. R&D, MVP)
- Weighted towards expertise (top agent ha comunque score ponderato alto)

---

### ❌ 4. Quality Metrics Accuracy

**Problema**:
- `historical_accuracy`, `quality_score` richiedono:
  - Storico decisioni precedenti (cold start problem)
  - Ground truth validation (chi decide se decision era corretta?)
  - Peer review score tracking (manual effort)

**Impact**:
- Nuovi agent hanno weight penalty (no historical data)
- Quality metrics potrebbero essere gamed
- Feedback loop lento (1-2 sprint per accumulare dati)

**Mitigation**:
- Bootstrap con default weights (50% per nuovi agent)
- Human labeling per prime 10-20 decisioni
- Automated validation dove possibile (es. test pass/fail)
- Decay factor per historical data (più recente = più rilevante)

---

### ❌ 5. Outsider Agent Paradox

**Problema**:
- Outsider ha **basso peso** (20) → **basso impatto** su scoring aggregato
- Ma è incluso proprio per prospettiva diversa
- Rischio: voce outsider ignorata nel consensus finale

**Impact**:
- Groupthink non completamente evitato
- Outsider perspective utile solo se score variance alta (red flag)
- Può essere sempre eliminato come outlier (score basso)

**Mitigation**:
- Track outlier elimination frequency: se outsider SEMPRE eliminato → rivedere strategy
- Weighted minority vote: se outsider score è minority ma forte, flag per human
- Exception handling: se outsider identifica CRITICAL risk, escalate anche se score basso
- Threshold dinamico: se top 3 expert in strong agreement, outsider peso aumentato

---

### ❌ 6. Scaling Challenges

**Problema**:
- Attualmente 4 agent limit (3 expert + 1 outsider)
- Con 22 agent totali nel progetto, molti esclusi
- Non usa expertise di agent non selezionati

**Impact**:
- Specialisti di nicchia potrebbero essere skippati
- Alcuni agent hanno overlap expertise (es. agent_api + agent_backend per REST task)
- Selection bias verso agent generalist

**Mitigation**:
- Dynamic agent selection basata su task sub-components
- Hierarchical orchestration (coordinator delega a sub-orchestrator)
- Expert consultation on-demand (agent può chiamare altro agent)
- Increase max agents to 5-6 per task molto complessi

---

### ❌ 7. Transparency vs Complexity Trade-off

**Problema**:
- Scoring matrix + outlier elimination + consensus = molto da spiegare a human
- Risk di "black box" perception se troppi dettagli
- User fatigue: troppi dati → approval shallow

**Impact**:
- Human approval potrebbe diventare rubber-stamp
- Difficile debuggare quando consensus è sbagliato
- Onboarding barrier per nuovi team member

**Mitigation**:
- **Layered UI**: summary view + details on-demand
- **Visualizations**: radar chart per 5 criteri, heatmap per scoring matrix
- **Explainable AI**: justification field obbligatorio su ogni score
- **Audit trail**: full log per post-mortem analysis

---

### ❌ 8. Cost/Benefit Sbilanciato per Task Semplici

**Problema**:
- Multi-agent overkill per task routine (es. "update README")
- Soglia single-agent (weight > 85) potrebbe non attivare per false negative

**Impact**:
- Spreco risorse su task banali
- User frustration per latency su operazioni veloci
- Budget LLM API burn rate alto

**Mitigation**:
- **Task classification upfront**: routine vs complex
- **Confidence boosting**: se task match exact recipe in KB → single agent con high confidence
- **User override**: `--force-single-agent` flag
- **Cost monitoring**: alert se spesa supera threshold mensile

---

## Trade-Off Summary Table

| Aspetto | Pro ✅ | Contro ❌ | Severity |
|---------|--------|-----------|----------|
| **Quality** | Accuracy > 95% consensus | Latency 3-5min vs 30s | Medium |
| **Robustezza** | Peer review anti-bias | Implementazione complessa | High |
| **Innovazione** | Outsider perspective | Consensus mediocrity risk | High |
| **Scalabilità** | Multi-agent su task critici | 16× token usage | High |
| **Trasparenza** | Full audit trail | UI complexity | Medium |
| **Costo** | Quality-first | Budget LLM burn | Medium |

---

## Quando Usare Multi-Agent vs Single Agent

### ✅ Use Multi-Agent When:
- Task **critico** (security, compliance, production)
- **Cross-domain** (es. DB + Security + API)
- **Stakeholder multipli** (> 3 team impattati)
- **Alto rischio** (breaking change, data loss potential)
- **Incertezza alta** (no recipe esatto in KB)

### ✅ Use Single Agent When:
- Task **routine** (match recipe in KB)
- **Singolo dominio** (es. pure DB DDL)
- **Low risk** (read-only, reversible)
- **Time-sensitive** (hotfix, outage)
- **High confidence** (agent weight > 85, quality > 0.95)

---

## Metriche di Successo

| Metrica | Target | Rationale |
|---------|--------|-----------|
| Consensus quality | Human approval > 85% | Validation che consensus è robusto |
| Outlier accuracy | Eliminated != chosen < 15% | Outlier detection non sbaglia troppo |
| Latency | < 5min per 4-agent round table | User tolerance threshold |
| Cost | < €0.50 per orchestration | Budget sustainability |
| Adoption | 30% task usano multi-agent | Right balance routine vs critical |

---

## Riferimenti

### File Source of Truth
- `agents/core/multi-agent-coordinator.js` - Implementazione coordinatore
- `agents/core/schemas/agent-weight.schema.json` - Schema weighting
- `docs/agentic/templates/agent-decision-framework.json` - 5-question template
- `docs/agentic/templates/decision-matrix.template.json` - Decision matrix

### Wiki Correlate
- [Orchestrator n8n (WHAT)](./orchestrations/orchestrator-n8n.md) - Dispatch unico
- [Agent Priority Rules](./agent-priority-and-checklists.md) - Priority.json
- [Agents Registry](./control-plane/agents-registry.md) - Lista completa agent
- [Tag Scopes & Retrieval Bundles](./docs-tag-scopes.md) - Context loading

### External
- [Consensus Decision Making](https://en.wikipedia.org/wiki/Consensus_decision-making)
- [Outlier Detection Methods](https://en.wikipedia.org/wiki/Outlier)
## Raccomandazione Pragmatica: Expert + Reviewer

### Design Consigliato

```mermaid
graph LR
    A[Intent] --> B{Complexity?}
    B -->|Simple| C[Single Agent]
    B -->|Complex| D[Expert + Reviewer]
    
    D --> E[Expert: Propose]
    E --> F[Reviewer: Score]
    F --> G{Score >= 7?}
    G -->|Yes| H[Auto-Execute]
    G -->|No| I[Human Review]
    
    H --> J[Async Peer Review]
    I --> K{Human Decision}
    K -->|Approve Expert| H
    K -->|Use Reviewer| L[Reviewer Execute]
    
    style D fill:#9f9,stroke:#060,stroke-width:2px
    style F fill:#99f,stroke:#006
    style J fill:#ff9,stroke:#f90
```sql

### Componenti

**1. Expert Selection** (come round table, ma solo top 1):
- Weight calculation quality-focused
- Select agent con weight > 80 AND quality > 0.90

**2. Reviewer Selection**:
- Cross-domain agent (diverso dominio dall'expert)
- Weight > 60 (competente ma non necessariamente top)

**3. Simplified Framework** (3 domande):
- What? (objective, deliverables)
- How? (approach, steps)
- Impacts? (risks, stakeholders)

**4. Reviewer Scoring** (3 criteri):
- Feasibility (40%)
- Risk mitigation (40%)
- Alignment (20%)
- Threshold: 7.0/10 per auto-approve

**5. Async Learning**:
- Post-execution, sample 20% task
- 2-3 peer agents score decision
- Update quality metrics DB
- No blocking, pure learning

### Benefici vs Full Round Table

| Metrica | Full Round Table | Expert + Reviewer | Miglioramento |
|---------|------------------|-------------------|---------------|
| Latency | 3-5 min | < 1 min | **5× più veloce** |
| API Calls | 16× | 4× | **4× meno** |
| Complexity | Alta | Media | **60% più semplice** |
| Quality gain | 95% | 80% | **-15% quality OK** |
| Cost | €0.50 | €0.10 | **5× più economico** |

### Implementation Checklist

- [ ] Implement `scoreProposal()` con 3 criteri (feasibility, risk, alignment)
- [ ] Add reviewer selection logic (cross-domain)
- [ ] Integrate con `orchestrator.n8n.dispatch`
- [ ] Add task_boundary tracking per expert
- [ ] Implement async peer review (20% sampling)
- [ ] Create quality metrics DB schema
- [ ] Test su 5 task pilot
- [ ] Measure: latency, approval rate, cost

### Quando Evolvere a Full Round Table

Solo se TUTTE le condizioni sono vere:
- ✅ Expert + Reviewer in produzione > 6 mesi
- ✅ Human approval rate < 70% (troppe escalation)
- ✅ Task criticality aumenta (più compliance/security)
- ✅ Budget disponibile per latency + cost
- ✅ Team capacity per maintain complexity

Altrimenti: **stay con Expert + Reviewer**.

---

**Status**: RECOMMENDED APPROACH (2026-01-13)  
**Owner**: team-platform  
**Next Review**: 2026-07-01 (6 months)


