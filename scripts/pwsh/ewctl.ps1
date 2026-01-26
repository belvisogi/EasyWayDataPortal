<#
.SYNOPSIS
  The Sacred Kernel of EasyWay Control (ewctl).
  Orchestrates modular checks, fixes, and plans with strict output isolation.

.DESCRIPTION
  This script acts as a plugin loader and standardized execution environment.
  It discovers modules in `scripts/pwsh/modules/ewctl/*.psm1`.
  It captures all checks/fixes and guarantees pure JSON output when requested.

.PARAMETER Command
  The action to perform: check, fix, plan, describe.

.PARAMETER Json
  If set, outputs pure JSON suitable for n8n/pipelines.

.EXAMPLE
  .\ewctl.ps1 check --json
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Command,

  [switch]$Json,
  [switch]$VerboseOutput, # Force verbose to host even in JSON mode (debug only)
  [switch]$Force # Bypass confirmations
)

$ErrorActionPreference = 'Stop'
$ValidCommands = "check", "fix", "plan", "describe"

if ($Command -notin $ValidCommands) {
  # Fallback for Legacy/Invalid commands
  Write-Error "Invalid Command '$Command'. Valid commands are: $($ValidCommands -join ', ')."
  exit 1
}

$ModulesPath = Join-Path $PSScriptRoot "modules/ewctl"

$LogPath = Join-Path $PSScriptRoot "../../logs/ewctl.debug.log"
if (-not (Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null }

function Write-KernelLog {
  param($Message, $Type = "Info")
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $line = "[$timestamp] [$Type] $Message"
  Add-Content -Path $LogPath -Value $line -ErrorAction SilentlyContinue
}

# --- 1. Helper: Safe Execution (The Silencer) ---
function Invoke-EwctlSafeExecution {
  param([ScriptBlock]$Block, [string]$Context = "Unknown")
    
  # Captures streams to prevent pollution of stdout (critical for n8n)
  # Returns @{ Result = $res; Output = $capturedOutput }
  try {
    if ($Json) {
      # In JSON mode, we hush everything unless it's the return value
      # Write-Host uses stream 6 in PWSH. We redirect it to null.
      # We also redirect verbose (4) and warning (3) to generate clean JSON.
      $result = & $Block 6>$null 4>$null 3>$null
      return @{ Result = $result; Success = $true }
    }
    else {
      # In Human mode, let it flow
      $result = & $Block
      return @{ Result = $result; Success = $true }
    }
  }
  catch {
    $err = $_
    Write-KernelLog -Type "ERROR" -Message "CRASH in $Context : $($err.Exception.Message)`n$($err.ScriptStackTrace)"
    return @{ Success = $false; Error = $err.Exception.Message; Source = $err.InvocationInfo.ScriptName }
  }
}

# --- 2. Module Discovery ---
$Modules = Get-ChildItem -Path $ModulesPath -Filter "ewctl.*.psm1"
$LoadedModules = @()

foreach ($m in $Modules) {
  Import-Module $m.FullName -Force -Scope Local
  $baseName = $m.BaseName
    
  # Duck Typing: Check capabilities
  $canCheck = (Get-Command -Module $baseName -Name "Get-EwctlDiagnosis" -ErrorAction SilentlyContinue)
  $canPlan = (Get-Command -Module $baseName -Name "Get-EwctlPrescription" -ErrorAction SilentlyContinue)
  $canFix = (Get-Command -Module $baseName -Name "Invoke-EwctlTreatment" -ErrorAction SilentlyContinue)

  $LoadedModules += [PSCustomObject]@{
    Name     = $baseName
    CanCheck = [bool]$canCheck
    CanPlan  = [bool]$canPlan
    CanFix   = [bool]$canFix
  }
}

# --- 3. Execution Engine ---
$GlobalResults = @()

switch ($Command) {
  "describe" {
    $GlobalResults = $LoadedModules
  }

  "check" {
    foreach ($mod in $LoadedModules) {
      if ($mod.CanCheck) {
        # Invoke Check
        $call = "{0}\{1}" -f $mod.Name, "Get-EwctlDiagnosis"
        $res = Invoke-EwctlSafeExecution -Block { & $call } -Context "$($mod.Name):Check"
        if ($res.Success) {
          # Flatten results
          foreach ($r in $res.Result) {
            $r | Add-Member -MemberType NoteProperty -Name "Module" -Value $mod.Name -Force
            $GlobalResults += $r
          }
        }
        else {
          $GlobalResults += [PSCustomObject]@{ Status = "ERROR"; Message = "Module crashed: $($res.Error)"; Module = $mod.Name }
        }
      }
    }
  }

  "plan" {
    foreach ($mod in $LoadedModules) {
      if ($mod.CanPlan) {
        $call = "{0}\{1}" -f $mod.Name, "Get-EwctlPrescription"
        $res = Invoke-EwctlSafeExecution -Block { & $call } -Context "$($mod.Name):Plan"
        if ($res.Success) {
          foreach ($r in $res.Result) {
            $r | Add-Member -MemberType NoteProperty -Name "Module" -Value $mod.Name -Force
            $GlobalResults += $r
          }
        }
      }
    }
  }

  "fix" {
    # 1. DRY RUN PHASE: Calculate Plan first
    Write-Host "--- 🔍 DRY RUN (Planning Phase) ---" -ForegroundColor Cyan
    $ExecutionPlan = @()

    foreach ($mod in $LoadedModules) {
      if ($mod.CanPlan) {
        $call = "{0}\{1}" -f $mod.Name, "Get-EwctlPrescription"
        # Run Plan safely
        $res = Invoke-EwctlSafeExecution -Block { & $call } -Context "$($mod.Name):Plan"
        if ($res.Success) {
          foreach ($item in $res.Result) {
            $ExecutionPlan += [PSCustomObject]@{
              Module      = $mod.Name
              Step        = $item.Step
              Description = $item.Description
              Automated   = $item.Automated
            }
          }
        }
      }
    }

    # 2. SHOW PLAN
    if ($ExecutionPlan.Count -eq 0) {
      Write-Host "✅ Nothing to fix. System is healthy." -ForegroundColor Green
      exit 0
    }

    $ExecutionPlan | Format-Table -AutoSize | Out-String | Write-Host

    # 3. INTERACTIVE GATE (The Kill Switch)
    if (-not $Force -and -not $Json) {
      Write-Host "⚠️  Ready to execute $($ExecutionPlan.Count) actions." -ForegroundColor Yellow
      $confirm = Read-Host "🚀 PRESS 'Y' TO EXECUTE, ANY OTHER KEY TO ABORT"
      if ($confirm -ne 'y') { 
        Write-Host "🛑 Aborted by user." -ForegroundColor Red
        exit 0 
      }
    }

    # 4. EXECUTION PHASE
    Write-Host "--- 🔨 EXECUTION PHASE ---" -ForegroundColor Cyan
    foreach ($mod in $LoadedModules) {
      if ($mod.CanFix) {
        # Filter: In real implementation we should pass the specific plan items to fix
        # For now, we trust the module knows what to do based on current state
        $call = "{0}\{1}" -f $mod.Name, "Invoke-EwctlTreatment"
        $res = Invoke-EwctlSafeExecution -Block { & $call -Confirm:$false } -Context "$($mod.Name):Fix"
        $GlobalResults += [PSCustomObject]@{
          Module  = $mod.Name
          Action  = "Fix"
          Success = $res.Success
          Result  = $res.Result
        }
      }
    }
  }
}

# --- 4. Render Output ---
if ($Json) {
  $GlobalResults | ConvertTo-Json -Depth 5 -Compress
}
else {
  # Human Friendly Output
  if ($Command -eq 'check') {
    $GlobalResults | Format-Table -Property Status, Module, Message -AutoSize
  }
  elseif ($Command -eq 'describe') {
    $GlobalResults | Format-Table -AutoSize
  }
  else {
    $GlobalResults | Format-List
  }
}

# --- 5. Exit Code ---
# If any operation failed or result has Status='Error', exit 1
$hasError = $GlobalResults | Where-Object { $_.Status -eq 'Error' -or $_.Success -eq $false }
if ($hasError) { exit 1 }
exit 0
