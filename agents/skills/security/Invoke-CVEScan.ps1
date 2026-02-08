<#
.SYNOPSIS
    Scan Docker image for CVE vulnerabilities

.DESCRIPTION
    Uses Docker Scout, Snyk, or Trivy to scan Docker images for known CVEs.
    Returns structured vulnerability report with severity classification.

.PARAMETER ImageName
    Docker image to scan (e.g., "n8nio/n8n:1.123.20")

.PARAMETER Scanner
    Scanner to use: "docker-scout", "snyk", or "trivy"

.PARAMETER FailOnSeverity
    Fail (throw exception) if vulnerabilities >= this severity are found

.PARAMETER OutputFormat
    Output format: "object" (PSCustomObject) or "json" (JSON string)

.EXAMPLE
    Invoke-CVEScan -ImageName "n8nio/n8n:1.123.20" -Scanner "docker-scout"

.EXAMPLE
    Invoke-CVEScan -ImageName "postgres:15.10-alpine" -FailOnSeverity "critical"

.OUTPUTS
    PSCustomObject with:
    - ImageName: string
    - Scanner: string
    - ScanDate: datetime
    - Vulnerabilities: array of CVE objects
    - Summary: { critical, high, medium, low }
    - TotalCount: integer
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
        [ValidateSet("critical", "high", "medium", "low", "none")]
        [string]$FailOnSeverity = "none",

        [Parameter(Mandatory = $false)]
        [ValidateSet("object", "json")]
        [string]$OutputFormat = "object"
    )

    try {
        Write-Verbose "Scanning $ImageName with $Scanner..."

        $vulnerabilities = @()
        $summary = @{
            critical = 0
            high = 0
            medium = 0
            low = 0
        }

        # Check if scanner is available
        $scannerCmd = switch ($Scanner) {
            "docker-scout" { "docker" }
            "snyk" { "snyk" }
            "trivy" { "trivy" }
        }

        if (-not (Get-Command $scannerCmd -ErrorAction SilentlyContinue)) {
            throw "Scanner command not found: $scannerCmd. Please install $Scanner first."
        }

        # Execute scanner
        $scanResult = switch ($Scanner) {
            "docker-scout" {
                Write-Verbose "Running: docker scout cves $ImageName --format json"
                $output = docker scout cves $ImageName --format json 2>&1

                if ($LASTEXITCODE -ne 0 -and $output -match "command not found") {
                    throw "Docker Scout plugin not installed. Run: docker scout --version"
                }

                # Docker Scout may return exit code 1 if vulnerabilities found (expected)
                if ($output) {
                    try {
                        $output | ConvertFrom-Json
                    } catch {
                        # If JSON parsing fails, Docker Scout might not be available
                        Write-Warning "Docker Scout returned non-JSON output. Might not be available on this Docker version."
                        Write-Warning "Output: $output"
                        return $null
                    }
                } else {
                    $null
                }
            }
            "snyk" {
                Write-Verbose "Running: snyk container test $ImageName --json"
                $output = snyk container test $ImageName --json 2>&1

                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
                    # Exit code 1 = vulnerabilities found (expected)
                    throw "Snyk failed with exit code $LASTEXITCODE: $output"
                }

                if ($output) {
                    $output | ConvertFrom-Json
                } else {
                    $null
                }
            }
            "trivy" {
                Write-Verbose "Running: trivy image --format json $ImageName"
                $output = trivy image --format json $ImageName 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "Trivy failed: $output"
                }

                if ($output) {
                    $output | ConvertFrom-Json
                } else {
                    $null
                }
            }
        }

        # Parse scanner-specific format
        if ($scanResult) {
            $vulnerabilities = Parse-ScannerOutput -Scanner $Scanner -ScanResult $scanResult

            # Count by severity
            foreach ($vuln in $vulnerabilities) {
                switch ($vuln.Severity.ToLower()) {
                    "critical" { $summary.critical++ }
                    "high" { $summary.high++ }
                    "medium" { $summary.medium++ }
                    "low" { $summary.low++ }
                }
            }
        }

        # Build report
        $report = [PSCustomObject]@{
            ImageName = $ImageName
            Scanner = $Scanner
            ScanDate = Get-Date -Format "o"
            Vulnerabilities = $vulnerabilities
            Summary = $summary
            TotalCount = $vulnerabilities.Count
            Status = if ($vulnerabilities.Count -eq 0) { "clean" } else { "vulnerabilities_found" }
        }

        # Check if should fail
        $shouldFail = $false
        switch ($FailOnSeverity.ToLower()) {
            "critical" {
                $shouldFail = $summary.critical -gt 0
            }
            "high" {
                $shouldFail = ($summary.critical -gt 0 -or $summary.high -gt 0)
            }
            "medium" {
                $shouldFail = ($summary.critical -gt 0 -or $summary.high -gt 0 -or $summary.medium -gt 0)
            }
            "low" {
                $shouldFail = $report.TotalCount -gt 0
            }
            "none" {
                $shouldFail = $false
            }
        }

        if ($shouldFail) {
            $errorMsg = "CVE scan failed for ${ImageName}: Found $($summary.critical) critical, $($summary.high) high, $($summary.medium) medium, $($summary.low) low vulnerabilities (threshold: $FailOnSeverity)"
            throw $errorMsg
        }

        # Return in requested format
        if ($OutputFormat -eq "json") {
            return $report | ConvertTo-Json -Depth 10
        } else {
            return $report
        }

    } catch {
        Write-Error "CVE scan failed for ${ImageName}: $_"
        throw
    }
}

function Parse-ScannerOutput {
    <#
    .SYNOPSIS
        Parse scanner-specific output to normalized format
    #>
    param(
        [string]$Scanner,
        [object]$ScanResult
    )

    $normalized = @()

    switch ($Scanner) {
        "docker-scout" {
            # Docker Scout format (example - adjust based on actual output)
            if ($ScanResult.vulnerabilities) {
                foreach ($vuln in $ScanResult.vulnerabilities) {
                    $normalized += [PSCustomObject]@{
                        CVE = $vuln.id
                        Severity = $vuln.severity
                        Package = $vuln.package
                        InstalledVersion = $vuln.installedVersion
                        FixedVersion = $vuln.fixedVersion
                        Description = $vuln.description
                    }
                }
            }
        }
        "snyk" {
            # Snyk format
            if ($ScanResult.vulnerabilities) {
                foreach ($vuln in $ScanResult.vulnerabilities) {
                    $normalized += [PSCustomObject]@{
                        CVE = $vuln.id
                        Severity = $vuln.severity
                        Package = $vuln.packageName
                        InstalledVersion = $vuln.version
                        FixedVersion = if ($vuln.fixedIn) { $vuln.fixedIn[0] } else { "none" }
                        Description = $vuln.title
                    }
                }
            }
        }
        "trivy" {
            # Trivy format
            if ($ScanResult.Results) {
                foreach ($result in $ScanResult.Results) {
                    if ($result.Vulnerabilities) {
                        foreach ($vuln in $result.Vulnerabilities) {
                            $normalized += [PSCustomObject]@{
                                CVE = $vuln.VulnerabilityID
                                Severity = $vuln.Severity
                                Package = $vuln.PkgName
                                InstalledVersion = $vuln.InstalledVersion
                                FixedVersion = $vuln.FixedVersion
                                Description = $vuln.Title
                            }
                        }
                    }
                }
            }
        }
    }

    return $normalized
}
