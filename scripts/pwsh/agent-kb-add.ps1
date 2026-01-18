Param(
  [Parameter(Mandatory=$true)] [string]$Id,
  [Parameter(Mandatory=$true)] [string]$Intent,
  [Parameter(Mandatory=$true)] [string]$Question,
  [string[]]$Tags,
  [string[]]$Steps,
  [string[]]$Verify,
  [string[]]$Preconditions,
  [string[]]$Rollback,
  [string[]]$Outputs,
  [string[]]$References
)

$ErrorActionPreference = 'Stop'
$kb = 'agents/kb/recipes.jsonl'
if (-not (Test-Path $kb)) { throw "KB not found: $kb" }

$obj = [ordered]@{
  id=$Id; intent=$Intent; question=$Question;
  tags=$Tags; preconditions=$Preconditions; steps=$Steps; verify=$Verify; rollback=$Rollback; outputs=$Outputs; references=$References; updated=(Get-Date).ToUniversalTime().ToString('o')
}
$line = ($obj | ConvertTo-Json -Depth 8 -Compress)
Add-Content -Path $kb -Value $line
Write-Host "Added KB entry: $Id" -ForegroundColor Green

