# Agent Issue Tracking & Kanban System

## Overview

Sistema di tracciamento issue per agenti con board Kanban e governance automatica.

**Quando un agente incontra un problema**, registra un issue che finisce in una Kanban board dove `agent_governance` propone miglioramenti.

---

## Architecture

```
Agent encounters issue
    ↓
issue-logger.ps1
    ↓
agents/logs/issues.jsonl (append)
    ↓
agents/logs/kanban.json (update backlog)
    ↓
[if critical/high] → Notify agent_governance
    ↓
agent_governance reviews
    ↓
kanban-manager.ps1 (propose-fix)
    ↓
Human reviews & approves
    ↓
Issue resolved
```

---

## Components

### 1. Issue Log Schema

**File**: `agents/core/schemas/issue-log.schema.json`

**Fields**:
- `id`: ISSUE-YYYYMMDD-XXX
- `timestamp`: ISO 8601
- `agent`: Agent name
- `severity`: critical | high | medium | low
- `category`: execution_failed, validation_error, etc.
- `description`: Human-readable
- `context`: Additional details
- `suggested_fix`: Agent's suggestion
- `status`: open | in_review | planned | in_progress | resolved
- `assigned_to`: Default: agent_governance

---

### 2. Issue Logger Script

**File**: `scripts/pwsh/issue-logger.ps1`

**Usage**:

```powershell
# Agent encounters issue
pwsh scripts/pwsh/issue-logger.ps1 `
  -Agent "agent_dba" `
  -Severity "high" `
  -Category "missing_dependency" `
  -Description "db/migrations/ directory not found" `
  -UserInput "create migration for users table" `
  -Intent "db:migration.create" `
  -ActionAttempted "create_migration_file" `
  -ErrorMessage "Directory not found: db/migrations/" `
  -SuggestedFix "Create db/migrations/ directory with README"
```

**Output**:
- Appends to `agents/logs/issues.jsonl`
- Updates `agents/logs/kanban.json` (backlog)
- If critical/high: Notifies agent_governance

---

### 3. Kanban Manager Script

**File**: `scripts/pwsh/kanban-manager.ps1`

**Actions**:

#### View Kanban

```powershell
# Console view
pwsh scripts/pwsh/kanban-manager.ps1 -Action view

# Markdown export
pwsh scripts/pwsh/kanban-manager.ps1 -Action view -Format markdown
```

**Output**:
```
=== AGENT ISSUE KANBAN ===

[backlog] (3)
  🔴 ISSUE-20260118-001 - agent_dba - db/migrations/ directory not found...
  🟠 ISSUE-20260118-002 - agent_frontend - Build failed: missing dependencies...
  🟡 ISSUE-20260118-003 - agent_api - OpenAPI validation warning...

[in_review] (1)
  🟠 ISSUE-20260117-005 - agent_backend - Connection timeout to SQL Server...

[planned] (2)
  ...

[in_progress] (1)
  ...

[resolved] (15)
  ...
```

#### Move Issue

```powershell
# Move to in_review (agent_governance starts review)
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action move `
  -IssueId ISSUE-20260118-001 `
  -Column in_review
```

#### Propose Fix (agent_governance)

```powershell
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action propose-fix `
  -IssueId ISSUE-20260118-001 `
  -ProposedFix "Add pre-check in agent_dba manifest:
{
  'pre_checks': [
    {
      'check': 'directory_exists',
      'path': 'db/migrations/',
      'on_fail': 'create_directory_with_readme'
    }
  ]
}
Implement auto-fix in agent-dba.ps1 to create directory if missing."
```

#### Export Report

```powershell
pwsh scripts/pwsh/kanban-manager.ps1 -Action export
```

**Output**: `out/issues-report.md`

---

## Workflow Example

### Scenario: agent_dba encounters missing directory

**Step 1: Agent logs issue**

```powershell
# In agent-dba.ps1
if (-not (Test-Path "db/migrations/")) {
    pwsh scripts/pwsh/issue-logger.ps1 `
      -Agent "agent_dba" `
      -Severity "high" `
      -Category "missing_dependency" `
      -Description "db/migrations/ directory not found" `
      -UserInput $userInput `
      -Intent "db:migration.create" `
      -ActionAttempted "create_migration_file" `
      -ErrorMessage "Directory not found: db/migrations/" `
      -SuggestedFix "Create db/migrations/ directory with README"
    
    Write-Error "Cannot create migration: db/migrations/ not found"
    exit 1
}
```

**Step 2: Issue appears in Kanban backlog**

```json
// agents/logs/kanban.json
{
  "columns": {
    "backlog": [
      {
        "issue_id": "ISSUE-20260118-001",
        "agent": "agent_dba",
        "severity": "high",
        "category": "missing_dependency",
        "description": "db/migrations/ directory not found",
        "added_at": "2026-01-18T20:05:00Z"
      }
    ]
  }
}
```

**Step 3: agent_governance receives notification**

```jsonl
// agents/agent_governance/notifications.jsonl
{"timestamp":"2026-01-18T20:05:00Z","type":"high_priority_issue","issue_id":"ISSUE-20260118-001","agent":"agent_dba","severity":"high","description":"db/migrations/ directory not found","action_required":"Review and propose improvement"}
```

**Step 4: agent_governance reviews**

```powershell
# agent_governance reviews issue
pwsh scripts/pwsh/kanban-manager.ps1 -Action view

# Moves to in_review
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action move `
  -IssueId ISSUE-20260118-001 `
  -Column in_review
```

**Step 5: agent_governance proposes fix**

```powershell
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action propose-fix `
  -IssueId ISSUE-20260118-001 `
  -ProposedFix "
## Proposed Solution

### 1. Add Pre-Check to Manifest

Update agents/agent_dba/manifest.json:

\`\`\`json
{
  \"actions\": [
    {
      \"name\": \"dba:migration.create\",
      \"pre_checks\": [
        {
          \"check\": \"directory_exists\",
          \"path\": \"db/migrations/\",
          \"on_fail\": \"auto_create_with_readme\"
        }
      ]
    }
  ]
}
\`\`\`

### 2. Implement Auto-Fix

Add to scripts/agent-dba.ps1:

\`\`\`powershell
if (-not (Test-Path 'db/migrations/')) {
    New-Item -ItemType Directory -Path 'db/migrations/' -Force
    @'
# Database Migrations

See: Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/db-migrations.md
'@ | Set-Content 'db/migrations/README.md'
    
    Write-Host '✅ Created db/migrations/ directory'
}
\`\`\`

### 3. Update Documentation

Add to db-migrations.md:
- Note that directory is auto-created if missing
- Link to issue ISSUE-20260118-001

### Impact
- Prevents future occurrences
- Improves user experience (auto-fix)
- Reduces support burden
"
```

**Step 6: Human reviews & approves**

```powershell
# Human reviews proposed fix
cat agents/logs/issues.jsonl | Select-String "ISSUE-20260118-001"

# Approves and moves to planned
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action move `
  -IssueId ISSUE-20260118-001 `
  -Column planned
```

**Step 7: Implementation**

```powershell
# Developer implements fix
# ... (code changes)

# Moves to in_progress
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action move `
  -IssueId ISSUE-20260118-001 `
  -Column in_progress
```

**Step 8: Resolution**

```powershell
# After implementation and testing
pwsh scripts/pwsh/kanban-manager.ps1 `
  -Action move `
  -IssueId ISSUE-20260118-001 `
  -Column resolved
```

---

## Integration with Agents

### In Agent Scripts

```powershell
# Example: agent-dba.ps1

try {
    # Attempt action
    $result = Invoke-DatabaseMigration -Name $migrationName
} catch {
    # Log issue
    $issueId = pwsh scripts/pwsh/issue-logger.ps1 `
      -Agent "agent_dba" `
      -Severity "high" `
      -Category "execution_failed" `
      -Description "Migration creation failed: $($_.Exception.Message)" `
      -UserInput $userInput `
      -Intent $intent `
      -ActionAttempted "create_migration" `
      -ErrorMessage $_.Exception.Message `
      -SuggestedFix "Check database connection and permissions"
    
    Write-Error "Migration failed. Issue logged: $issueId"
    exit 1
}
```

### In Agent Manifest

```json
{
  "actions": [
    {
      "name": "dba:migration.create",
      "script": "../../scripts/agent-dba.ps1",
      "error_handling": {
        "log_issues": true,
        "severity_mapping": {
          "critical": ["database_unavailable", "data_loss_risk"],
          "high": ["execution_failed", "validation_error"],
          "medium": ["warning", "deprecation"],
          "low": ["info"]
        }
      }
    }
  ]
}
```

---

## agent_governance Actions

### New Action: Review Issues

```json
// agents/agent_governance/manifest.json
{
  "actions": [
    {
      "name": "governance:issues.review",
      "description": "Review open issues and propose improvements",
      "script": "../../scripts/agent-governance.ps1",
      "params": {
        "Action": "review-issues"
      },
      "schedule": "daily"  // Run daily
    },
    {
      "name": "governance:improvement.propose",
      "description": "Propose improvement for specific issue",
      "script": "../../scripts/agent-governance.ps1",
      "params": {
        "Action": "propose-improvement"
      }
    }
  ]
}
```

### Script: agent-governance.ps1

```powershell
# scripts/agent-governance.ps1

param(
    [ValidateSet('review-issues', 'propose-improvement')]
    [string]$Action,
    
    [string]$IssueId
)

switch ($Action) {
    'review-issues' {
        # Get all open issues
        $issues = Get-Content agents/logs/issues.jsonl | 
                  ConvertFrom-Json | 
                  Where-Object { $_.status -eq 'open' }
        
        Write-Host "Found $($issues.Count) open issues"
        
        # Prioritize by severity
        $critical = $issues | Where-Object { $_.severity -eq 'critical' }
        $high = $issues | Where-Object { $_.severity -eq 'high' }
        
        # Review critical first
        foreach ($issue in $critical) {
            Write-Host "🔴 CRITICAL: $($issue.id) - $($issue.description)"
            
            # Move to in_review
            pwsh scripts/pwsh/kanban-manager.ps1 `
              -Action move `
              -IssueId $issue.id `
              -Column in_review
        }
        
        # Then high
        foreach ($issue in $high) {
            Write-Host "🟠 HIGH: $($issue.id) - $($issue.description)"
            
            # Analyze and propose fix
            & $PSScriptRoot/agent-governance.ps1 `
              -Action propose-improvement `
              -IssueId $issue.id
        }
    }
    
    'propose-improvement' {
        $issue = Get-Content agents/logs/issues.jsonl | 
                 ConvertFrom-Json | 
                 Where-Object { $_.id -eq $IssueId }
        
        if (-not $issue) {
            Write-Error "Issue $IssueId not found"
            exit 1
        }
        
        # Analyze issue and generate proposal
        $proposal = Generate-ImprovementProposal -Issue $issue
        
        # Add to kanban
        pwsh scripts/pwsh/kanban-manager.ps1 `
          -Action propose-fix `
          -IssueId $IssueId `
          -ProposedFix $proposal
        
        Write-Host "✅ Improvement proposed for $IssueId"
    }
}
```

---

## Metrics & Reporting

### Daily Report

```powershell
# Generate daily issue report
pwsh scripts/pwsh/kanban-manager.ps1 -Action export

# Output: out/issues-report.md
```

**Report includes**:
- Total issues
- Open issues
- Critical issues
- Issues by severity
- Issues by agent
- Recent issues (last 10)
- Top categories

### Dashboard

```powershell
# View kanban in console
pwsh scripts/pwsh/kanban-manager.ps1 -Action view

# Export to markdown
pwsh scripts/pwsh/kanban-manager.ps1 -Action view -Format markdown
```

---

## Benefits

1. **Tracciabilità**: Ogni problema è loggato e tracciabile
2. **Governance**: agent_governance propone miglioramenti automaticamente
3. **Prioritizzazione**: Kanban board visualizza priorità
4. **Continuous Improvement**: Pattern di errori → miglioramenti sistemici
5. **Audit Trail**: Storico completo di issue e risoluzioni
6. **Metrics**: Report per identificare agenti/categorie problematiche

---

## Next Steps

1. **Integrate in existing agents** - Add issue logging to error handlers
2. **Schedule agent_governance** - Daily review of open issues
3. **CI Integration** - Fail build if critical issues > threshold
4. **Notifications** - Slack/Teams integration for critical issues
5. **ML Analysis** - Identify patterns in issues for proactive fixes

---

**Created**: 2026-01-18  
**Version**: 1.0  
**Status**: Ready for implementation
