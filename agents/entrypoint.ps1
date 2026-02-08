# entrypoint.ps1 - EasyWay Agent Runner entrypoint
# Keeps the container alive and ready to execute agents on-demand
# Triggered by: n8n webhooks, docker exec, or scheduled tasks

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " EasyWay Agent Runner v2.0"              -ForegroundColor Cyan
Write-Host " Mode: $env:EASYWAY_MODE"                -ForegroundColor Cyan
Write-Host " Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Verify environment
$checks = @(
    @{ Name = "PowerShell"; Check = { $PSVersionTable.PSVersion.ToString() } },
    @{ Name = "Node.js"; Check = { node -v 2>$null } },
    @{ Name = "Python3"; Check = { python3 --version 2>$null } },
    @{ Name = "Git"; Check = { git --version 2>$null } }
)

foreach ($c in $checks) {
    try {
        $ver = & $c.Check
        Write-Host "  [OK] $($c.Name): $ver" -ForegroundColor Green
    }
    catch {
        Write-Host "  [!!] $($c.Name): not available" -ForegroundColor Yellow
    }
}

# Check agent manifests
$manifests = Get-ChildItem -Path /app/agents/agent_*/manifest.json -ErrorAction SilentlyContinue
$level2 = $manifests | ForEach-Object {
    $m = Get-Content $_.FullName -Raw | ConvertFrom-Json
    if ($m.evolution_level -ge 2) { $m.name }
}
Write-Host ""
Write-Host "  Agents loaded: $($manifests.Count)" -ForegroundColor White
Write-Host "  Level 2 (LLM): $($level2.Count) [$(@($level2) -join ', ')]" -ForegroundColor White
Write-Host ""

# Health check endpoint file (for Docker HEALTHCHECK)
$healthFile = "/tmp/runner-health"
"ok" | Set-Content $healthFile

Write-Host "Runner ready. Waiting for agent execution requests..." -ForegroundColor Green
Write-Host "Use 'docker exec easyway-runner pwsh /app/scripts/pwsh/<agent>.ps1' to run agents." -ForegroundColor DarkGray

# Keep alive: sleep loop with periodic health update
while ($true) {
    "ok $(Get-Date -Format 'HH:mm:ss')" | Set-Content $healthFile
    Start-Sleep -Seconds 30
}
