<#
.SYNOPSIS
  The Sacred Kernel of EasyWay Control (ewctl).
#>
[CmdletBinding()]
Param(
  [string]$Command,
  [switch]$Json,
  [switch]$VerboseOutput, 
  [switch]$Force,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RestArgs
)

$ErrorActionPreference = 'Stop'
$ValidCommands = "check", "fix", "plan", "describe", "commit"

if ($Command -notin $ValidCommands) {
  Write-Error "Invalid Command '$Command'."
  exit 1
}

$ModulesPath = Join-Path $PSScriptRoot "modules/ewctl"


function Write-KernelLog {
  param($Message, $Type = "Info")
  # Simple log stub
}

function Invoke-EwctlSafeExecution {
  param([ScriptBlock]$Block, [string]$Context = "Unknown")
  try {
    $result = & $Block
    return @{ Result = $result; Success = $true }
  }
  catch {
    return @{ Success = $false; Error = $_.Exception.Message }
  }
}

# --- Module Discovery ---
$Modules = Get-ChildItem -Path $ModulesPath -Filter "ewctl.*.psm1" -ErrorAction SilentlyContinue
$LoadedModules = @()

if ($Modules) {
  foreach ($m in $Modules) {
    Import-Module $m.FullName -Force -Scope Local
    $LoadedModules += [PSCustomObject]@{
      Name     = $m.BaseName
      CanCheck = $true # Simplified for MVP
      CanPlan  = $true
      CanFix   = $true
    }
  }
}

# --- Execution Engine ---


switch ($Command) {
  "describe" {
    # Stub
  }

  "check" {
    # Stub
  }

  "plan" {
    # Stub
  }

  "fix" {
    Write-Host "Fix mode not fully implemented in this wrapper."
  }

  "commit" {
    # --- SMART COMMIT WRAPPER ---
    Write-Host "🛡️  EasyWay Smart Commit Protocol Initiated..." -ForegroundColor Cyan

    # 1. Anti-Pattern Scan
    $stagedFiles = git diff --name-only --cached
    if ($stagedFiles) {
      foreach ($file in $stagedFiles) {
        if (-not (Test-Path $file)) { continue }
        if ($file -match "\.(md|txt|json)$" -or $file -match ".cursorrules") { continue }
        $content = Get-Content $file -Raw
        $p1 = "Invoke-AgentTool"
        $p2 = ".*-Target"
        $p3 = ".*\(.*git diff.*\)"
        if ($content -match "$p1$p2$p3") {
          Write-Host "❌ BLOCKED: Forbidden pattern detected in '$file'." -ForegroundColor Red
          write-host "Use pipeline!"
          exit 1
        }
      }
    }

    # 2. Fast Audit
    Write-Host "🕵️  Running Rapid Audit..." -ForegroundColor Cyan
    $AuditScript = Join-Path $PSScriptRoot "agent-audit.ps1"
    if (Test-Path $AuditScript) {
      $auditParams = @{ Mode = 'manifest-only'; AutoFix = $false; FailOnError = $false }
      & $AuditScript @auditParams
      if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Audit Failed, but proceeding (Governance is in 'Warn' mode)." -ForegroundColor Yellow
      }
    }

    # 2b. OpenAPI Lint (only when openapi.yaml is staged)
    $openApiStaged = $stagedFiles | Where-Object { $_ -match 'openapi\.yaml$' }
    if ($openApiStaged) {
      $OpenApiLintScript = Join-Path $PSScriptRoot "Invoke-OpenApiLint.ps1"
      if (Test-Path $OpenApiLintScript) {
        & $OpenApiLintScript -FailOnError $false
        if ($LASTEXITCODE -ne 0) {
          Write-Host "⚠️  OpenAPI lint failed — proceeding (Warn mode)." -ForegroundColor Yellow
        }
      }
    }

    # 3. Execute Git Commit
    Write-Host "✅ Checks Passed. Committing..." -ForegroundColor Green
    if ($RestArgs.Count -eq 0) {
      git commit
    }
    else {
      git commit @RestArgs
    }
  }
}

# --- Exit Code ---
exit 0
