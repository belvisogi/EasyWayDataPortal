# verify-brains.ps1
# Smoke Test for Strategic Agents (OODA Integration)

$ErrorActionPreference = 'Stop'

function Test-Brain($name, $cmd) {
    Write-Host "`n🧠 Testing Brain: $name" -ForegroundColor Magenta
    Write-Host "   Command: $cmd" -ForegroundColor Gray
    try {
        $output = Invoke-Expression "$cmd 2>&1" | Out-String
        if ($output -match "GEDI Consultation") {
            Write-Host "   ✅ OODA Triggered (GEDI Consulted)" -ForegroundColor Green
        } else {
            Write-Host "   ❌ OODA Silent (GEDI NOT Consulted)" -ForegroundColor Red
            Write-Host $output -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "   ❌ CRASH: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 1. Governance
Test-Brain "agent_governance" "pwsh scripts/agent-governance.ps1 -Checklist -Interactive:`$false"

# 2. ScrumMaster
Test-Brain "agent_scrummaster" "pwsh scripts/agent-ado-scrummaster.ps1 -Action 'ado:userstory.create' -IntentPath 'agents/agent_template/intent_sample.json' -WhatIf"

# 3. DBA
# Create temporary intent for DBA
$dbaIntent = @{
    action = "db-table:create"
    params = @{
        database = "TestDB"
        tableName = "TestTable_OODA"
        columns = @(@{ name="Id"; type="int" })
        summaryOut = "out/db/test.json"
    }
} | ConvertTo-Json
$dbaFile = "out/dba-ooda-test.json"
Set-Content -Path $dbaFile -Value $dbaIntent

Test-Brain "agent_dba" "pwsh scripts/agent-dba.ps1 -Action 'db-table:create' -IntentPath '$dbaFile' -WhatIf"

# Cleanup
Remove-Item $dbaFile -ErrorAction SilentlyContinue
