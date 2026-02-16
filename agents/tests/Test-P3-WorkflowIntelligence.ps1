<#
.SYNOPSIS
    Pester v3 tests for Phase 3 — Workflow Intelligence.

.DESCRIPTION
    Validates decision profiles, COSTAR skill prompts (DryRun), and n8n schema.

.EXAMPLE
    Invoke-Pester -Script agents/tests/Test-P3-WorkflowIntelligence.ps1
#>

$repoRoot = Resolve-Path "$PSScriptRoot/../.."
$agentsRoot = "$PSScriptRoot/.."

# ═══════════════════════════════════════════
# 1. DECISION PROFILE TESTS
# ═══════════════════════════════════════════
Describe "Decision Profiles" {

    $profilesDir = "$agentsRoot/config/decision-profiles"

    Context "Schema compliance" {

        It "Profiles directory exists" {
            Test-Path $profilesDir | Should Be $true
        }

        It "At least 3 starter profiles exist" {
            $files = Get-ChildItem -Path $profilesDir -Filter "*.json"
            $files.Count | Should BeGreaterThan 2
        }

        It "conservative.json is valid JSON with required fields" {
            $p = Get-Content "$profilesDir/conservative.json" -Raw | ConvertFrom-Json
            $p.name       | Should Not BeNullOrEmpty
            $p.risk_level | Should Be "conservative"
        }

        It "moderate.json is valid JSON with required fields" {
            $p = Get-Content "$profilesDir/moderate.json" -Raw | ConvertFrom-Json
            $p.name       | Should Not BeNullOrEmpty
            $p.risk_level | Should Be "moderate"
        }

        It "aggressive.json is valid JSON with required fields" {
            $p = Get-Content "$profilesDir/aggressive.json" -Raw | ConvertFrom-Json
            $p.name       | Should Not BeNullOrEmpty
            $p.risk_level | Should Be "aggressive"
        }
    }

    Context "Profile values" {
        It "Conservative has zero threshold" {
            $c = Get-Content "$profilesDir/conservative.json" -Raw | ConvertFrom-Json
            $c.auto_approve_threshold_usd | Should Be 0
        }

        It "Moderate has threshold of 100" {
            $m = Get-Content "$profilesDir/moderate.json" -Raw | ConvertFrom-Json
            $m.auto_approve_threshold_usd | Should Be 100
        }

        It "Aggressive allows delete without approval" {
            $a = Get-Content "$profilesDir/aggressive.json" -Raw | ConvertFrom-Json
            $a.allowed_actions_without_approval -contains "delete" | Should Be $true
        }
    }
}

# ═══════════════════════════════════════════
# 2. COSTAR SKILL TESTS (DryRun mode)
# ═══════════════════════════════════════════

. "$agentsRoot/skills/analysis/Invoke-Summarize.ps1"
. "$agentsRoot/skills/analysis/Invoke-SQLQuery.ps1"
. "$agentsRoot/skills/analysis/Invoke-ClassifyIntent.ps1"

Describe "COSTAR Skill: Invoke-Summarize" {

    It "DryRun returns prompt with all COSTAR sections" {
        $result = Invoke-Summarize -InputText "Test document content" -DryRun
        $result.DryRun  | Should Be $true
        $result.SkillId | Should Be "analysis.summarize"
        $result.Prompt  | Should Match "CONTEXT"
        $result.Prompt  | Should Match "OBJECTIVE"
        $result.Prompt  | Should Match "STYLE"
        $result.Prompt  | Should Match "TONE"
        $result.Prompt  | Should Match "AUDIENCE"
        $result.Prompt  | Should Match "RESPONSE"
    }

    It "DryRun prompt contains the input text" {
        $result = Invoke-Summarize -InputText "Hello world test" -DryRun
        $result.Prompt | Should Match "Hello world test"
    }

    It "DryRun respects MaxWords parameter" {
        $result = Invoke-Summarize -InputText "Test" -MaxWords 300 -DryRun
        $result.Prompt | Should Match "300 words"
    }
}

Describe "COSTAR Skill: Invoke-SQLQuery" {

    It "DryRun returns prompt with COSTAR sections" {
        $result = Invoke-SQLQuery -Question "How many users?" -DryRun
        $result.DryRun  | Should Be $true
        $result.SkillId | Should Be "analysis.sql-query"
        $result.Prompt  | Should Match "CONTEXT"
        $result.Prompt  | Should Match "OBJECTIVE"
        $result.Prompt  | Should Match "READ-ONLY"
    }

    It "DryRun includes schema context when provided" {
        $result = Invoke-SQLQuery -Question "Count rows" -SchemaContext "CREATE TABLE users (id INT)" -DryRun
        $result.Prompt | Should Match "CREATE TABLE users"
    }
}

Describe "COSTAR Skill: Invoke-ClassifyIntent" {

    It "DryRun returns structured prompt" {
        $result = Invoke-ClassifyIntent -UserInput "Delete the staging DB" -DryRun
        $result.DryRun  | Should Be $true
        $result.SkillId | Should Be "analysis.classify-intent"
        $result.Prompt  | Should Match "Delete the staging DB"
        $result.Prompt  | Should Match "CONTEXT"
    }

    It "DryRun includes custom intent list" {
        $result = Invoke-ClassifyIntent -UserInput "Test" -IntentList @("alpha", "beta") -DryRun
        $result.Prompt | Should Match "alpha"
        $result.Prompt | Should Match "beta"
    }
}

# ═══════════════════════════════════════════
# 3. COSTAR REGISTRY TESTS
# ═══════════════════════════════════════════
Describe "Skills Registry — COSTAR entries" {

    $registry = Get-Content "$agentsRoot/skills/registry.json" -Raw | ConvertFrom-Json

    It "Registry contains analysis.summarize with costar_prompt" {
        $skill = $registry.skills | Where-Object { $_.id -eq "analysis.summarize" }
        $skill | Should Not BeNullOrEmpty
        $skill.costar_prompt | Should Not BeNullOrEmpty
    }

    It "Registry contains analysis.sql-query with costar_prompt" {
        $skill = $registry.skills | Where-Object { $_.id -eq "analysis.sql-query" }
        $skill | Should Not BeNullOrEmpty
        $skill.costar_prompt.response_format | Should Match "JSON"
    }

    It "Registry contains analysis.classify-intent" {
        $skill = $registry.skills | Where-Object { $_.id -eq "analysis.classify-intent" }
        $skill | Should Not BeNullOrEmpty
    }
}

# ═══════════════════════════════════════════
# 4. N8N INTEGRATION TESTS
# ═══════════════════════════════════════════
Describe "n8n Agent Node" {

    It "n8n-agent-node.schema.json exists and is valid JSON" {
        $schemaPath = "$agentsRoot/core/schemas/n8n-agent-node.schema.json"
        Test-Path $schemaPath | Should Be $true
        { Get-Content $schemaPath -Raw | ConvertFrom-Json } | Should Not Throw
    }

    It "Schema requires agentId, action, prompt" {
        $schema = Get-Content "$agentsRoot/core/schemas/n8n-agent-node.schema.json" -Raw | ConvertFrom-Json
        $schema.required -contains "agentId" | Should Be $true
        $schema.required -contains "action"  | Should Be $true
        $schema.required -contains "prompt"  | Should Be $true
    }

    It "agent-composition-example.json is valid n8n workflow" {
        $wfPath = "$agentsRoot/core/n8n/Templates/agent-composition-example.json"
        Test-Path $wfPath | Should Be $true
        $wf = Get-Content $wfPath -Raw | ConvertFrom-Json
        $wf.nodes.Count | Should BeGreaterThan 2
        $wf.connections   | Should Not BeNullOrEmpty
    }
}
