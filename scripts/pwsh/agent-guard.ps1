<#
.SYNOPSIS
    Agent Guard - The CI/CD Sentry 👮
    Enforces policies defined in policies.json on git context.

.DESCRIPTION
    Validates Branch Names, Target Branches, and Commit Messages against
    regex patterns defined in the external policy file.
    Acts as a "Gatekeeper" in the pipeline.

.PARAMETER ContextId
    The ID of the workflow context (e.g., PR-123)
.PARAMETER SourceBranch
    The branch being merged.
.PARAMETER TargetBranch
    The destination branch.
.PARAMETER CommitMessage
    (Optional) The commit message to validate.
.PARAMETER PolicyFile
    Path to the JSON policy file. Defaults to adjacent policies.json.

.EXAMPLE
    .\agent-guard.ps1 -SourceBranch "feature/devops/PBI-001-ui" -TargetBranch "develop"
#>

[CmdletBinding()]
param(
    [string]$ContextId = "LOCAL-TEST",
    [Parameter(Mandatory = $true)][string]$SourceBranch,
    [Parameter(Mandatory = $true)][string]$TargetBranch,
    [string]$CommitMessage,
    [string]$PolicyFile = "$PSScriptRoot/../../agents/agent_guard/policies.json"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) { "INFO" { "Cyan" } "WARN" { "Yellow" } "ERROR" { "Red" } "SUCCESS" { "Green" } }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

Write-Log "👮 Agent Guard Initialized (Context: $ContextId)"

# 1. Load Policy
if (-not (Test-Path $PolicyFile)) {
    Write-Log "Policy file not found at $PolicyFile" "ERROR"
    exit 1
}
$policy = Get-Content $PolicyFile -Raw | ConvertFrom-Json
Write-Log "Loaded Policy v$($policy.version)"

$errors = @()

# 2. Check Branch Naming
if ($policy.rules.branch_naming.enabled) {
    $valid = $false
    foreach ($pattern in $policy.rules.branch_naming.patterns) {
        if ($SourceBranch -match $pattern) {
            $valid = $true
            break
        }
    }
    if (-not $valid) {
        $errors += "❌ Branch Naming Violation: '$SourceBranch' does not match allowed patterns."
        $errors += "   Hint: $($policy.rules.branch_naming.error_message)"
    }
    else {
        Write-Log "✅ Branch Name OK: $SourceBranch" "SUCCESS"
    }
}

# 3. Check Target Policy
if ($policy.rules.target_branch_policy.enabled) {
    $allowed = $false
    # Logic: Default deny. Must match a specific allow rule.
    foreach ($rule in $policy.rules.target_branch_policy.rules) {
        # Simple wildcard matching for policy rules
        $fromPattern = "^" + $rule.from.Replace("*", ".*") + "$"
        $toPattern = "^" + $rule.to.Replace("*", ".*") + "$"

        if (($SourceBranch -match $fromPattern) -and ($TargetBranch -match $toPattern)) {
            if ($rule.allow) {
                $allowed = $true
                break # Explicit allow found
            }
            else {
                # Explicit deny
                $allowed = $false
                break
            }
        }
    }

    if (-not $allowed) {
        $errors += "❌ Target Policy Violation: Merging '$SourceBranch' into '$TargetBranch' is forbidden."
    }
    else {
        Write-Log "✅ Target Flow OK: $SourceBranch -> $TargetBranch" "SUCCESS"
    }
}

# 4. Check Commit Message (if provided)
if ($CommitMessage -and $policy.rules.commit_message.enabled) {
    if ($CommitMessage -notmatch $policy.rules.commit_message.pattern) {
        $errors += "❌ Commit Message Violation: '$CommitMessage'"
        $errors += "   Hint: $($policy.rules.commit_message.error_message)"
    }
    else {
        Write-Log "✅ Commit Message OK" "SUCCESS"
    }
}

# 5. Report
Write-Host "`n--- REPORT ---"
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Log $_ "ERROR" }
    Write-Log "🚫 GUARD BLOCKED THE GATES" "ERROR"
    exit 1
}
else {
    Write-Log "✨ ALL SYSTEMS GO. OPEN THE GATES." "SUCCESS"
    exit 0
}
