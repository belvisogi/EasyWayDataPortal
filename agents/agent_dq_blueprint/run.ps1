param(
  [ValidateSet('blueprint-from-file')]
  [string]$Action = 'blueprint-from-file',
  [Parameter(Mandatory=$true)]
  [string]$Input,
  [Parameter(Mandatory=$true)]
  [string]$Domain,
  [Parameter(Mandatory=$true)]
  [string]$Flow,
  [Parameter(Mandatory=$true)]
  [string]$Instance,
  [double]$Impact = 0.5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "[agent_dq_blueprint] Action=$Action Input=$Input Scope=$Domain/$Flow/$Instance"

try {
  # Prefer TS CLI if ts-node is available, else just print guidance
  $tsNode = (& node -e "try{require('ts-node');process.exit(0)}catch(e){process.exit(1)}" 2>$null); $hasTsNode = ($LASTEXITCODE -eq 0)
} catch { $hasTsNode = $false }

if ($hasTsNode) {
  node -r ts-node/register agents/agent_dq_blueprint/src/cli.ts --action $Action --input $Input --domain $Domain --flow $Flow --instance $Instance --impact $Impact
} else {
  Write-Warning "ts-node non trovato. Esegui: npm i -D ts-node typescript oppure usa direttamente ts-node."
  Write-Host "Esempio: npx ts-node agents/agent_dq_blueprint/src/cli.ts --action $Action --input $Input --domain $Domain --flow $Flow --instance $Instance --impact $Impact"
}

