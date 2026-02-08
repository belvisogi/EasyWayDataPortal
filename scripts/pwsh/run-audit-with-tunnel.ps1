<#
.SYNOPSIS
    Run agent audit with automatic SSH tunnel to Ollama

.DESCRIPTION
    Opens SSH tunnel to server's Ollama, runs audit, keeps tunnel alive

.PARAMETER Action
    Audit action: audit, fix, validate, report

.PARAMETER AgentId
    Agent to audit

.PARAMETER Fixes
    Fixes to apply (comma-separated)

.PARAMETER DryRun
    Preview changes without applying

.EXAMPLE
    pwsh run-audit-with-tunnel.ps1 -Action audit -AgentId agent_vulnerability_scanner
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("audit", "fix", "validate", "report")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$AgentId = "",

    [Parameter(Mandatory = $false)]
    [string]$Fixes = "",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

$SSHKey = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"
$SSHHost = "ubuntu@80.225.86.168"
$LocalPort = 11434
$RemotePort = 11434

Write-Host "🔧 Agent Audit with SSH Tunnel" -ForegroundColor Cyan
Write-Host ""

# Check if tunnel is already active
Write-Host "Checking if SSH tunnel is active..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "http://localhost:$LocalPort/api/tags" -Method GET -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✅ SSH tunnel already active" -ForegroundColor Green
    $tunnelWasActive = $true
} catch {
    Write-Host "⚠️  SSH tunnel not active, creating..." -ForegroundColor Yellow
    $tunnelWasActive = $false

    # Start SSH tunnel in background
    $sshArgs = @(
        "-i", $SSHKey,
        "-L", "${LocalPort}:localhost:${RemotePort}",
        "-N",  # No remote command
        "-f",  # Background
        $SSHHost
    )

    Write-Host "Executing: ssh $($sshArgs -join ' ')" -ForegroundColor Gray

    try {
        $process = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -NoNewWindow -PassThru -ErrorAction Stop

        # Wait for tunnel to be ready
        Write-Host "Waiting for tunnel to establish..." -ForegroundColor Yellow
        $maxAttempts = 10
        $attempt = 0
        $tunnelReady = $false

        while ($attempt -lt $maxAttempts) {
            Start-Sleep -Seconds 1
            $attempt++
            try {
                $null = Invoke-RestMethod -Uri "http://localhost:$LocalPort/api/tags" -Method GET -TimeoutSec 2 -ErrorAction Stop
                $tunnelReady = $true
                break
            } catch {
                Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
            }
        }

        if (-not $tunnelReady) {
            throw "SSH tunnel failed to establish after $maxAttempts seconds"
        }

        Write-Host "✅ SSH tunnel established (PID: $($process.Id))" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create SSH tunnel: $_"
        Write-Host ""
        Write-Host "Manual command:" -ForegroundColor Yellow
        Write-Host "  ssh -i `"$SSHKey`" -L ${LocalPort}:localhost:${RemotePort} $SSHHost" -ForegroundColor Gray
        exit 1
    }
}

Write-Host ""

# Run audit script
Write-Host "Running audit script..." -ForegroundColor Cyan
Write-Host ""

$auditScriptPath = Join-Path $ScriptDir "agent-audit-v2.ps1"

$auditArgs = @{
    Action = $Action
}

if ($AgentId) {
    $auditArgs.AgentId = $AgentId
}

if ($Fixes) {
    $auditArgs.Fixes = $Fixes
}

if ($DryRun) {
    $auditArgs.DryRun = $true
}

try {
    & $auditScriptPath @auditArgs
} catch {
    Write-Error "Audit script failed: $_"
    exit 1
}

Write-Host ""
Write-Host "✅ Audit complete" -ForegroundColor Green

if (-not $tunnelWasActive) {
    Write-Host ""
    Write-Host "ℹ️  SSH tunnel is still running in background" -ForegroundColor Cyan
    Write-Host "   Use it for more audits, or close with:" -ForegroundColor Gray
    Write-Host "   pkill -f 'ssh.*11434:localhost:11434'" -ForegroundColor Gray
}
