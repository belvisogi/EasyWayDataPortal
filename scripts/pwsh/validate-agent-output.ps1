<#
.SYNOPSIS
Validates agent output for security compliance and governance adherence

.DESCRIPTION
Layer 3 Defense: Scans agent-generated output for security violations,
hardcoded credentials, excessive privileges, and compliance issues.

.PARAMETER OutputJson
JSON string containing the agent output to validate

.PARAMETER AgentRole
Role of the agent that generated the output (e.g., agent_dba, agent_security)

.EXAMPLE
$valid = pwsh scripts/validate-agent-output.ps1 -OutputJson $agentOutput -AgentRole "agent_dba"
if (-not ($valid | ConvertFrom-Json).IsCompliant) {
    Write-Error "Output rejected"
}
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputJson,
    
    [Parameter(Mandatory = $true)]
    [string]$AgentRole
)

function Test-OutputCompliance {
    param(
        [object]$Output,
        [string]$Role
    )
    
    $violations = @()
    
    # Check 1: Structured response required
    $requiredFields = @('what', 'how', 'impacts')
    foreach ($field in $requiredFields) {
        if ($Output.PSObject.Properties.Name -notcontains $field) {
            $violations += "Missing required field: $field (unstructured response)"
        }
    }
    
    # Check 2: Hardcoded credentials (CRITICAL)
    $outputStr = $Output | ConvertTo-Json -Depth 10
    if ($outputStr -match 'password\s*=\s*[''"][^''">]{3,}[''"]' -and
        $outputStr -notmatch '<KEYVAULT') {
        $violations += "CRITICAL: Hardcoded password detected (use Key Vault placeholder)"
    }
    
    if ($outputStr -match 'api[_-]?key\s*=\s*[''"][^''">]+[''"]' -and
        $outputStr -notmatch '<KEYVAULT') {
        $violations += "CRITICAL: Hardcoded API key detected"
    }
    
    if ($outputStr -match 'connectionString.*password\s*=' -and
        $outputStr -notmatch '<KEYVAULT') {
        $violations += "CRITICAL: Connection string with password detected"
    }
    
    # Check 3: DB Agent specific validations
    if ($Role -like '*dba*' -or $Role -like '*database*') {
        # Excessive privilege grants
        if ($outputStr -match 'GRANT\s+ALL.*TO.*PUBLIC') {
            $violations += "Excessive privilege: GRANT ALL TO PUBLIC (violates least privilege)"
        }
        
        if ($outputStr -match 'CREATE\s+USER.*AS\s+SYSADMIN') {
            $violations += "Excessive privilege: Creating SYSADMIN user"
        }
        
        # Missing rollback strategy
        if ($Output.how -and $Output.how.steps) {
            $hasRollback = $Output.how.steps | Where-Object { $_ -match 'rollback|revert' }
            if (-not $hasRollback -and $outputStr -match '(DROP|DELETE|TRUNCATE)') {
                $violations += "Missing rollback strategy for destructive operation"
            }
        }
    }
    
    # Check 4: External URLs (potential exfiltration)
    $allowedDomains = @(
        'dev\.azure\.com',
        'portal\.azure\.com',
        'github\.com',
        'learn\.microsoft\.com'
    )
    
    if ($outputStr -match 'https?://([^/\s]+)') {
        $urls = [regex]::Matches($outputStr, 'https?://([^/\s]+)')
        foreach ($url in $urls) {
            $domain = $url.Groups[1].Value
            $isAllowed = $false
            foreach ($allowed in $allowedDomains) {
                if ($domain -match $allowed) {
                    $isAllowed = $true
                    break
                }
            }
            if (-not $isAllowed) {
                $violations += "External URL detected: $domain (potential data exfiltration)"
            }
        }
    }
    
    # Check 5: Security Agent specific validations
    if ($Role -like '*security*') {
        # Must document permission changes
        if ($outputStr -match '(GRANT|REVOKE|ALTER.*PERMISSION)' -and
            -not $Output.impacts.risks) {
            $violations += "Permission changes must document risks"
        }
    }
    
    # Check 6: Approval requirement validation
    $destructivePatterns = @('DROP', 'DELETE', 'TRUNCATE', 'REVOKE')
    $isDestructive = $false
    foreach ($pattern in $destructivePatterns) {
        if ($outputStr -match $pattern) {
            $isDestructive = $true
            break
        }
    }
    
    if ($isDestructive -and $Output.requires_approval -ne $true) {
        $violations += "Destructive operation must require human approval"
    }
    
    return @{
        IsCompliant    = ($violations.Count -eq 0)
        Violations     = $violations
        ViolationCount = $violations.Count
        Severity       = if ($violations -match 'CRITICAL') { 'critical' }
        elseif ($violations.Count -gt 2) { 'high' }
        elseif ($violations.Count -gt 0) { 'medium' }
        else { 'none' }
    }
}

# Main validation
try {
    $output = $OutputJson | ConvertFrom-Json
    $compliance = Test-OutputCompliance -Output $output -Role $AgentRole
    
    $result = @{
        IsCompliant = $compliance.IsCompliant
        Violations  = $compliance.Violations
        Severity    = $compliance.Severity
        AgentRole   = $AgentRole
        Timestamp   = Get-Date -Format "o"
    }
    
    if (-not $compliance.IsCompliant) {
        Write-Warning "🚨 OUTPUT VALIDATION FAILED"
        Write-Warning "Agent: $AgentRole"
        Write-Warning "Severity: $($compliance.Severity)"
        Write-Warning "Violations ($($compliance.ViolationCount)):"
        foreach ($violation in $compliance.Violations) {
            Write-Warning "  - $violation"
        }
        
        # Log security event
        $event = @{
            event      = "output_validation_failed"
            agent      = $AgentRole
            severity   = $compliance.Severity
            violations = $compliance.Violations
            timestamp  = Get-Date -Format "o"
        } | ConvertTo-Json -Compress
        
        $logDir = "agents/logs"
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path "$logDir/security-events.jsonl" -Value $event
        
        # Critical violations block execution
        if ($compliance.Severity -eq 'critical') {
            Write-Error "BLOCKED: Critical security violation detected"
            $result | ConvertTo-Json -Depth 5
            exit 1
        }
    }
    else {
        Write-Verbose "✅ Output validation passed"
    }
    
    return $result | ConvertTo-Json -Depth 5
    
}
catch {
    Write-Error "Output validation error: $_"
    $errorResult = @{
        IsCompliant = $false
        Error       = $_.Exception.Message
        AgentRole   = $AgentRole
        Timestamp   = Get-Date -Format "o"
    } | ConvertTo-Json
    
    return $errorResult
}
