Param(
  [Parameter(Mandatory=$true)] [string]$InputJson
)

$ErrorActionPreference = 'Stop'

function Fail($msg){ Write-Error $msg; exit 1 }

try { $obj = $InputJson | ConvertFrom-Json -ErrorAction Stop } catch { Fail "Invalid JSON" }

if (-not $obj.action) { Fail "Missing 'action'" }
if ($null -eq $obj.ok) { Fail "Missing 'ok'" }
if ($null -eq $obj.whatIf) { Fail "Missing 'whatIf'" }
if (-not $obj.output) { Fail "Missing 'output'" }

$out = [ordered]@{
  ok = $true
  schema = 'action-result@1.0'
  missing = @()
}

if (-not $obj.contractId) { $out.missing += 'contractId' }
if (-not $obj.contractVersion) { $out.missing += 'contractVersion' }
if ($out.missing.Count -gt 0) { $out.ok = $false }

$out | ConvertTo-Json -Depth 6 | Write-Output

