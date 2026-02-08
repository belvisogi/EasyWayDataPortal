<#
.SYNOPSIS
    Check health of Docker containers and services

.DESCRIPTION
    Performs health checks on running containers and services.
    Returns structured health report with status per component.

.PARAMETER Target
    Target to check: "all", "containers", "services", or specific container name

.PARAMETER Timeout
    Timeout in seconds for each check (default: 10)

.EXAMPLE
    Invoke-HealthCheck -Target "all"

.EXAMPLE
    Invoke-HealthCheck -Target "easyway-db"
#>
function Invoke-HealthCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Target = "all",

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 10
    )

    try {
        $checks = @()
        $startTime = Get-Date

        if ($Target -eq "all" -or $Target -eq "containers") {
            # Check Docker containers
            $containers = docker ps --format "{{.Names}}|{{.Status}}|{{.Image}}" 2>&1
            if ($LASTEXITCODE -eq 0) {
                foreach ($line in $containers) {
                    $parts = $line -split '\|'
                    if ($parts.Count -ge 3) {
                        $status = $parts[1]
                        $healthy = $status -match "healthy" -or ($status -match "^Up" -and $status -notmatch "unhealthy")

                        $checks += [PSCustomObject]@{
                            Component = $parts[0]
                            Type = "container"
                            Image = $parts[2]
                            Status = $status
                            Healthy = $healthy
                            CheckedAt = Get-Date -Format "o"
                        }
                    }
                }
            }
        } elseif ($Target -ne "services") {
            # Check specific container
            $inspect = docker inspect $Target --format "{{.State.Status}}|{{.State.Health.Status}}" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $parts = $inspect -split '\|'
                $checks += [PSCustomObject]@{
                    Component = $Target
                    Type = "container"
                    Status = $parts[0]
                    HealthStatus = if ($parts.Count -gt 1) { $parts[1] } else { "no-healthcheck" }
                    Healthy = $parts[0] -eq "running"
                    CheckedAt = Get-Date -Format "o"
                }
            }
        }

        if ($Target -eq "all" -or $Target -eq "services") {
            # Check key service ports
            $services = @(
                @{ Name = "API"; Port = 3000; Path = "/health" },
                @{ Name = "Qdrant"; Port = 6333; Path = "/collections" },
                @{ Name = "n8n"; Port = 5678; Path = "/" }
            )

            foreach ($svc in $services) {
                try {
                    $response = curl -s -o /dev/null -w "%{http_code}" --max-time $Timeout "http://localhost:$($svc.Port)$($svc.Path)" 2>&1
                    $checks += [PSCustomObject]@{
                        Component = $svc.Name
                        Type = "service"
                        Port = $svc.Port
                        HttpStatus = $response
                        Healthy = $response -match "^[23]"
                        CheckedAt = Get-Date -Format "o"
                    }
                } catch {
                    $checks += [PSCustomObject]@{
                        Component = $svc.Name
                        Type = "service"
                        Port = $svc.Port
                        HttpStatus = "error"
                        Healthy = $false
                        Error = $_.Exception.Message
                        CheckedAt = Get-Date -Format "o"
                    }
                }
            }
        }

        $duration = (Get-Date) - $startTime
        $healthyCount = ($checks | Where-Object { $_.Healthy }).Count

        return [PSCustomObject]@{
            Target = $Target
            TotalChecks = $checks.Count
            Healthy = $healthyCount
            Unhealthy = $checks.Count - $healthyCount
            OverallStatus = if ($healthyCount -eq $checks.Count) { "healthy" } else { "degraded" }
            Duration = "$([math]::Round($duration.TotalSeconds, 2))s"
            Checks = $checks
            CheckedAt = Get-Date -Format "o"
        }

    } catch {
        Write-Error "Health check failed: $_"
        throw
    }
}
