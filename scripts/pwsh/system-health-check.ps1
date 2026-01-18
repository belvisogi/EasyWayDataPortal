
$ErrorActionPreference = 'Stop'
Write-Host "🏥 System Health Check (Measure Twice)..." -ForegroundColor Cyan

$root = "$PSScriptRoot/../.." # Assuming scripts/pwsh/
$agentsDir = Join-Path $root "agents"
$errors = 0

# 1. Structural Checks
Write-Host "1. Checking Structure..." -ForegroundColor Yellow
if (-not (Test-Path "$root/scripts/pwsh/core/AgentMemory.psm1")) {
    Write-Host "  [FAIL] Core Memory Module missing!" -ForegroundColor Red
    $errors++
} else {
    Write-Host "  [PASS] Core Memory Module found." -ForegroundColor Green
}

# 2. Memory Cortex Checks
Write-Host "2. Checking Memory Cortex..." -ForegroundColor Yellow
$agents = Get-ChildItem $agentsDir -Directory | Where-Object { $_.Name -notin @('kb','logs','core') }
foreach ($a in $agents) {
    $mem = Join-Path $a.FullName "memory/context.json"
    if (-not (Test-Path $mem)) {
        Write-Host "  [FAIL] $($a.Name): Missing context.json" -ForegroundColor Red
        $errors++
    } else {
        # Check Brains
        if ($a.Name -in @('agent_governance','agent_scrummaster')) {
            $json = Get-Content $mem -Raw | ConvertFrom-Json
            if (-not $json.brain_context) {
                Write-Host "  [FAIL] $($a.Name): Missing 'brain_context' (Brain Cortex faulty)" -ForegroundColor Red
                $errors++
            } else {
                 Write-Host "  [PASS] $($a.Name): Brain Active." -ForegroundColor Green
            }
        }
    }
}

# 3. GEDI Sanity Check
Write-Host "3. GEDI Pulse Check..." -ForegroundColor Yellow
$gediScript = "$root/scripts/pwsh/agent-gedi.ps1"
if (-not (Test-Path $gediScript)) {
    Write-Host "  [FAIL] GEDI Script missing at new location!" -ForegroundColor Red
    $errors++
} else {
     Write-Host "  [PASS] GEDI Script located." -ForegroundColor Green
}

# 4. Manifest Audit (Delegated)
Write-Host "4. Running Audit Agent..." -ForegroundColor Yellow
$auditRes = pwsh "$root/scripts/pwsh/agents-manifest-audit.ps1" -OutJson "$root/out/health-check-audit.json" | ConvertFrom-Json
if (-not $auditRes.ok) {
     Write-Host "  [FAIL] Audit found $($auditRes.errorsCount) errors!" -ForegroundColor Red
     $errors += $auditRes.errorsCount
} else {
     Write-Host "  [PASS] Audit Clean." -ForegroundColor Green
}

Write-Host "---" -ForegroundColor Gray
if ($errors -eq 0) {
    Write-Host "✅ SYSTEM HEALTHY. Ready to Cut." -ForegroundColor Green
} else {
    Write-Host "❌ SYSTEM UNHEALTHY. $errors errors found." -ForegroundColor Red
    exit 1
}
