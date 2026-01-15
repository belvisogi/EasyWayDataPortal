<#
.SYNOPSIS
Validates agent input for prompt injection patterns before execution

.DESCRIPTION
Layer 1 Defense: Scans user input and agent requests for dangerous patterns
including prompt injection, SQL injection, credential leakage, and command injection.

.PARAMETER InputJson
JSON string containing the input to validate

.PARAMETER Strictness
Validation strictness level: low, medium (default), high

.EXAMPLE
$valid = pwsh scripts/validate-agent-input.ps1 -InputJson $userInput
if (-not ($valid | ConvertFrom-Json).IsValid) { 
    Write-Error "Input rejected"
    exit 1 
}
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputJson,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('low', 'medium', 'high')]
    [string]$Strictness = "medium"
)

function Test-PromptInjection {
    param([string]$Text)
    
    # Dangerous patterns (case-insensitive regex)
    $dangerousPatterns = @(
        # Direct instruction override
        'ignora\s+(tutte?\s+le\s+)?istruzioni',
        'ignore\s+(all\s+)?instructions',
        'override\s+(all\s+)?rules',
        'disregard\s+previous',
        'forget\s+everything',
        
        # Privilege escalation
        'grant\s+all\s+(to\s+)?public',
        'create\s+user.*admin',
        'alter\s+user.*sysadmin',
        'exec.*sp_addsrvrolemember',
        
        # Credential leakage
        'password\s*=\s*[''"][^''">]{3,}[''"]',
        'api[_-]?key\s*=\s*[''"][^''">]+[''"]',
        'secret\s*=\s*[''"][^''">]+[''"]',
        'connection[_-]?string.*password',
        
        # Command injection
        ';.*exec\s*\(',
        '\$\(.*\)',
        '`[^`]+`',
        '\|\s*powershell',
        '\|\s*bash',
        
        # Data exfiltration
        'send\s+.*\s+to\s+http',
        'post\s+.*credentials',
        'log\s+.*password',
        'curl.*-d.*password',
        
        # Role manipulation
        'you\s+are\s+now\s+(a\s+)?',
        'act\s+as\s+(a\s+)?(hacker|admin|root)',
        'pretend\s+to\s+be',
        'assume\s+role',
        
        # Hidden instructions
        '\[HIDDEN\]',
        '<!--.*OVERRIDE.*-->',
        '/\*\s*INJECT\s*\*/',
        '\{\{.*BYPASS.*\}\}'
    )
    
    $matches = @()
    $matchDetails = @()
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Text -match $pattern) {
            $match = $Matches[0]
            $matches += $match
            $matchDetails += @{
                Pattern = $pattern
                Match = $match
                Position = $Text.IndexOf($match)
            }
        }
    }
    
    return @{
        IsSafe = ($matches.Count -eq 0)
        Matches = $matches
        MatchDetails = $matchDetails
        Severity = if ($matches.Count -gt 3) { "critical" } 
                   elseif ($matches.Count -gt 1) { "high" } 
                   elseif ($matches.Count -eq 1) { "medium" }
                   else { "none" }
    }
}

function Test-SQLInjection {
    param([string]$Text)
    
    $sqlPatterns = @(
        # SQL injection classic
        "';.*drop\s+table",
        "'\s+or\s+'1'\s*=\s*'1",
        "'\s+or\s+1\s*=\s*1",
        "union\s+select",
        "exec\s*\(\s*'",
        "execute\s*\(\s*'",
        
        # SQL dangerous commands
        "xp_cmdshell",
        "sp_executesql.*drop",
        "truncate\s+table",
        "delete\s+from.*where\s+1\s*=\s*1"
    )
    
    $violations = @()
    
    foreach ($pattern in $sqlPatterns) {
        if ($Text -match $pattern) {
            $violations += @{
                Pattern = $pattern
                Match = $Matches[0]
            }
        }
    }
    
    return @{
        IsSafe = ($violations.Count -eq 0)
        Violations = $violations
    }
}

function Test-PathTraversal {
    param([string]$Text)
    
    $pathPatterns = @(
        '\.\./\.\.',  # ../..
        '\.\.\\\.\.', # ..\..
        '%2e%2e',     # URL encoded ..
        '/etc/passwd',
        'C:\\Windows\\System32'
    )
    
    foreach ($pattern in $pathPatterns) {
        if ($Text -match $pattern) {
            return @{
                IsSafe = $false
                Pattern = $pattern
            }
        }
    }
    
    return @{ IsSafe = $true }
}

# Main validation
try {
    $input = $InputJson | ConvertFrom-Json
    
    # Validate all text fields recursively
    $allText = ($input | ConvertTo-Json -Depth 10)
    
    $promptCheck = Test-PromptInjection -Text $allText
    $sqlCheck = Test-SQLInjection -Text $allText
    $pathCheck = Test-PathTraversal -Text $allText
    
    $result = @{
        IsValid = ($promptCheck.IsSafe -and $sqlCheck.IsSafe -and $pathCheck.IsSafe)
        PromptInjection = $promptCheck
        SQLInjection = $sqlCheck
        PathTraversal = $pathCheck
        Strictness = $Strictness
        Timestamp = Get-Date -Format "o"
    }
    
    if (-not $result.IsValid) {
        Write-Warning "⚠️ SECURITY ALERT: Potential injection detected!"
        
        if (-not $promptCheck.IsSafe) {
            Write-Warning "  Prompt injection matches: $($promptCheck.Matches -join ', ')"
            Write-Warning "  Severity: $($promptCheck.Severity)"
        }
        
        if (-not $sqlCheck.IsSafe) {
            Write-Warning "  SQL injection patterns: $($sqlCheck.Violations.Count)"
        }
        
        if (-not $pathCheck.IsSafe) {
            Write-Warning "  Path traversal detected: $($pathCheck.Pattern)"
        }
        
        # Log to security events
        $securityLog = @{
            event = "input_validation_failed"
            input_preview = $InputJson.Substring(0, [Math]::Min(200, $InputJson.Length))
            checks = @{
                prompt_injection = $promptCheck
                sql_injection = $sqlCheck
                path_traversal = $pathCheck
            }
            timestamp = Get-Date -Format "o"
        } | ConvertTo-Json -Compress
        
        $logDir = "agents/logs"
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path "$logDir/security-events.jsonl" -Value $securityLog
        
        # In high strictness mode, fail immediately
        if ($Strictness -eq 'high' -and $promptCheck.Severity -in @('critical', 'high')) {
            Write-Error "BLOCKED: Security violation severity=$($promptCheck.Severity)"
            $result | ConvertTo-Json -Depth 5
            exit 1
        }
    } else {
        Write-Verbose "✅ Input validation passed"
    }
    
    return $result | ConvertTo-Json -Depth 5
    
} catch {
    Write-Error "Validation error: $_"
    $errorResult = @{
        IsValid = $false
        Error = $_.Exception.Message
        Timestamp = Get-Date -Format "o"
    } | ConvertTo-Json
    
    return $errorResult
}
