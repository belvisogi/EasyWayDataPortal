# 🚀 Agent Evolution Guide - From Scripts to Autonomous Agents

**Version:** 1.0.0
**Created:** 2026-02-08
**Purpose:** Roadmap for upgrading agents from Level 1 (Script Runners) to Level 4 (Claude-like)

---

## 📊 Evolution Levels Overview

| Level | Name | Capabilities | Effort | Example Agent |
|-------|------|--------------|--------|---------------|
| **Level 1** ⭐ | Script Runners | Intent → Action (deterministic) | Current | Most agents today |
| **Level 2** ⭐⭐ | Smart Executors | LLM chooses actions, retry logic | 1 week | agent_vulnerability_scanner (target) |
| **Level 3** ⭐⭐⭐ | Autonomous Agents | Multi-turn, self-correction, memory | 2 weeks | agent_creator (future) |
| **Level 4** ⭐⭐⭐⭐ | Claude-like | Inter-agent collaboration, learning, code gen | 1 month | (research phase) |

---

## Level 1: Script Runners ⭐ (Current State)

### Characteristics
- **Static mapping:** Intent JSON → Predefined action
- **Deterministic:** Same input = same output
- **No reasoning:** Executes without thinking
- **Single-shot:** No retry or error handling

### Example
```powershell
# agent-xxx.ps1
function Invoke-Action {
    param($Intent)

    switch ($Intent.action) {
        "vuln-scan" { Invoke-VulnScan }
        "eol-check" { Check-EOL }
        default { throw "Unknown action" }
    }
}
```

### Upgrade Path to Level 2
1. Add `llm_config` to manifest.json
2. Implement LLM-based action selection
3. Add retry logic with error analysis

---

## Level 2: Smart Executors ⭐⭐

### New Capabilities
- ✅ **LLM reasoning:** Chooses which actions to run
- ✅ **Error analysis:** Understands why something failed
- ✅ **Retry logic:** Tries different approaches
- ✅ **Dynamic parameters:** LLM adjusts params based on context

### Implementation

**File:** `agents/agent_xxx/manifest.json`
```json
{
  "llm_config": {
    "model": "gpt-4-turbo",
    "temperature": 0.0,
    "system_prompt": "agents/agent_xxx/PROMPTS.md"
  },
  "actions": [
    { "name": "vuln-scan:full" },
    { "name": "vuln-scan:quick" },
    { "name": "vuln-scan:compatibility-only" }
  ]
}
```

**File:** `scripts/pwsh/agent-xxx.ps1`
```powershell
function Invoke-SmartAction {
    param($Intent)

    # LLM decides which actions to run
    $plan = Invoke-LLM -Prompt @"
User request: $($Intent.goal)

Available actions:
1. vuln-scan:full (comprehensive, 5-10 min)
2. vuln-scan:quick (fast, 30 sec)
3. vuln-scan:compatibility-only (version check, 10 sec)

Which actions should I run? In what order? Return JSON array.
"@

    $actions = $plan | ConvertFrom-Json

    foreach ($action in $actions) {
        try {
            Invoke-Action -Name $action.name -Params $action.params
        } catch {
            # LLM analyzes error and suggests retry
            $fix = Invoke-LLM -Prompt "Action $($action.name) failed: $_. How should I fix this?"
            # Retry with fix
        }
    }
}
```

### Upgrade Path to Level 3
1. Add memory/context.json persistence
2. Implement multi-turn conversation
3. Add self-correction loop

---

## Level 3: Autonomous Agents ⭐⭐⭐

### New Capabilities
- ✅ **Multi-turn conversation:** Agent plans, executes, reflects
- ✅ **Self-correction:** Detects mistakes and fixes them
- ✅ **Memory persistence:** Learns from past executions
- ✅ **Proactive exploration:** Discovers information before acting

### Implementation

**Memory System:**
```json
// agents/agent_xxx/memory/context.json
{
  "stats": {
    "total_runs": 45,
    "errors": 2,
    "success_rate": 95.6
  },
  "knowledge": {
    "known_good_versions": { "n8n": "1.123.20" },
    "known_issues": [
      {
        "component": "traefik",
        "issue": "Docker API incompatible",
        "resolution": "Use Caddy instead",
        "learned_date": "2026-02-07"
      }
    ]
  },
  "preferences": {
    "notification_threshold": "high",
    "auto_fix": false
  }
}
```

**Multi-Turn Execution:**
```powershell
function Start-AutonomousExecution {
    param($Goal)

    $context = Get-AgentMemory -AgentId "agent_xxx"
    $conversation = @()

    $conversation += @{
        role = "system"
        content = "You are agent_xxx. Goal: $Goal. Memory: $($context | ConvertTo-Json)"
    }

    $maxTurns = 10
    for ($turn = 0; $turn -lt $maxTurns; $turn++) {
        $response = Invoke-LLM -Messages $conversation

        $toolCalls = Parse-ToolCalls -Response $response

        if ($toolCalls.Count -eq 0) {
            # Agent finished
            break
        }

        foreach ($tool in $toolCalls) {
            $result = Invoke-Tool -Name $tool.name -Params $tool.params
            $conversation += @{
                role = "tool"
                name = $tool.name
                content = ($result | ConvertTo-Json)
            }
        }
    }

    # Update memory
    Update-AgentMemory -AgentId "agent_xxx" -NewKnowledge $conversation
}
```

### Upgrade Path to Level 4
1. Implement inter-agent communication
2. Add dynamic skill learning
3. Build hierarchical task decomposition

---

## Level 4: Claude-like ⭐⭐⭐⭐ (Research)

### Vision
- ✅ **Inter-agent collaboration:** Agents work together like a team
- ✅ **Learning from feedback:** Improves based on user corrections
- ✅ **Code generation:** Creates new tools when needed
- ✅ **Hierarchical planning:** Breaks complex tasks into sub-tasks

### Example Scenario
```
User: "Audit security and fix critical issues"

Agent (autonomous):
1. [Planning] Breaks into:
   - Run vuln scan (agent_vulnerability_scanner)
   - Check passwords (agent_security)
   - Review network (agent_infra)

2. [Discovery] Realizes needs port scanner:
   - Generates PowerShell script
   - Tests it
   - Adds to skill registry

3. [Execution] Calls other agents in parallel

4. [Analysis] Finds 3 CRITICAL issues

5. [Remediation] Asks user permission to fix

6. [Implementation] Calls:
   - agent_security (rotate passwords)
   - agent_dba (enable RLS)
   - agent_infra (update firewall)

7. [Verification] Re-runs scan, confirms fixes

8. [Documentation] Updates Wiki automatically
```

---

## 📈 Recommended Upgrade Path

### Phase 1: Foundation (Week 1-2)
- ✅ Implement Skills System for all agents
- ✅ Add manifest.schema.json validation
- ✅ Update agent_template to Level 2
- ✅ Create PROMPTS.md for each agent

### Phase 2: Smart Executors (Week 3-4)
- Upgrade top 5 agents to Level 2:
  1. agent_vulnerability_scanner
  2. agent_security
  3. agent_dba
  4. agent_docs_sync
  5. agent_pr_manager

### Phase 3: Autonomy (Month 2)
- Implement memory system across all agents
- Add multi-turn conversation for core agents
- Build inter-agent communication (n8n orchestration)

### Phase 4: Research (Month 3+)
- Experiment with hierarchical planning
- Test dynamic skill learning
- Pilot inter-agent collaboration

---

## 🎯 Success Metrics

| Metric | Level 1 | Level 2 | Level 3 | Level 4 |
|--------|---------|---------|---------|---------|
| Success Rate | 70% | 85% | 95% | 98% |
| User Intervention | High | Medium | Low | Minimal |
| Time to Complete | Baseline | -20% | -50% | -70% |
| Error Recovery | Manual | Retry | Auto-fix | Preventive |

---

## 📚 References

- [SKILLS_SYSTEM.md](./SKILLS_SYSTEM.md) - Modular skills framework
- [LLM_INTEGRATION_PATTERN.md](./LLM_INTEGRATION_PATTERN.md) - Add LLM reasoning
- [AGENT_WORKFLOW_STANDARD.md](./AGENT_WORKFLOW_STANDARD.md) - Agent standards

---

**Status:** 🚧 Roadmap Document
**Owner:** EasyWay Platform Team
**Last Updated:** 2026-02-08
