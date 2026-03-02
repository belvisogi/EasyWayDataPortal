<#
.SYNOPSIS
    Scans git-tracked files for leaked secrets and governance violations.

.DESCRIPTION
    Rule-based scanner (no LLM). Detects hardcoded credentials, API keys,
    passwords, and PAT governance violations. Produces structured JSON report.
    NEVER accesses or logs actual secret values -- only detects patterns
    and reports file:line locations with redacted context.

.PARAMETER ScanPath
    Repository root to scan. Defaults to current directory.

.PARAMETER OutputFormat
    "json" or "markdown". Default: json.

.PARAMETER Severity
    Filter: "all", "critical", "high". Default: all.

.PARAMETER Json
    Switch for machine-readable JSON output (alias for -OutputFormat json).

.EXAMPLE
    pwsh agents/skills/security/Invoke-SecretsScan.ps1 -ScanPath . -Json

.EXAMPLE
    pwsh agents/skills/security/Invoke-SecretsScan.ps1 -Severity critical
#>

[CmdletBinding()]
Param(
    [string] $ScanPath      = '.',
    [ValidateSet('json', 'markdown')]
    [string] $OutputFormat   = 'json',
    [ValidateSet('all', 'critical', 'high')]
    [string] $Severity       = 'all',
    [switch] $Json
)

$ErrorActionPreference = 'Stop'
if ($Json) { $OutputFormat = 'json' }

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# ── Secret Detection Patterns ────────────────────────────────────────────────
$secretPatterns = @(
    @{ Name = 'Private Key';        Severity = 'CRITICAL'; Pattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' }
    @{ Name = 'Generic API Key';    Severity = 'HIGH';     Pattern = '(?i)(api[_-]?key|apikey)\s*[:=]\s*["\x27]?[A-Za-z0-9/+=]{20,}' }
    @{ Name = 'Hardcoded Password'; Severity = 'HIGH';     Pattern = '(?i)(password|passwd|pwd)\s*[:=]\s*["\x27][^"\x27]{4,}["\x27]' }
    @{ Name = 'Bearer Token';       Severity = 'HIGH';     Pattern = '(?i)bearer\s+[A-Za-z0-9\-._~+/]{20,}=*' }
    @{ Name = 'Connection String';  Severity = 'HIGH';     Pattern = '(?i)(server|host)=[^;]+;.*password=[^;]+' }
    @{ Name = 'AWS Access Key';     Severity = 'CRITICAL'; Pattern = 'AKIA[0-9A-Z]{16}' }
    @{ Name = 'GitHub PAT';         Severity = 'CRITICAL'; Pattern = 'ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,}' }
    @{ Name = 'OpenRouter Key';     Severity = 'CRITICAL'; Pattern = 'sk-or-v1-[a-f0-9]{64}' }
    @{ Name = 'DeepSeek Key';       Severity = 'CRITICAL'; Pattern = 'sk-[a-f0-9]{32,}' }
)

# Known leaked values (patterns, NOT the actual values -- just enough to match)
# These are maintained by the security team and should be updated after each rotation
$knownLeakedPatterns = @(
    @{ Name = 'Known Qdrant Key Pattern'; Severity = 'CRITICAL'; Pattern = 'wgs6[A-Za-z0-9]{28}' }
    @{ Name = 'Known Gitea Password';     Severity = 'CRITICAL'; Pattern = 'EasyWay2026!' }
)

$allPatterns = $secretPatterns + $knownLeakedPatterns

# ── Safe Patterns (exclusions) ───────────────────────────────────────────────
$safeLinePatterns = @(
    '\$\{[A-Z_]+\}',            # ${VAR} docker/bash references
    '\$env:[A-Z_]+',            # $env:VAR PowerShell references
    '\$[A-Z_][A-Z_0-9]*',      # $VAR bash references (uppercase = env var convention)
    'ChangeMe',
    'placeholder',
    '<PASTE_',
    '<REDACTED>',
    'UNKNOWN_PLEASE',
    '\*\*\*REDACTED\*\*\*',
    'vedi `/opt/easyway/',      # our documentation reference pattern
    'stored in .*/\.env'        # documentation reference
)

$excludedFilePatterns = @(
    '\.env\.example$',
    '\.env\..*\.example$',
    '\\node_modules\\',
    '\\dist\\',
    '\\.git\\',
    '\\.png$', '\\.jpg$', '\\.jpeg$', '\\.gif$', '\\.ico$',
    '\\.woff$', '\\.woff2$', '\\.ttf$', '\\.eot$',
    '\\.zip$', '\\.gz$', '\\.tar$', '\\.7z$',
    '\\.exe$', '\\.dll$', '\\.so$', '\\.dylib$',
    '\\.pdf$', '\\.docx$',
    '\\package-lock\.json$'
)

# ── PAT Governance Mapping ───────────────────────────────────────────────────
$patGovernance = @(
    @{
        Script = 'Resolve-PRConflicts.ps1'
        Operation = 'PR comments + push'
        ExpectedPrimary = 'ADO_PR_CREATOR_PAT'
        WrongPattern = '^\s*\[string\]\s*\$Pat\s*=\s*\$env:AZURE_DEVOPS_EXT_PAT\s*,?\s*$'
        CorrectPattern = 'ADO_PR_CREATOR_PAT'
    }
    @{
        Script = 'Convert-PrdToPbi.ps1'
        Operation = 'Create Work Items'
        ExpectedPrimary = 'ADO_WORKITEMS_PAT'
        WrongPattern = '^\s*\[string\]\s*\$Pat\s*=\s*\$env:AZURE_DEVOPS_EXT_PAT\s*,?\s*$'
        CorrectPattern = 'ADO_WORKITEMS_PAT'
    }
)

# ── Get git-tracked files ────────────────────────────────────────────────────
Push-Location $ScanPath
try {
    $gitFiles = git ls-files 2>$null
    if (-not $gitFiles) {
        Write-Error "Not a git repository or no tracked files at '$ScanPath'"
        exit 1
    }
    $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
    $gitSha = git rev-parse --short HEAD 2>$null
}
finally {
    Pop-Location
}

# ── Scan ─────────────────────────────────────────────────────────────────────
$findings = [System.Collections.ArrayList]::new()
$filesScanned = 0
$findingId = 0

foreach ($file in $gitFiles) {
    $fullPath = Join-Path $ScanPath $file

    # Skip excluded file patterns
    $skip = $false
    foreach ($ep in $excludedFilePatterns) {
        if ($file -match $ep) { $skip = $true; break }
    }
    if ($skip) { continue }

    if (-not (Test-Path $fullPath -PathType Leaf)) { continue }

    # Skip files > 1MB (likely binary or generated)
    $fileInfo = Get-Item $fullPath
    if ($fileInfo.Length -gt 1048576) { continue }

    $filesScanned++

    try {
        $lines = Get-Content $fullPath -ErrorAction SilentlyContinue
    }
    catch { continue }

    if (-not $lines) { continue }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $line -or $line.Length -lt 10) { continue }

        foreach ($pattern in $allPatterns) {
            if ($Severity -eq 'critical' -and $pattern.Severity -ne 'CRITICAL') { continue }
            if ($Severity -eq 'high' -and $pattern.Severity -notin @('CRITICAL', 'HIGH')) { continue }

            if ($line -match $pattern.Pattern) {
                # Check if this line contains a safe pattern (variable reference, placeholder, etc.)
                $isSafe = $false
                foreach ($sp in $safeLinePatterns) {
                    if ($line -match $sp) { $isSafe = $true; break }
                }
                if ($isSafe) { continue }

                # Redact the matched value in context
                $redactedLine = $line -replace $pattern.Pattern, '***REDACTED***'
                if ($redactedLine.Length -gt 120) {
                    $redactedLine = $redactedLine.Substring(0, 117) + '...'
                }

                $findingId++
                [void]$findings.Add(@{
                    id          = "F{0:D3}" -f $findingId
                    severity    = $pattern.Severity
                    category    = 'leaked_secret'
                    pattern     = $pattern.Name
                    file        = $file
                    line        = $i + 1
                    context     = $redactedLine.Trim()
                    remediation = "Remove secret value. Use env var reference or point to /opt/easyway/.env.secrets"
                })
            }
        }
    }
}

# ── PAT Governance Compliance Check ──────────────────────────────────────────
$compliance = [System.Collections.ArrayList]::new()

foreach ($rule in $patGovernance) {
    $scriptFiles = $gitFiles | Where-Object { $_ -like "*$($rule.Script)" }
    foreach ($sf in $scriptFiles) {
        $sfPath = Join-Path $ScanPath $sf
        if (-not (Test-Path $sfPath)) { continue }

        $content = Get-Content $sfPath -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $status = 'COMPLIANT'
        $actualPat = $rule.ExpectedPrimary

        # Check if the script uses the wrong PAT as primary
        $lines = Get-Content $sfPath
        foreach ($l in $lines) {
            if ($l -match $rule.WrongPattern) {
                $status = 'VIOLATION'
                $actualPat = 'AZURE_DEVOPS_EXT_PAT'
                break
            }
        }

        # Also check if the correct PAT appears anywhere (might be in fallback pattern already)
        if ($status -eq 'VIOLATION' -and $content -match $rule.CorrectPattern) {
            $status = 'COMPLIANT'
            $actualPat = $rule.ExpectedPrimary
        }

        [void]$compliance.Add(@{
            script       = $rule.Script
            file         = $sf
            operation    = $rule.Operation
            expected_pat = $rule.ExpectedPrimary
            actual_pat   = $actualPat
            status       = $status
        })
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────
$stopwatch.Stop()

$summary = @{
    total_files_scanned = $filesScanned
    total_findings      = $findings.Count
    critical            = ($findings | Where-Object { $_.severity -eq 'CRITICAL' }).Count
    high                = ($findings | Where-Object { $_.severity -eq 'HIGH' }).Count
    medium              = ($findings | Where-Object { $_.severity -eq 'MEDIUM' }).Count
    low                 = ($findings | Where-Object { $_.severity -eq 'LOW' }).Count
    compliant_scripts   = ($compliance | Where-Object { $_.status -eq 'COMPLIANT' }).Count
    non_compliant_scripts = ($compliance | Where-Object { $_.status -eq 'VIOLATION' }).Count
}

$report = @{
    scan_timestamp = (Get-Date -Format 'o')
    scan_duration_ms = $stopwatch.ElapsedMilliseconds
    repo_root      = (Resolve-Path $ScanPath).Path
    git_branch     = $gitBranch
    git_sha        = $gitSha
    findings       = @($findings)
    compliance     = @($compliance)
    summary        = $summary
}

# ── Output ───────────────────────────────────────────────────────────────────
if ($OutputFormat -eq 'json') {
    $report | ConvertTo-Json -Depth 5
}
else {
    Write-Host "# Sentinel Secrets Scan Report" -ForegroundColor Cyan
    Write-Host "Branch: $gitBranch | SHA: $gitSha | Files: $filesScanned" -ForegroundColor Gray
    Write-Host ""

    if ($findings.Count -eq 0) {
        Write-Host "No secrets detected." -ForegroundColor Green
    }
    else {
        Write-Host "## Findings ($($findings.Count))" -ForegroundColor Yellow
        foreach ($f in $findings) {
            $color = if ($f.severity -eq 'CRITICAL') { 'Red' } elseif ($f.severity -eq 'HIGH') { 'Yellow' } else { 'Gray' }
            Write-Host "  [$($f.severity)] $($f.pattern) -- $($f.file):$($f.line)" -ForegroundColor $color
            Write-Host "    $($f.context)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "## PAT Governance Compliance" -ForegroundColor Cyan
    foreach ($c in $compliance) {
        $color = if ($c.status -eq 'COMPLIANT') { 'Green' } else { 'Red' }
        Write-Host "  [$($c.status)] $($c.script) -- expected: $($c.expected_pat), actual: $($c.actual_pat)" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "Summary: $($summary.critical) CRITICAL, $($summary.high) HIGH | Compliance: $($summary.compliant_scripts)/$($summary.compliant_scripts + $summary.non_compliant_scripts)" -ForegroundColor White
}
