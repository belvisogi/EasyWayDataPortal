# Pre-Flight Validation Script
# Run this BEFORE deployment to ensure everything is ready

Param(
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'
$script:FailCount = 0
$script:PassCount = 0

function Test-Check {
    param(
        [string]$Name,
        [scriptblock]$Check,
        [string]$FailMessage
    )
  
    Write-Host "`n[TEST] $Name" -ForegroundColor Cyan
  
    try {
        $result = & $Check
        if ($result) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $script:PassCount++
            return $true
        }
        else {
            Write-Host "  ❌ FAIL: $FailMessage" -ForegroundColor Red
            $script:FailCount++
            return $false
        }
    }
    catch {
        Write-Host "  ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $script:FailCount++
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  AGENT CHAT PRE-FLIGHT VALIDATION" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Test 1: Flyway migrations exist
Test-Check "Flyway Migration V_100 exists" {
    Test-Path "db/flyway/sql/V_100__create_agent_conversations.sql"
} "File not found: db/flyway/sql/V_100__create_agent_conversations.sql"

Test-Check "Flyway Migration V_101 exists" {
    Test-Path "db/flyway/sql/V_101__stored_procedures_agent_chat.sql"
} "File not found: db/flyway/sql/V_101__stored_procedures_agent_chat.sql"

# Test 2: Backend files exist
Test-Check "Agent Chat Routes exist" {
    Test-Path "EasyWay-DataPortal/easyway-portal-api/src/routes/agent-chat.ts"
} "File not found: routes/agent-chat.ts"

Test-Check "Agent Chat Service exists" {
    Test-Path "EasyWay-DataPortal/easyway-portal-api/src/services/agent-chat.service.ts"
} "File not found: services/agent-chat.service.ts"

Test-Check "Security Middleware exists" {
    Test-Path "EasyWay-DataPortal/easyway-portal-api/src/middleware/security.ts"
} "File not found: middleware/security.ts"

# Test 3: SQL Syntax validation
Test-Check "V_100 SQL Syntax" {
    $sql = Get-Content "db/flyway/sql/V_100__create_agent_conversations.sql" -Raw
    # Basic syntax checks
    $sql -match "CREATE TABLE" -and 
    $sql -match "agent_conversations" -and 
    $sql -match "agent_messages"
} "SQL syntax issues in V_100"

Test-Check "V_101 SQL Syntax (SP count)" {
    $sql = Get-Content "db/flyway/sql/V_101__stored_procedures_agent_chat.sql" -Raw
    # Check all 5 SPs present
    ($sql -split "CREATE OR ALTER PROCEDURE").Count -eq 6  # 5 SPs + 1 header
} "Expected 5 stored procedures in V_101"

# Test 4: TypeScript compilation check (if tsc available)
if (Get-Command tsc -ErrorAction SilentlyContinue) {
    Test-Check "TypeScript Compilation (dry-run)" {
        Push-Location "EasyWay-DataPortal/easyway-portal-api"
        $output = tsc --noEmit 2>&1
        Pop-Location
        $LASTEXITCODE -eq 0
    } "TypeScript compilation errors found"
}
else {
    Write-Host "`n[SKIP] TypeScript compilation (tsc not found)" -ForegroundColor Yellow
}

# Test 5: Security scripts exist
Test-Check "Input validation script exists" {
    Test-Path "scripts/validate-agent-input.ps1"
} "File not found: scripts/validate-agent-input.ps1"

Test-Check "Output validation script exists" {
    Test-Path "scripts/validate-agent-output.ps1"
} "File not found: scripts/validate-agent-output.ps1"

# Test 6: Route registration check
Test-Check "Route registered in app.ts" {
    $appTs = Get-Content "EasyWay-DataPortal/easyway-portal-api/src/app.ts" -Raw
    $appTs -match "import.*agentChatRouter.*from.*agent-chat" -and
    $appTs -match "app\.use.*agentChatRouter"
} "agentChatRouter not registered in app.ts"

# Test 7: Dependencies check (package.json)
Test-Check "package.json has required dependencies" {
    $pkg = Get-Content "EasyWay-DataPortal/easyway-portal-api/package.json" | ConvertFrom-Json
    $deps = $pkg.dependencies
    $deps.express -and $deps.mssql -and $deps.winston
} "Missing required npm dependencies"

# Test 8: Documentation exists
Test-Check "Deployment guide exists" {
    Test-Path "docs/deployment/agent-chat-deployment-guide.md"
} "Deployment guide not found"

# Summary
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "  VALIDATION SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  ✅ Passed: $script:PassCount" -ForegroundColor Green
Write-Host "  ❌ Failed: $script:FailCount" -ForegroundColor Red

if ($script:FailCount -eq 0) {
    Write-Host "`n🎉 ALL CHECKS PASSED! Ready for deployment." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n⚠️  VALIDATION FAILED. Fix issues before deployment." -ForegroundColor Red
    exit 1
}
