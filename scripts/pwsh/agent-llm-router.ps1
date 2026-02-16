param(
    [string]$Agent = "user",
    [string]$Preference = "",
    [string]$DecisionProfile = "",
    [int]$Rating = 0,
    [string]$Comment = "",
    [switch]$PlanOnly,
    [string]$RagEvidenceId = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

# --- INTERACTIVE WIZARD START ---
if ($Action -eq "invoke" -and [string]::IsNullOrWhiteSpace($Prompt) -and -not $MyInvocation.ExpectingInput) {
    Write-Host "`n=== EasyWay Agent Router (Wizard) ===`n" -ForegroundColor Cyan

    # 1. Select Agent
    $agentsDir = Join-Path $PSScriptRoot "..\..\agents"
    $agents = Get-ChildItem -Path $agentsDir -Directory | Where-Object { $_.Name -notin "core", "logs", "templates", "kb" }
    
    Write-Host "Available Agents:" -ForegroundColor Gray
    for ($i = 0; $i -lt $agents.Count; $i++) {
        Write-Host "  [$($i+1)] $($agents[$i].Name)"
    }
    
    $agentIdx = Read-Host "`nSelect Agent (1-$($agents.Count)) [Default: user]"
    if ([string]::IsNullOrWhiteSpace($agentIdx)) {
        $Agent = "user"    
    }
    elseif ($agentIdx -match "^\d+$" -and [int]$agentIdx -le $agents.Count) {
        $Agent = $agents[[int]$agentIdx - 1].Name
    }
    else {
        $Agent = $agentIdx # Allow custom name typing
    }
    Write-Host "Selected: $Agent" -ForegroundColor Green

    # 2. Select Preference Profile
    Write-Host "`nPreference Profile:" -ForegroundColor Gray
    Write-Host "  [1] speed_first (Cheap/Fast)"
    Write-Host "  [2] privacy_first (Local Only)"
    Write-Host "  [3] cost_balanced (Best Value)"
    
    $profIdx = Read-Host "`nSelect Profile [Default: None/Standard]"
    switch ($profIdx) {
        "1" { $Preference = "speed_first" }
        "2" { $Preference = "privacy_first" }
        "3" { $Preference = "cost_balanced" }
        default { $Preference = "" }
    }
    if ($Preference) { Write-Host "Selected: $Preference" -ForegroundColor Green }

    # 3. Decision Profile
    $profilesDir = Join-Path $PSScriptRoot "..\..\agents\config\decision-profiles"
    if (Test-Path $profilesDir) {
        $profiles = Get-ChildItem -Path $profilesDir -Filter "*.json" | ForEach-Object { $_.BaseName }
        if ($profiles.Count -gt 0) {
            Write-Host "`nDecision Profile (Risk Appetite):" -ForegroundColor Gray
            for ($i = 0; $i -lt $profiles.Count; $i++) {
                $pData = Get-Content (Join-Path $profilesDir "$($profiles[$i]).json") -Raw | ConvertFrom-Json
                Write-Host "  [$($i+1)] $($profiles[$i]) — $($pData.risk_level) (auto < `$$($pData.auto_approve_threshold_usd))"
            }
            $dpIdx = Read-Host "`nSelect Decision Profile [Enter = None]"
            if ($dpIdx -match '^\d+$' -and [int]$dpIdx -le $profiles.Count -and [int]$dpIdx -ge 1) {
                $DecisionProfile = $profiles[[int]$dpIdx - 1]
                Write-Host "Selected: $DecisionProfile" -ForegroundColor Green
            }
        }
    }

    # 4. Enter Prompt
    Write-Host "`nPrompt:" -ForegroundColor Gray
    $inputPrompt = Read-Host "> "
    if ([string]::IsNullOrWhiteSpace($inputPrompt)) {
        Write-Warning "No prompt provided. Exiting."
        exit
    }
    $Prompt = $inputPrompt
    
    Write-Host "`nRunning: agent-llm-router -Agent $Agent -Profile '$Preference' -DecisionProfile '$DecisionProfile' ...`n" -ForegroundColor DarkGray
}
# --- INTERACTIVE WIZARD END ---

$target = Join-Path $PSScriptRoot "..\..\agents\core\tools\agent-llm-router.ps1"
if (-not (Test-Path -LiteralPath $target)) {
    throw "Canonical script not found: $target"
}

& pwsh -NoProfile -File $target @ForwardArgs
exit $LASTEXITCODE
