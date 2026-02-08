# 🎯 EasyWay Agents - Skills System Framework

**Version:** 2.0.0
**Created:** 2026-02-08
**Status:** ✅ Production Standard

---

## 📋 Overview

Il **Skills System** è un framework modulare che permette agli agent di:
- 🔌 **Riutilizzare** funzionalità comuni tra agent diversi
- 🧩 **Comporre** azioni complesse da building blocks semplici
- 📚 **Imparare** nuove capacità dinamicamente
- 🔍 **Scoprire** skills disponibili a runtime
- 🧪 **Testare** funzionalità in isolamento

---

## 🏗️ Architecture

```
agents/
├── skills/                      # ⭐ Shared skills repository
│   ├── README.md               # Skills catalog
│   ├── registry.json           # Skills metadata
│   ├── security/               # Security domain
│   │   ├── Invoke-CVEScan.ps1
│   │   ├── Test-CertificateExpiry.ps1
│   │   └── Get-SecretFromVault.ps1
│   ├── database/               # Database domain
│   │   ├── Invoke-Migration.ps1
│   │   ├── Test-Connection.ps1
│   │   └── Export-Schema.ps1
│   ├── observability/          # Observability domain
│   │   ├── Test-HealthCheck.ps1
│   │   ├── Export-Metrics.ps1
│   │   └── Send-Alert.ps1
│   ├── integration/            # Integration domain
│   │   ├── Invoke-WebhookCall.ps1
│   │   ├── Send-SlackMessage.ps1
│   │   └── Create-ADOWorkItem.ps1
│   └── utilities/              # Utility domain
│       ├── ConvertTo-Markdown.ps1
│       ├── Test-VersionCompatibility.ps1
│       └── Invoke-RetryWithBackoff.ps1
│
├── agent_xxx/
│   ├── manifest.json           # References skills needed
│   └── PROMPTS.md              # LLM knows available skills

scripts/pwsh/
└── agent-xxx.ps1               # Loads skills from manifest
```

---

## 📝 Skill Definition Format

Each skill is a **PowerShell function** with:
1. **Standardized naming:** `Verb-Noun` (e.g., `Invoke-CVEScan`, `Test-HealthCheck`)
2. **Parameter validation:** Using `[Parameter()]` attributes
3. **Output typing:** Returns structured objects (PSCustomObject)
4. **Error handling:** Try/catch with detailed error messages
5. **Documentation:** Comment-based help

### Example Skill

```powershell
# agents/skills/security/Invoke-CVEScan.ps1

<#
.SYNOPSIS
    Scans a Docker image for CVE vulnerabilities.

.DESCRIPTION
    Uses Docker Scout or Snyk to scan for known CVEs in Docker images.
    Returns structured vulnerability report with severity classification.

.PARAMETER ImageName
    Docker image to scan (e.g., "n8nio/n8n:1.123.20")

.PARAMETER Scanner
    Scanner to use: "docker-scout", "snyk", or "trivy"

.PARAMETER FailOnSeverity
    Fail (exit code 1) if vulnerabilities >= this severity are found

.EXAMPLE
    Invoke-CVEScan -ImageName "n8nio/n8n:1.123.20" -Scanner "docker-scout"

.OUTPUTS
    PSCustomObject with:
    - ImageName: string
    - Scanner: string
    - ScanDate: datetime
    - Vulnerabilities: array of CVE objects
    - Summary: { critical, high, medium, low }
#>
function Invoke-CVEScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("docker-scout", "snyk", "trivy")]
        [string]$Scanner = "docker-scout",

        [Parameter(Mandatory = $false)]
        [ValidateSet("critical", "high", "medium", "low")]
        [string]$FailOnSeverity = "high"
    )

    try {
        Write-Verbose "Scanning $ImageName with $Scanner..."

        $result = switch ($Scanner) {
            "docker-scout" {
                $output = docker scout cves $ImageName --format json 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Docker Scout failed: $output"
                }
                $output | ConvertFrom-Json
            }
            "snyk" {
                $output = snyk container test $ImageName --json
                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
                    # Exit code 1 = vulnerabilities found (expected)
                    throw "Snyk failed: $output"
                }
                $output | ConvertFrom-Json
            }
            "trivy" {
                $output = trivy image --format json $ImageName
                if ($LASTEXITCODE -ne 0) {
                    throw "Trivy failed: $output"
                }
                $output | ConvertFrom-Json
            }
        }

        # Normalize output to standard format
        $vulnerabilities = @()
        $summary = @{
            critical = 0
            high = 0
            medium = 0
            low = 0
        }

        # Parse scanner-specific format (implementation varies)
        # ...

        $report = [PSCustomObject]@{
            ImageName = $ImageName
            Scanner = $Scanner
            ScanDate = Get-Date -Format "o"
            Vulnerabilities = $vulnerabilities
            Summary = $summary
            TotalCount = $vulnerabilities.Count
        }

        # Check if should fail
        $shouldFail = $false
        switch ($FailOnSeverity) {
            "critical" { $shouldFail = $summary.critical -gt 0 }
            "high" { $shouldFail = ($summary.critical -gt 0 -or $summary.high -gt 0) }
            "medium" { $shouldFail = ($summary.critical -gt 0 -or $summary.high -gt 0 -or $summary.medium -gt 0) }
            "low" { $shouldFail = $report.TotalCount -gt 0 }
        }

        if ($shouldFail) {
            throw "Scan failed: Found $($summary.critical) critical, $($summary.high) high vulnerabilities"
        }

        return $report

    } catch {
        Write-Error "CVE scan failed for ${ImageName}: $_"
        throw
    }
}
```

---

## 📦 Skill Registry Format

**File:** `agents/skills/registry.json`

```json
{
  "version": "2.0.0",
  "last_updated": "2026-02-08T10:00:00Z",
  "skills": [
    {
      "id": "security.cve-scan",
      "name": "Invoke-CVEScan",
      "domain": "security",
      "file": "agents/skills/security/Invoke-CVEScan.ps1",
      "version": "1.0.0",
      "description": "Scan Docker images for CVE vulnerabilities",
      "parameters": [
        {
          "name": "ImageName",
          "type": "string",
          "required": true,
          "description": "Docker image to scan"
        },
        {
          "name": "Scanner",
          "type": "string",
          "required": false,
          "default": "docker-scout",
          "enum": ["docker-scout", "snyk", "trivy"]
        },
        {
          "name": "FailOnSeverity",
          "type": "string",
          "required": false,
          "default": "high",
          "enum": ["critical", "high", "medium", "low"]
        }
      ],
      "outputs": {
        "type": "object",
        "properties": {
          "ImageName": { "type": "string" },
          "Scanner": { "type": "string" },
          "ScanDate": { "type": "string", "format": "date-time" },
          "Vulnerabilities": { "type": "array" },
          "Summary": {
            "type": "object",
            "properties": {
              "critical": { "type": "integer" },
              "high": { "type": "integer" },
              "medium": { "type": "integer" },
              "low": { "type": "integer" }
            }
          }
        }
      },
      "dependencies": ["docker", "docker-scout OR snyk OR trivy"],
      "tags": ["security", "cve", "docker", "vulnerability"],
      "tested_with": {
        "docker": ">=20.10.0",
        "docker-scout": ">=0.5.0"
      }
    },
    {
      "id": "utilities.version-compatibility",
      "name": "Test-VersionCompatibility",
      "domain": "utilities",
      "file": "agents/skills/utilities/Test-VersionCompatibility.ps1",
      "version": "1.0.0",
      "description": "Check version compatibility against matrix",
      "parameters": [
        {
          "name": "Component",
          "type": "string",
          "required": true,
          "description": "Component name (e.g., 'n8n', 'postgres')"
        },
        {
          "name": "Version",
          "type": "string",
          "required": true,
          "description": "Version to check (e.g., '1.123.20')"
        },
        {
          "name": "MatrixFile",
          "type": "string",
          "required": false,
          "default": "./compatibility-matrix.json"
        }
      ],
      "outputs": {
        "type": "object",
        "properties": {
          "IsCompatible": { "type": "boolean" },
          "Issues": { "type": "array" },
          "Recommendations": { "type": "array" }
        }
      },
      "dependencies": [],
      "tags": ["compatibility", "version", "validation"]
    }
  ]
}
```

---

## 🔌 How Agents Use Skills

### 1. Declare Skills in Manifest

**File:** `agents/agent_vulnerability_scanner/manifest.json`

```json
{
  "id": "agent_vulnerability_scanner",
  "name": "agent_vulnerability_scanner",
  "role": "Agent_Security_Scanner",

  "skills_required": [
    "security.cve-scan",
    "utilities.version-compatibility",
    "observability.health-check",
    "integration.slack-alert"
  ],

  "skills_optional": [
    "security.certificate-expiry",
    "database.test-connection"
  ],

  "actions": [
    {
      "name": "vuln-scan:full",
      "description": "Full vulnerability scan using multiple skills",
      "uses_skills": [
        "security.cve-scan",
        "utilities.version-compatibility",
        "observability.health-check"
      ],
      "params": { ... }
    }
  ]
}
```

### 2. Load Skills at Runtime

**File:** `scripts/pwsh/agent-vulnerability-scanner.ps1`

```powershell
# Load Skills System
. "$PSScriptRoot/../agents/skills/Load-Skills.ps1"

# Load agent manifest
$manifest = Get-Content "$PSScriptRoot/../agents/agent_vulnerability_scanner/manifest.json" | ConvertFrom-Json

# Auto-load required skills
foreach ($skillId in $manifest.skills_required) {
    Import-Skill -SkillId $skillId
}

# Now skills are available as functions
function Invoke-FullScan {
    param($Intent)

    # Use loaded skills
    $cveResults = Invoke-CVEScan -ImageName "n8nio/n8n:1.123.20" -Scanner "docker-scout"

    $compatResults = Test-VersionCompatibility -Component "n8n" -Version "1.123.20"

    $healthResults = Test-HealthCheck -Endpoints @("http://localhost/health")

    # Combine results
    return @{
        CVE = $cveResults
        Compatibility = $compatResults
        Health = $healthResults
    }
}
```

### 3. Skill Loader Implementation

**File:** `agents/skills/Load-Skills.ps1`

```powershell
<#
.SYNOPSIS
    Skills System loader for EasyWay Agents

.DESCRIPTION
    Provides functions to discover, load, and use skills dynamically.
#>

$script:SkillsRegistry = $null
$script:LoadedSkills = @{}

function Get-SkillsRegistry {
    if (-not $script:SkillsRegistry) {
        $registryPath = Join-Path $PSScriptRoot "registry.json"
        $script:SkillsRegistry = Get-Content $registryPath | ConvertFrom-Json
    }
    return $script:SkillsRegistry
}

function Import-Skill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillId
    )

    # Check if already loaded
    if ($script:LoadedSkills.ContainsKey($SkillId)) {
        Write-Verbose "Skill $SkillId already loaded"
        return
    }

    # Find skill in registry
    $registry = Get-SkillsRegistry
    $skill = $registry.skills | Where-Object { $_.id -eq $SkillId }

    if (-not $skill) {
        throw "Skill not found: $SkillId"
    }

    # Resolve file path
    $skillPath = Join-Path $PSScriptRoot ".." $skill.file
    if (-not (Test-Path $skillPath)) {
        throw "Skill file not found: $skillPath"
    }

    # Dot-source the skill
    try {
        . $skillPath
        $script:LoadedSkills[$SkillId] = @{
            Metadata = $skill
            LoadedAt = Get-Date
        }
        Write-Verbose "Loaded skill: $($skill.name) from $skillPath"
    } catch {
        throw "Failed to load skill ${SkillId}: $_"
    }
}

function Get-LoadedSkills {
    return $script:LoadedSkills
}

function Get-AvailableSkills {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags
    )

    $registry = Get-SkillsRegistry
    $skills = $registry.skills

    if ($Domain) {
        $skills = $skills | Where-Object { $_.domain -eq $Domain }
    }

    if ($Tags) {
        $skills = $skills | Where-Object {
            $skillTags = $_.tags
            $matchCount = ($Tags | Where-Object { $skillTags -contains $_ }).Count
            $matchCount -gt 0
        }
    }

    return $skills
}

function Test-SkillDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillId
    )

    $registry = Get-SkillsRegistry
    $skill = $registry.skills | Where-Object { $_.id -eq $SkillId }

    if (-not $skill) {
        throw "Skill not found: $SkillId"
    }

    $missingDeps = @()
    foreach ($dep in $skill.dependencies) {
        # Check if dependency is available
        $cmd = Get-Command $dep -ErrorAction SilentlyContinue
        if (-not $cmd) {
            $missingDeps += $dep
        }
    }

    return @{
        SkillId = $SkillId
        AllDependenciesAvailable = $missingDeps.Count -eq 0
        MissingDependencies = $missingDeps
    }
}
```

---

## 🧪 Testing Skills

### Unit Test Example

**File:** `agents/skills/security/Invoke-CVEScan.Tests.ps1`

```powershell
BeforeAll {
    . "$PSScriptRoot/Invoke-CVEScan.ps1"
}

Describe "Invoke-CVEScan" {
    Context "When scanning valid image" {
        It "Returns structured report" {
            Mock docker { '{"vulnerabilities": []}' }

            $result = Invoke-CVEScan -ImageName "alpine:latest" -Scanner "docker-scout"

            $result.ImageName | Should -Be "alpine:latest"
            $result.Scanner | Should -Be "docker-scout"
            $result.ScanDate | Should -Not -BeNullOrEmpty
            $result.Summary | Should -Not -BeNull
        }
    }

    Context "When critical CVEs found" {
        It "Throws if FailOnSeverity is critical" {
            Mock docker {
                '{"vulnerabilities": [{"severity": "critical"}]}'
            }

            {
                Invoke-CVEScan -ImageName "vulnerable:1.0" -FailOnSeverity "critical"
            } | Should -Throw
        }
    }

    Context "When scanner not available" {
        It "Throws clear error message" {
            Mock docker { throw "command not found" }

            {
                Invoke-CVEScan -ImageName "test:1.0"
            } | Should -Throw "*Docker Scout failed*"
        }
    }
}
```

---

## 📊 Skills Catalog

### Security Domain

| Skill ID | Function | Description |
|----------|----------|-------------|
| security.cve-scan | Invoke-CVEScan | Scan Docker images for CVEs |
| security.certificate-expiry | Test-CertificateExpiry | Check SSL/TLS certificate expiry |
| security.secret-vault | Get-SecretFromVault | Retrieve secret from Azure Key Vault |
| security.password-gen | New-SecurePassword | Generate cryptographically secure password |
| security.hash-password | ConvertTo-PasswordHash | Hash password with bcrypt/argon2 |

### Database Domain

| Skill ID | Function | Description |
|----------|----------|-------------|
| database.migration | Invoke-Migration | Run DB migration script |
| database.test-connection | Test-Connection | Test database connectivity |
| database.export-schema | Export-Schema | Export DB schema to JSON/SQL |
| database.backup | Invoke-Backup | Backup database to file |
| database.user-create | New-DatabaseUser | Create DB user with permissions |

### Observability Domain

| Skill ID | Function | Description |
|----------|----------|-------------|
| observability.health-check | Test-HealthCheck | HTTP health endpoint check |
| observability.metrics | Export-Metrics | Export Prometheus metrics |
| observability.alert | Send-Alert | Send alert to Slack/PagerDuty |
| observability.log-query | Get-Logs | Query application logs |

### Integration Domain

| Skill ID | Function | Description |
|----------|----------|-------------|
| integration.webhook | Invoke-WebhookCall | Call HTTP webhook |
| integration.slack | Send-SlackMessage | Send Slack message/notification |
| integration.ado-workitem | Create-ADOWorkItem | Create Azure DevOps work item |
| integration.email | Send-Email | Send email via SMTP/SendGrid |

### Utilities Domain

| Skill ID | Function | Description |
|----------|----------|-------------|
| utilities.version-compatibility | Test-VersionCompatibility | Check version compatibility |
| utilities.retry | Invoke-RetryWithBackoff | Retry action with exponential backoff |
| utilities.markdown | ConvertTo-Markdown | Convert object to Markdown table |
| utilities.json-validate | Test-JsonSchema | Validate JSON against schema |

---

## 🎓 Best Practices

### 1. Single Responsibility
Each skill should do **one thing well**.
- ✅ `Invoke-CVEScan` - scans for CVEs
- ❌ `Invoke-SecurityAudit` - does CVEs + certificates + passwords (too broad)

### 2. Idempotency
Skills should be **safe to run multiple times**.
```powershell
# ✅ Good - idempotent
function New-DatabaseUser {
    param($Username)

    $exists = Test-DatabaseUserExists -Username $Username
    if ($exists) {
        Write-Verbose "User $Username already exists"
        return Get-DatabaseUser -Username $Username
    }

    # Create user
}

# ❌ Bad - fails on second run
function New-DatabaseUser {
    param($Username)
    # CREATE USER (fails if exists)
}
```

### 3. Structured Output
Always return **PSCustomObject** with consistent properties.
```powershell
# ✅ Good
return [PSCustomObject]@{
    Success = $true
    Message = "Scan completed"
    Data = $results
    Timestamp = Get-Date -Format "o"
}

# ❌ Bad
return "Scan completed: $results"
```

### 4. Error Handling
Use **try/catch** with meaningful error messages.
```powershell
try {
    $result = Invoke-SomeOperation
} catch {
    $errorDetails = @{
        Operation = "Invoke-SomeOperation"
        Error = $_.Exception.Message
        Timestamp = Get-Date
        Context = @{
            Param1 = $param1
            Param2 = $param2
        }
    }
    Write-Error ($errorDetails | ConvertTo-Json)
    throw
}
```

### 5. Documentation
Use **comment-based help** for all skills.
```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description

.PARAMETER Name
    Parameter description

.EXAMPLE
    Example usage

.OUTPUTS
    What the function returns
#>
```

---

## 🔄 Skill Lifecycle

### Creating a New Skill

1. **Create skill file:** `agents/skills/{domain}/{Verb-Noun}.ps1`
2. **Implement function** with proper parameters and error handling
3. **Add to registry:** Update `agents/skills/registry.json`
4. **Write tests:** Create `{Verb-Noun}.Tests.ps1`
5. **Document:** Update `agents/skills/README.md` catalog
6. **Validate:** Run `Test-SkillDependencies`

### Versioning Skills

When making **breaking changes** to a skill:
1. Increment version in registry.json
2. Document breaking changes in skill file header
3. Consider creating `{Verb-Noun}-v2.ps1` for backward compatibility
4. Update all agents that use the skill

### Deprecating Skills

1. Mark as `"deprecated": true` in registry.json
2. Add deprecation notice in skill file
3. Provide migration path to replacement skill
4. Remove after 2 releases

---

## 📈 Metrics & Monitoring

### Skill Usage Tracking

```powershell
# In Load-Skills.ps1
function Import-Skill {
    # ... (loading code)

    # Track usage
    $usageLog = @{
        SkillId = $SkillId
        Agent = $env:AGENT_NAME
        LoadedAt = Get-Date -Format "o"
        LoadedBy = $env:USERNAME
    }

    Add-Content -Path "agents/logs/skill-usage.jsonl" -Value ($usageLog | ConvertTo-Json -Compress)
}
```

### Performance Monitoring

```powershell
# Wrap skill calls with timing
function Invoke-SkillWithMetrics {
    param($SkillId, $Parameters)

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $result = & $SkillId @Parameters
        $status = "success"
    } catch {
        $status = "error"
        throw
    } finally {
        $stopwatch.Stop()

        $metrics = @{
            SkillId = $SkillId
            Duration = $stopwatch.ElapsedMilliseconds
            Status = $status
            Timestamp = Get-Date -Format "o"
        }

        Add-Content -Path "agents/logs/skill-metrics.jsonl" -Value ($metrics | ConvertTo-Json -Compress)
    }

    return $result
}
```

---

## 🚀 Next Steps

1. **Implement core skills** (security, database, observability)
2. **Update all agents** to use skills instead of inline code
3. **Create skill discovery UI** (optional - list available skills)
4. **Build skill composition** (combine skills into workflows)
5. **Add LLM integration** (Level 2 - LLM chooses which skills to use)

---

## 📚 References

- [AGENT_WORKFLOW_STANDARD.md](./AGENT_WORKFLOW_STANDARD.md) - Agent patterns
- [AGENT_EVOLUTION_GUIDE.md](./AGENT_EVOLUTION_GUIDE.md) - Evolution levels
- [LLM_INTEGRATION_PATTERN.md](./LLM_INTEGRATION_PATTERN.md) - LLM reasoning

---

**Status:** ✅ Production Standard
**Owner:** EasyWay Platform Team
**Last Updated:** 2026-02-08
