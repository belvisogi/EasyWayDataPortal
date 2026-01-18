
$ErrorActionPreference = 'Stop'
Write-Host "🪤 OODA Trap Simulation..." -ForegroundColor Cyan

# Mock Context
$script = "scripts/pwsh/agent-ado-scrummaster.ps1"

Write-Host "`n1. Triggering ScrumMaster OODA Loop..." -ForegroundColor Yellow
# We call with WhatIf to be safe, but GEDI should still be consulted before execution logic
# Note: GEDI check is at line 223, before the switch logic.
# We need to pass required params for 'ado:userstory.create' to avoid validation error, 
# OR just rely on GEDI being called early.
# Actually, looking at the script, GEDI is called early. 
# But we need to ensure the script doesn't fail on missing params before GEDI.
# The script reads params later inside the switch. So calling with just -Action should work?
# Wait, Params are defined at top.

try {
    # We use a dummy action that isn't read-only to trigger GEDI
    # 'ado:userstory.create' requires some inputs? No, strictly only if they are used.
    # But let's see. logic is: Read-Intent... Invoke-GediCheck... switch.
    # So if we don't provide IntentPath, Read-Intent returns null, $p is empty.
    # Then Invoke-GediCheck is called.
    
    & pwsh $script -Action 'ado:userstory.create' -WhatIf
    
} catch {
    Write-Host "Simulation Error: $_" -ForegroundColor Red
}

Write-Host "`n2. Triggering Governance OODA Loop..." -ForegroundColor Yellow
$govScript = "scripts/pwsh/agent-governance.ps1"
try {
    # Governance calls GEDI if -Checklist or -Interactive is set.
    # We use -WhatIf to avoid actual changes.
    & pwsh $govScript -Checklist -WhatIf
} catch {
    Write-Host "Simulation Error: $_" -ForegroundColor Red
}

Write-Host "`n--- Simulation Complete ---" -ForegroundColor Gray
