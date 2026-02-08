# 🔍 Agents Gap Analysis - Quanto siamo lontani dagli standard?

**Date:** 2026-02-08
**Auditor:** Claude Sonnet 4.5
**Baseline:** Framework 2.0 Standards
**Scope:** 35 agents in production

---

## 📊 EXECUTIVE SUMMARY - Siamo MOLTO lontani

### Scorecard Generale

| Criterio | Target | Attuale | Gap | Gravità |
|----------|--------|---------|-----|---------|
| **Manifest Schema Compliance** | 100% | **0%** | -100% | 🔴 CRITICA |
| **Skills System Adoption** | 100% | **0%** | -100% | 🔴 CRITICA |
| **Memory System (context.json)** | 100% | **80%** | -20% | 🟡 MEDIA |
| **Priority.json** | 100% | **17%** | -83% | 🔴 CRITICA |
| **Templates/Intent** | 100% | **23%** | -77% | 🔴 CRITICA |
| **LLM Integration** | 30% (top 10) | **0%** | -30% | 🟠 ALTA |
| **Documentation Quality** | 100% | **86%** | -14% | 🟢 BASSA |
| **Evolution Level** | 2.0 avg | **1.0** | -1.0 | 🔴 CRITICA |

**Overall Compliance Score: 23/100** 🔴

---

## 🚨 PROBLEMA #1: MANIFEST SCHEMA - 0% Compliance (CRITICO)

### Cosa Dovrebbe Essere (Standard v2.0)

```json
{
  "id": "agent_xxx",
  "name": "agent_xxx",
  "role": "Agent_Xxx",
  "description": "...",
  "owner": "team-platform",
  "version": "1.0.0",

  "llm_config": {
    "model": "gpt-4-turbo",
    "temperature": 0.0,
    "system_prompt": "agents/agent_xxx/PROMPTS.md",
    "tools": ["function_calling"]
  },

  "context_config": {
    "memory_files": ["agents/kb/recipes.jsonl"],
    "context_limit_tokens": 128000
  },

  "allowed_tools": ["pwsh", "git", "az"],

  "skills_required": [
    "security.cve-scan",
    "utilities.version-compatibility"
  ],

  "actions": [
    {
      "name": "xxx:action",
      "description": "...",
      "uses_skills": ["security.cve-scan"],
      "params": { ... }
    }
  ],

  "allowed_paths": {
    "read": ["agents/", "Wiki/"],
    "write": ["agents/logs/"]
  },

  "knowledge_sources": ["Wiki/EasyWayData.wiki/..."]
}
```

### Cosa C'è Realmente

**Esempio: agent_security (uno dei MIGLIORI)**

```json
{
  "role": "Agent_Security",
  "description": "...",
  "allowed_paths": [...],
  "allowed_tools": ["pwsh", "az"],
  "required_gates": ["KB_Consistency"],
  "knowledge_sources": [...],
  "actions": [...],
  "name": "agent_security",
  "readme": "README.md",
  "classification": "arm"
}
```

**Problemi:**
- ❌ Manca `id`
- ❌ Manca `owner`
- ❌ Manca `version`
- ❌ **Manca COMPLETAMENTE `llm_config`** (no LLM reasoning)
- ❌ **Manca COMPLETAMENTE `context_config`**
- ❌ **Manca COMPLETAMENTE `skills_required`**
- ❌ `actions` non hanno `uses_skills`
- ❌ `actions` non hanno `params` schema

**Esempio: agent_template (IL TEMPLATE BASE)**

```json
{
  "id": "agent_template",
  "name": "agent_template",
  "role": "Template",
  "description": "...",
  "owner": "team-platform",
  "version": "0.1.0",
  "llm_config": {
    "model": "gpt-4-turbo",
    "temperature": 0.0,
    "system_prompt": "agents/agent_template/PROMPTS.md",
    "tools": ["web_search", "code_interpreter"]
  },
  "context_config": {...},
  "allowed_tools": ["pwsh", "git", "az"],
  "actions": [...],
  "allowed_paths": {...}
}
```

**Questo è MEGLIO ma:**
- ❌ **NON ha `skills_required`** (pre-Framework 2.0)
- ❌ **NON ha `skills_optional`**
- ❌ `actions` non hanno `uses_skills`

### Gap Analysis

| Campo | Presente in Manifest | Corretto? |
|-------|---------------------|-----------|
| `id` | 80% | ✅ |
| `name` | 90% | ✅ |
| `role` | 90% | ✅ |
| `description` | 95% | ✅ |
| `owner` | 30% | ❌ |
| `version` | 50% | ⚠️ (spesso "0.1.0" never updated) |
| `llm_config` | **20%** | ❌ CRITICAL |
| `context_config` | **10%** | ❌ CRITICAL |
| `allowed_tools` | 60% | ⚠️ |
| **`skills_required`** | **0%** | 🔴 **ZERO ADOPTION** |
| **`skills_optional`** | **0%** | 🔴 **ZERO ADOPTION** |
| `actions` | 80% | ⚠️ (incomplete schema) |
| `allowed_paths` | 70% | ⚠️ |
| `knowledge_sources` | 50% | ⚠️ |

**Compliance: 0/35 agents (0%)**

### Effort to Fix

| Action | Agents Affected | Effort per Agent | Total |
|--------|----------------|------------------|-------|
| Add `owner`, `version` | 35 | 5 min | 3 hours |
| Add `llm_config` skeleton | 28 (80%) | 15 min | 7 hours |
| Add `skills_required` | 35 | 30 min | 18 hours |
| Update `actions` schema | 35 | 20 min | 12 hours |
| **TOTAL** | - | - | **40 hours (1 week)** |

---

## 🚨 PROBLEMA #2: SKILLS SYSTEM - 0% Adoption (CRITICO)

### Cosa Dovrebbe Esserci

**In manifest.json:**
```json
{
  "skills_required": [
    "security.cve-scan",
    "utilities.version-compatibility"
  ]
}
```

**In agent script:**
```powershell
# Load Skills System
. "$PSScriptRoot/../agents/skills/Load-Skills.ps1"

# Import skills
Import-Skill -SkillId "security.cve-scan"

# Use skill
$result = Invoke-CVEScan -ImageName "n8nio/n8n:1.123.20"
```

### Cosa C'è Realmente

**agent_vulnerability_scanner:**
- Script ha tutto il codice CVE scan **inline** (180 righe duplicate)
- Script ha version compatibility **inline** (150 righe duplicate)
- **ZERO uso del Skills System**

**agent_security:**
- Ha funzioni inline per Key Vault access
- **ZERO uso del Skills System**

**agent_dba:**
- Ha migration logic inline
- **ZERO uso del Skills System**

### Code Duplication Analysis

Cercando pattern comuni tra agent:

| Functionality | Duplicated Across | Lines Duplicated | Potential Skill |
|---------------|-------------------|------------------|-----------------|
| **CVE Scanning** | 3 agents | ~180 x 3 = 540 | security.cve-scan ✅ (già creato) |
| **Version Check** | 5 agents | ~150 x 5 = 750 | utilities.version-compatibility ✅ (già creato) |
| **Azure Key Vault** | 4 agents | ~100 x 4 = 400 | security.secret-vault ⏳ (da creare) |
| **Health Check** | 6 agents | ~80 x 6 = 480 | observability.health-check ⏳ |
| **Slack Notification** | 3 agents | ~60 x 3 = 180 | integration.slack-message ⏳ |
| **Retry Logic** | 8 agents | ~50 x 8 = 400 | utilities.retry-backoff ⏳ |
| **Markdown Export** | 4 agents | ~70 x 4 = 280 | utilities.convert-markdown ⏳ |
| **JSON Validation** | 5 agents | ~40 x 5 = 200 | utilities.json-validate ⏳ |

**Total Duplicate Code: ~3,230 lines** che potrebbero essere **8 skills** riutilizzabili.

### Skills Needed (Priority Order)

| Priority | Skill ID | Domain | Agents Using | Status |
|----------|----------|--------|--------------|--------|
| **P0** | security.cve-scan | security | 3 | ✅ Created |
| **P0** | utilities.version-compatibility | utilities | 5 | ✅ Created |
| **P1** | security.secret-vault | security | 4 | ⏳ To Create |
| **P1** | observability.health-check | observability | 6 | ⏳ To Create |
| **P1** | utilities.retry-backoff | utilities | 8 | ⏳ To Create |
| **P2** | integration.slack-message | integration | 3 | ⏳ To Create |
| **P2** | utilities.convert-markdown | utilities | 4 | ⏳ To Create |
| **P2** | utilities.json-validate | utilities | 5 | ⏳ To Create |

### Effort to Fix

| Action | Effort |
|--------|--------|
| Create 6 remaining skills (P1-P2) | 2 days |
| Refactor 35 agents to use skills | 5 days |
| Test integration | 2 days |
| **TOTAL** | **9 days (2 weeks)** |

---

## 🚨 PROBLEMA #3: PRIORITY.JSON - 17% Coverage (CRITICO)

### Chi Ha priority.json

Solo **6 su 35 agents** (17%):
1. agent_ado_userstory ✅
2. agent_ams ✅
3. agent_api ✅
4. agent_backend ✅
5. agent_creator ✅
6. agent_datalake ✅
7. agent_dba ✅
8. agent_security ✅

### Chi NON Ha priority.json

**29 agents** (83%) non hanno priority.json:
- agent_audit
- agent_cartographer
- agent_chronicler
- agent_developer
- agent_docs_review
- agent_docs_sync
- agent_dq_blueprint
- agent_frontend
- agent_gedi
- agent_governance
- agent_guard
- agent_infra
- agent_knowledge_curator
- agent_observability
- agent_pr_manager
- agent_release
- agent_retrieval
- agent_review
- agent_scrummaster
- agent_second_brain
- agent_synapse
- agent_template
- agent_vulnerability_scanner
- ... (e altri 6)

### Perché è un Problema

**priority.json** definisce:
- ✅ Regole di validazione per azioni
- ✅ Priorità di esecuzione
- ✅ Guardrails di sicurezza

**Esempio (agent_security):**
```json
{
  "rules": [
    {
      "id": "no-secret-in-logs",
      "description": "Non loggare mai valori segreti",
      "severity": "mandatory",
      "when": { "intentContains": ["kv-secret:set"] },
      "checklist": [
        "Non includere secretValue nei log/eventi",
        "Stampare solo secretName/vaultName"
      ]
    }
  ]
}
```

**Senza priority.json:**
- ❌ Nessuna validazione pre-action
- ❌ Nessuna regola di sicurezza
- ❌ Nessuna prioritizzazione

### Effort to Fix

| Action | Agents Affected | Effort per Agent | Total |
|--------|----------------|------------------|-------|
| Create priority.json | 29 | 30 min | 15 hours |
| Define validation rules | 29 | 20 min | 10 hours |
| **TOTAL** | - | - | **25 hours (3 days)** |

---

## 🚨 PROBLEMA #4: TEMPLATES/INTENT - 23% Coverage (CRITICO)

### Chi Ha Templates

Solo **8 su 35 agents** (23%):
1. agent_ado_userstory ✅ (3 templates)
2. agent_ams ✅
3. agent_creator ✅
4. agent_datalake ✅ (5 templates!)
5. agent_dba ✅ (5 templates!)
6. agent_synapse ✅
7. agent_template ✅ (2 templates)
8. (1 altro parziale)

### Cosa Contengono i Template (Best Example: agent_dba)

```
agents/agent_dba/templates/
├── intent.db-ddl-inventory.sample.json
├── intent.db-table-create.sample.json
├── intent.db-user-create.sample.json
├── intent.db-user-revoke.sample.json
└── intent.db-user-rotate.sample.json
```

**Esempio template:**
```json
{
  "action": "db-user:create",
  "params": {
    "username": "app_user_ro",
    "database": "portal_db",
    "permissions": ["SELECT"],
    "schema": "dbo"
  },
  "whatIf": false,
  "nonInteractive": true
}
```

### Perché è un Problema

Senza templates:
- ❌ Utenti non sanno come chiamare l'agent
- ❌ Nessuna documentazione eseguibile
- ❌ Difficile testare gli agent
- ❌ LLM non può generare intent corretti

### Effort to Fix

| Action | Agents Affected | Effort per Agent | Total |
|--------|----------------|------------------|-------|
| Create 3 intent templates per agent | 27 | 1 hour | 27 hours |
| **TOTAL** | - | - | **27 hours (3.5 days)** |

---

## 🚨 PROBLEMA #5: LLM INTEGRATION - 0% Production Use (CRITICO)

### Stato Attuale

**Agents con llm_config in manifest:**
- agent_template ✅ (template only)
- agent_creator ✅ (ma non usa LLM runtime)
- agent_ams ✅ (ma non usa LLM runtime)
- Forse 2-3 altri parziali

**Agents che EFFETTIVAMENTE usano LLM:** **0** 🔴

### Cosa Significa

**Tutti gli agent sono Level 1:**
- ❌ Nessun reasoning
- ❌ Nessuna scelta dinamica di azioni
- ❌ Nessun error recovery intelligente
- ❌ Nessun apprendimento

**Comportamento attuale:**
```powershell
switch ($Intent.action) {
    "xxx" { Do-XXX }
    "yyy" { Do-YYY }
    default { throw }
}
```

**Comportamento desiderato (Level 2):**
```powershell
$plan = Invoke-LLM -Prompt "User wants: $goal. Available actions: xxx, yyy. What should I do?"
foreach ($action in $plan.actions) {
    try {
        Execute $action
    } catch {
        $fix = Invoke-LLM "Failed: $_. How to fix?"
        Retry with $fix
    }
}
```

### Top 5 Agents da Upgradare a Level 2

| Agent | Current Use | Why Level 2 | Impact |
|-------|-------------|-------------|--------|
| **agent_vulnerability_scanner** | Security scans | Decide scan type based on risk | HIGH |
| **agent_security** | Key Vault, passwords | Choose rotation strategy | HIGH |
| **agent_dba** | DB migrations | Analyze schema and plan migration | VERY HIGH |
| **agent_docs_sync** | Documentation | Understand context and update relevant docs | MEDIUM |
| **agent_pr_manager** | Create PRs | Analyze changes and write good PR descriptions | MEDIUM |

### Effort to Upgrade to Level 2

| Action | Per Agent | Top 5 Total |
|--------|-----------|-------------|
| Add llm_config to manifest | 15 min | 1.25 hours |
| Create PROMPTS.md | 1 hour | 5 hours |
| Implement llm-client.ps1 | 2 hours | 2 hours (shared) |
| Refactor script for LLM planning | 6 hours | 30 hours |
| Test and tune prompts | 4 hours | 20 hours |
| **TOTAL per agent** | **13 hours** | **58 hours (7.5 days)** |

---

## 🟡 PROBLEMA #6: MEMORY SYSTEM - 80% Coverage (MEDIA)

### Stato Attuale

**Agents con memory/context.json:** **28 su 35** (80%)

**Contenuto tipico (TROPPO BASICO):**
```json
{
  "created": "2026-01-17T21:55:55.0730492+01:00",
  "stats": {
    "last_active": null,
    "errors": 0,
    "runs": 0
  },
  "preferences": {},
  "first_run": true
}
```

### Cosa DOVREBBE Contenere (Framework 2.0)

```json
{
  "created": "2026-02-08T10:00:00Z",
  "stats": {
    "total_runs": 127,
    "successful": 122,
    "errors": 5,
    "last_run": "2026-02-08T09:30:00Z",
    "avg_duration_seconds": 45.3,
    "success_rate": 96.06
  },
  "knowledge": {
    "known_good_versions": {
      "n8n": "1.123.20",
      "postgres": "15.10"
    },
    "known_issues": [
      {
        "component": "traefik",
        "issue": "Docker API incompatible",
        "resolution": "Use Caddy",
        "learned_date": "2026-02-07"
      }
    ],
    "successful_fixes": [
      {
        "problem": "CVE scan timeout",
        "solution": "Increase timeout to 300s",
        "applied": 12
      }
    ]
  },
  "preferences": {
    "notification_threshold": "high",
    "auto_fix_enabled": false,
    "scan_schedule": "0 6 * * *"
  },
  "last_errors": [
    {
      "timestamp": "2026-02-07T14:23:00Z",
      "action": "vuln-scan:full",
      "error": "Docker Scout timeout",
      "resolution": "Switched to Snyk scanner"
    }
  ]
}
```

### Gap

**Current memory è:**
- ✅ 80% coverage (buono)
- ❌ Quasi sempre vuoto o minimal
- ❌ Non traccia `knowledge`
- ❌ Non traccia `successful_fixes`
- ❌ Non impara dagli errori

### Effort to Fix

| Action | Agents Affected | Effort per Agent | Total |
|--------|----------------|------------------|-------|
| Enhance memory schema | 28 | 30 min | 14 hours |
| Update scripts to populate knowledge | 28 | 2 hours | 56 hours |
| **TOTAL** | - | - | **70 hours (9 days)** |

---

## 📊 SUMMARY: Distanza Totale dagli Standard

### Compliance Matrix

| Standard | Current | Gap | Effort to Close | Priority |
|----------|---------|-----|-----------------|----------|
| **Manifest Schema v2.0** | 0% | -100% | 40 hours | 🔴 P0 |
| **Skills System** | 0% | -100% | 72 hours (9 days) | 🔴 P0 |
| **Priority.json** | 17% | -83% | 25 hours | 🔴 P1 |
| **Intent Templates** | 23% | -77% | 27 hours | 🔴 P1 |
| **LLM Integration (Level 2)** | 0% | -100% | 58 hours (top 5) | 🟠 P2 |
| **Memory Enhancement** | 80% → 20% real | -60% | 70 hours | 🟡 P3 |
| **README Documentation** | 86% | -14% | 10 hours | 🟢 P4 |

### Total Effort to Compliance

| Phase | Work | Duration | Priority |
|-------|------|----------|----------|
| **Phase 0: Critical Fixes** | Manifest schema + Skills adoption | 112 hours (14 days) | 🔴 CRITICAL |
| **Phase 1: Completeness** | Priority.json + Templates | 52 hours (6.5 days) | 🔴 HIGH |
| **Phase 2: Intelligence** | LLM Level 2 (top 5) | 58 hours (7.5 days) | 🟠 MEDIUM |
| **Phase 3: Learning** | Memory enhancement | 70 hours (9 days) | 🟡 LOW |
| **TOTAL TO FULL COMPLIANCE** | - | **292 hours (~37 days / 7.5 weeks)** | - |

**Con 1 developer full-time: ~2 mesi**
**Con team di 2: ~1 mese**
**Con automated tooling (agent_audit): ~2 settimane** ⚡

---

## 🎯 RACCOMANDAZIONI PRIORITARIE

### Quick Wins (1 settimana)

1. **Standardize Manifests** (40 hours)
   - Script automatico che aggiunge campi mancanti
   - Validazione con manifest.schema.json
   - **ROI: ALTO** - Tutti gli agent diventano validabili

2. **Create Top 8 Skills** (16 hours)
   - security.secret-vault
   - observability.health-check
   - utilities.retry-backoff
   - integration.slack-message
   - utilities.convert-markdown
   - utilities.json-validate
   - database.test-connection
   - database.migration
   - **ROI: ALTISSIMO** - Elimina 3,230 righe duplicate

### Medium Term (1 mese)

3. **Refactor All Agents to Use Skills** (72 hours)
   - Automated refactoring tool
   - Test suite per verificare comportamento identico
   - **ROI: ALTO** - Codebase -60% più piccolo

4. **Add Priority.json + Templates** (52 hours)
   - Script generator per priority.json
   - Template generator basato su actions
   - **ROI: MEDIO** - Migliora usability

### Long Term (2-3 mesi)

5. **Upgrade Top 5 to Level 2** (58 hours)
   - agent_vulnerability_scanner
   - agent_security
   - agent_dba
   - agent_docs_sync
   - agent_pr_manager
   - **ROI: ALTISSIMO** - Agent diventano intelligenti

6. **Enhance Memory System** (70 hours)
   - Memory enrichment script
   - Learning loop implementation
   - **ROI: MEDIO** - Agent imparano nel tempo

---

## 🚀 AUTOMATED FIX STRATEGY

### Cosa Può Fare agent_audit con Ollama

**Automated (90% confidence):**
1. ✅ Add missing manifest fields (owner, version)
2. ✅ Add llm_config skeleton
3. ✅ Add skills_required based on code analysis
4. ✅ Create priority.json template
5. ✅ Create intent templates from actions
6. ✅ Enhance memory/context.json schema
7. ✅ Move agents to correct locations
8. ✅ Validate against schema

**Semi-Automated (60% confidence, need review):**
1. ⚠️ Refactor inline code to skills
2. ⚠️ Add PROMPTS.md for LLM
3. ⚠️ Implement smart execution logic

**Manual (0% confidence, human required):**
1. ❌ Define LLM prompts quality
2. ❌ Test LLM reasoning correctness
3. ❌ Tune temperature and parameters

### Recommended Approach

**Week 1: Automated Fixes (agent_audit)**
- Fix manifests for all 35 agents
- Add priority.json skeletons
- Create intent templates
- Validate against schema
- **Output: 90% structural compliance**

**Week 2: Skills Migration (agent_audit + human review)**
- Create 8 core skills
- Identify duplicate code patterns
- Generate refactoring plan
- Human reviews and approves
- **Output: Skills system ready**

**Week 3-4: Skills Adoption (human-led)**
- Refactor agents to use skills
- Test thoroughly
- Deploy incrementally
- **Output: -60% code duplication**

**Month 2: Level 2 Upgrade (human-led)**
- Top 5 agents get LLM reasoning
- Test and tune prompts
- Deploy to production
- **Output: 5 intelligent agents**

---

## 💡 FINAL VERDICT

### Quanto siamo lontani?

**Distanza dagli standard: 77/100 points** 🔴

**Breakdown:**
- Structure (manifest, files): **23/100** 🔴
- Code Quality (skills, no duplication): **0/100** 🔴
- Intelligence (LLM reasoning): **0/100** 🔴
- Memory/Learning: **20/100** 🔴
- Documentation: **86/100** ✅

### Cosa NON va (Top 3)

1. **🔴 ZERO Skills System adoption** → 3,230 righe duplicate
2. **🔴 ZERO LLM integration** → Tutti gli agent sono "stupidi"
3. **🔴 Manifest chaos** → Ogni agent ha formato diverso

### La Buona Notizia

✅ **Documentation è ottima** (86%)
✅ **Memory system structure esiste** (80%)
✅ **README quality è alta** (30/35 agents)
✅ **Framework 2.0 è pronto** (tutto documentato)
✅ **agent_audit può automatizzare 70% del lavoro**

---

**Prossimo Step:** Configurare agent_audit con Ollama e partire con automated fixes?

---

**Status:** 📊 Gap Analysis Complete
**Owner:** EasyWay Platform Team
**Date:** 2026-02-08
