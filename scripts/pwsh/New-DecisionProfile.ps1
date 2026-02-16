<#
.SYNOPSIS
    Interactive wizard to create a Decision Profile for EasyWay agents.

.DESCRIPTION
    Guides business users through defining their "Risk Appetite" via a CLI menu.
    Saves the profile as a validated JSON file under agents/config/decision-profiles/.

.EXAMPLE
    .\New-DecisionProfile.ps1
    .\New-DecisionProfile.ps1 -Name "team-finance" -RiskLevel moderate

.NOTES
    Phase: P3 - Workflow Intelligence
    Version: 1.0.0
#>
param(
    [string]$Name,
    [ValidateSet("conservative", "moderate", "aggressive")]
    [string]$RiskLevel,
    [double]$Threshold,
    [string]$EscalationChannel
)

$ErrorActionPreference = "Stop"

$profilesDir = Join-Path $PSScriptRoot "..\..\agents\config\decision-profiles"
if (-not (Test-Path $profilesDir)) {
    New-Item -Path $profilesDir -ItemType Directory -Force | Out-Null
}

$allActions = @("read", "summarize", "query", "write", "delete", "deploy", "create", "update")

# ── Defaults by Risk Level ──
$riskDefaults = @{
    conservative = @{
        Threshold         = 0
        RequireReview     = $allActions
        AllowWithout      = @()
        MaxConcurrent     = 1
        EscalationChannel = "console"
    }
    moderate     = @{
        Threshold         = 100
        RequireReview     = @("delete", "deploy")
        AllowWithout      = @("read", "summarize", "query", "write", "create", "update")
        MaxConcurrent     = 5
        EscalationChannel = "slack:#approvals"
    }
    aggressive   = @{
        Threshold         = 1000
        RequireReview     = @("deploy")
        AllowWithout      = @("read", "summarize", "query", "write", "delete", "create", "update")
        MaxConcurrent     = 20
        EscalationChannel = "slack:#ops-alerts"
    }
}

# ══════════════════════════════════════════
# INTERACTIVE WIZARD (if params missing)
# ══════════════════════════════════════════

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   EasyWay Decision Profile Wizard        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 1. Profile Name
if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Host "Step 1/5 — Profile Name" -ForegroundColor Yellow
    Write-Host "  Use lowercase, dashes/underscores only (e.g., 'team-finance')" -ForegroundColor Gray
    $Name = Read-Host "  > Name"
    if ($Name -notmatch '^[a-z0-9_-]+$') {
        Write-Error "Invalid name: '$Name'. Use lowercase alphanumeric, dashes, underscores."
        exit 1
    }
}
Write-Host "  ✔ Profile: $Name" -ForegroundColor Green

# 2. Risk Level
if ([string]::IsNullOrWhiteSpace($RiskLevel)) {
    Write-Host "`nStep 2/5 — Risk Level" -ForegroundColor Yellow
    Write-Host "  [1] conservative  — All actions need approval. Zero auto-approve." -ForegroundColor Gray
    Write-Host "  [2] moderate      — Auto-approve < `$100. Delete/Deploy need review." -ForegroundColor Gray
    Write-Host "  [3] aggressive    — Auto-approve < `$1000. Only Deploy needs review." -ForegroundColor Gray
    $sel = Read-Host "  > Select (1-3)"
    $RiskLevel = switch ($sel) {
        "1" { "conservative" }
        "2" { "moderate" }
        "3" { "aggressive" }
        default { Write-Error "Invalid selection: $sel"; exit 1 }
    }
}
$defaults = $riskDefaults[$RiskLevel]
Write-Host "  ✔ Risk: $RiskLevel" -ForegroundColor Green

# 3. Dollar Threshold
if ($null -eq $Threshold -or $Threshold -lt 0) {
    if ($PSBoundParameters.ContainsKey('Threshold') -and $Threshold -ge 0) {
        # param was provided
    }
    else {
        Write-Host "`nStep 3/5 — Auto-Approve Threshold (USD)" -ForegroundColor Yellow
        Write-Host "  Actions costing less than this amount are auto-approved." -ForegroundColor Gray
        Write-Host "  Default for '$RiskLevel': `$$($defaults.Threshold)" -ForegroundColor Gray
        $thresholdInput = Read-Host "  > Threshold [Enter = default]"
        if ([string]::IsNullOrWhiteSpace($thresholdInput)) {
            $Threshold = $defaults.Threshold
        }
        else {
            $Threshold = [double]$thresholdInput
        }
    }
}
Write-Host "  ✔ Threshold: `$$Threshold" -ForegroundColor Green

# 4. Actions Requiring Review (multi-select)
Write-Host "`nStep 4/5 — Actions Requiring Human Review" -ForegroundColor Yellow
Write-Host "  Default for '$RiskLevel': $($defaults.RequireReview -join ', ')" -ForegroundColor Gray
Write-Host "  Available: $($allActions -join ', ')" -ForegroundColor Gray
$reviewInput = Read-Host "  > Comma-separated list [Enter = default]"
if ([string]::IsNullOrWhiteSpace($reviewInput)) {
    $requireReview = $defaults.RequireReview
    $allowWithout = $defaults.AllowWithout
}
else {
    $requireReview = $reviewInput -split ',' | ForEach-Object { $_.Trim().ToLower() }
    $allowWithout = $allActions | Where-Object { $_ -notin $requireReview }
}
Write-Host "  ✔ Review: $($requireReview -join ', ')" -ForegroundColor Green

# 5. Escalation Channel
if ([string]::IsNullOrWhiteSpace($EscalationChannel)) {
    Write-Host "`nStep 5/5 — Escalation Channel" -ForegroundColor Yellow
    Write-Host "  Examples: console, slack:#channel, email:team@co.com" -ForegroundColor Gray
    Write-Host "  Default for '$RiskLevel': $($defaults.EscalationChannel)" -ForegroundColor Gray
    $EscalationChannel = Read-Host "  > Channel [Enter = default]"
    if ([string]::IsNullOrWhiteSpace($EscalationChannel)) {
        $EscalationChannel = $defaults.EscalationChannel
    }
}
Write-Host "  ✔ Escalation: $EscalationChannel" -ForegroundColor Green

# ══════════════════════════════════════════
# BUILD & SAVE PROFILE
# ══════════════════════════════════════════

$profileData = [ordered]@{
    name                             = $Name
    risk_level                       = $RiskLevel
    auto_approve_threshold_usd       = $Threshold
    require_human_review             = @($requireReview)
    allowed_actions_without_approval = @($allowWithout)
    escalation_channel               = $EscalationChannel
    max_concurrent_auto_actions      = $defaults.MaxConcurrent
    created_at                       = (Get-Date -Format "o")
    created_by                       = $env:USERNAME
}

$outPath = Join-Path $profilesDir "$Name.json"

if (Test-Path $outPath) {
    Write-Warning "Profile '$Name' already exists at: $outPath"
    $overwrite = Read-Host "  Overwrite? (y/N)"
    if ($overwrite -ne 'y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

$profileData | ConvertTo-Json -Depth 5 | Set-Content -Path $outPath -Encoding utf8

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Decision Profile Saved              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "  File: $outPath" -ForegroundColor Gray
Write-Host "  Use:  agent-llm-router.ps1 -DecisionProfile $Name`n" -ForegroundColor Gray
