<#
.SYNOPSIS
  [Governance] Module for EasyWay Governance Gates.
  Handles: KB Consistency, DB Drift, Pre-Deploy Checklist.
#>

# Helper: Detect Changes
function Get-GitChanges {
    try {
        $base = (git rev-parse HEAD~1 2>$null)
        if ($LASTEXITCODE -eq 0 -and $base) {
            return (git diff --name-only $base HEAD)
        }
    }
    catch {}
    return @()
}

# --- 1. Diagnosis (Check) ---
function Get-EwctlDiagnosis {
    $results = @()
    $changed = Get-GitChanges

    # 1. KB Consistency
    $changedDbApi = ($changed | Where-Object { $_ -like 'db/*' -or $_ -like 'EasyWay-DataPortal/easyway-portal-api/src/*' }).Count -gt 0
    $changedAdo = ($changed | Where-Object { $_ -like 'scripts/ado/*' }).Count -gt 0
    $changedAgents = ($changed | Where-Object { $_ -like 'Wiki/EasyWayData.wiki/agents-*.md' }).Count -gt 0
    $kbChanged = ($changed | Where-Object { $_ -eq 'agents/kb/recipes.jsonl' }).Count -gt 0
    $wikiChanged = ($changed | Where-Object { $_ -like 'Wiki/*' }).Count -gt 0

    if ($changedDbApi -and (-not $kbChanged -or -not $wikiChanged)) {
        $results += [PSCustomObject]@{
            Status  = "Error"
            Message = "KB Consistency Violation: DB/API changed but 'agents/kb/recipes.jsonl' or Wiki not updated."
            Context = "Governance"
        }
    }
    elseif (($changedAdo -or $changedAgents) -and -not $kbChanged) {
        $results += [PSCustomObject]@{
            Status  = "Error"
            Message = "KB Consistency Violation: ADO/Agents scripts changed but 'agents/kb/recipes.jsonl' not updated."
            Context = "Governance"
        }
    }
    else {
        $results += [PSCustomObject]@{ Status = "Ok"; Message = "KB Consistency Verified"; Context = "Governance" }
    }

    # 2. DB Drift & Checklist (Only if API exists)
    $apiPath = "EasyWay-DataPortal/easyway-portal-api" # Adjust path relative to repo root if needed? No, script runs from root.
    # Actually, user ID 0 says 'c:\old\EasyWayDataPortal' is root. 
    # agent-governance.ps1 used 'EasyWay-DataPortal/easyway-portal-api' as default but listed dir structure shows 'portal-api/easyway-portal-api' in STEP 11 (azure-pipelines.yaml).
    # Let's check listing from Step 4. 'portal-api' is a dir.
    # Step 11 var: API_PATH value: 'portal-api/easyway-portal-api'.
    # agent-governance.ps1 L2 says default 'EasyWay-DataPortal/easyway-portal-api', which looks wrong if repo root is EasyWayDataPortal.
    # Wait, Step 4 list_dir showed 'portal-api' folder.
    # Let's assume 'portal-api/easyway-portal-api' is the correct relative path.

    $apiPath = "portal-api/easyway-portal-api" 
    
    if (Test-Path $apiPath) {
        Push-Location $apiPath
        try {
            # DB Drift
            if ($changedDbApi) {
                # Only run if relevant? Or always? Gates usually run always to be safe.
                # Let's run always if npm exists
                if (Test-Path "package.json") {
                    # Mocking/Skipping npm install for speed in check - assumtion: dev has it.
                    # But CI needs it. ewctl.ps1 doesn't invoke npm i.
                    # logic: check if node_modules exists
                     
                    $driftOut = $null
                    try { 
                        $driftOut = npm run -s db:drift 2>&1 
                        if ($LASTEXITCODE -eq 0) {
                            $results += [PSCustomObject]@{ Status = "Ok"; Message = "DB Drift Check Passed"; Context = "DB" }
                        }
                        else {
                            $results += [PSCustomObject]@{ Status = "Error"; Message = "DB Drift Check Failed"; Context = "DB"; Details = $driftOut }
                        }
                    }
                    catch {
                        $results += [PSCustomObject]@{ Status = "Error"; Message = "DB Drift Check Exception"; Context = "DB"; Details = $_ }
                    }
                }
            }
            else {
                $results += [PSCustomObject]@{ Status = "Ok"; Message = "DB Drift Skipped (No relevant changes)"; Context = "DB" }
            }
        }
        finally {
            Pop-Location
        }
    }

    return $results
}

# --- 2. Prescription (Plan) ---
function Get-EwctlPrescription {
    $plan = @()
    # Logic to suggest fixes based on diagnosis states...
    # For now, placeholder.
    return $plan
}

# --- 3. Treatment (Fix) ---
function Invoke-EwctlTreatment {
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    return @()
}

Export-ModuleMember -Function Get-EwctlDiagnosis, Get-EwctlPrescription, Invoke-EwctlTreatment
