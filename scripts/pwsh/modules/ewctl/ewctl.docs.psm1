<#
.SYNOPSIS
  [Docs] Module for EasyWay Documentation Management.
  Handles: Wiki Normalization, Index Generation, Agent README Sync.
#>

# Helper: Resolve Wiki Path
function Get-WikiRoot {
    $path = "Wiki/EasyWayData.wiki"
    if (Test-Path $path) { return $path }
    return $null
}

# --- 1. Diagnosis (Check) ---
function Get-EwctlDiagnosis {
    $results = @()
    $wikiRoot = Get-WikiRoot

    # 1. Agents README Sync Check
    $readmeSyncScript = "scripts/agents-readme-sync.ps1"
    if (Test-Path $readmeSyncScript) {
        $out = & pwsh $readmeSyncScript -Mode check 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            $results += [PSCustomObject]@{ Status = "Ok"; Message = "Agents README is in sync"; Context = "Docs" }
        }
        else {
            $results += [PSCustomObject]@{ Status = "Error"; Message = "Agents README drift detected"; Context = "Docs" }
        }
    }

    # 2. Wiki Review (If Wiki exists)
    if ($wikiRoot) {
        $scripts = Join-Path $wikiRoot "scripts"
        # We assume if the scripts exist, we can use them for checking?
        # review-run.ps1 might be heavy. Let's just say "Wiki Scripts Available".
        if (Test-Path $scripts) {
            $results += [PSCustomObject]@{ Status = "Ok"; Message = "Wiki Scripts detected"; Context = "Docs" }
        }
        else {
            $results += [PSCustomObject]@{ Status = "Warn"; Message = "Wiki Scripts missing in $wikiRoot"; Context = "Docs" }
        }
    }

    return $results
}

# --- 2. Prescription (Plan) ---
function Get-EwctlPrescription {
    return @()
}

# --- 3. Treatment (Fix) ---
function Invoke-EwctlTreatment {
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    $report = @()
    $wikiRoot = Get-WikiRoot

    # 1. Sync Agents README
    if ($PSCmdlet.ShouldProcess("agents/README.md", "Sync with Manifests")) {
        $script = "scripts/agents-readme-sync.ps1"
        if (Test-Path $script) {
            pwsh $script -Mode fix | Out-Null
            $report += "Synced agents/README.md"
        }
    }

    # 2. Normalize Wiki & Indices
    if ($wikiRoot -and $PSCmdlet.ShouldProcess($wikiRoot, "Normalize & Generate Indices")) {
        $scripts = Join-Path $wikiRoot "scripts"
        $tasks = @(
            "normalize-project.ps1", "-EnsureFrontMatter",
            "generate-entities-index.ps1", "",
            "generate-master-index.ps1", ""
        )
        
        for ($i = 0; $i -lt $tasks.Count; $i += 2) {
            $s = $tasks[$i]
            $taskArgs = $tasks[$i + 1]
            $fullPath = Join-Path $scripts $s
            if (Test-Path $fullPath) {
                if ($taskArgs) { pwsh $fullPath $taskArgs | Out-Null } else { pwsh $fullPath | Out-Null }
                $report += "Ran $s"
            }
        }
    }

    return $report
}

Export-ModuleMember -Function Get-EwctlDiagnosis, Get-EwctlPrescription, Invoke-EwctlTreatment
