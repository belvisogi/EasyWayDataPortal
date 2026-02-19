<#
.SYNOPSIS
    Agent Infra: IaC/Terraform governance (Portable Brain Standard - Level 2)
.DESCRIPTION
    Manages IaC/Terraform workflows and AI-driven infrastructure drift analysis.
    Capabilities:
    - infra:terraform-plan  (scripted: terraform init/validate/plan, WhatIf-by-default)
    - infra:drift-check     (L2 LLM+RAG: AI drift assessment against Wiki IaC context)
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('infra:terraform-plan', 'infra:drift-check')]
  [string]$Action,

  [Parameter(Mandatory = $false)] [string]$Query,
  [Parameter(Mandatory = $false)] [string]$IntentPath,

  # LLM config (L2)
  [ValidateSet("DeepSeek", "OpenAI")]
  [string]$Provider = "DeepSeek",
  [string]$Model = "deepseek-chat",

  # Infra-specific
  [Parameter(Mandatory = $false)] [string]$Workdir,

  # Flags
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [bool]$LogEvent = $true,
  [switch]$JsonOutput
)

$ErrorActionPreference = 'Stop'

# --- HELPER FUNCTIONS ---

function Read-Intent($path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Write-AgentLog {
  param($EventData)
  if (-not $LogEvent) { return }
  $logDir = Join-Path $PSScriptRoot '..\..\agents\logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
  $entry = [ordered]@{
    timestamp = (Get-Date).ToString('o')
    agent     = 'agent_infra'
    provider  = $Provider
    data      = $EventData
  }
  ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir 'agent-history.jsonl') -Append -Encoding utf8
}

function Out-Result($obj) {
  if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
  else { $obj | ConvertTo-Json -Depth 5 | Write-Output }
}

# --- INIT ---

$intent = Read-Intent $IntentPath
$p      = if ($intent) { $intent.params } else { @{} }

if ($IntentPath) {
  if (-not $Action)  { $Action  = $intent.action }
  if (-not $Query)   { $Query   = if ($intent.PSObject.Properties['query']) { $intent.query } else { $p.query } }
  if (-not $Workdir) { $Workdir = $p.workdir }
}

if (-not $Action) { Write-Error "Action required"; exit 1 }

$now = (Get-Date).ToUniversalTime().ToString('o')

# --- EXECUTION ---

try {
  $Result = $null

  switch ($Action) {

    'infra:terraform-plan' {
      $wd       = if ($Workdir) { $Workdir } else { 'infra/terraform' }
      $executed = $false
      $errorMsg = $null

      if (-not (Test-Path $wd)) { $errorMsg = "Terraform dir not found: $wd" }
      if (-not $errorMsg -and -not $WhatIf) {
        if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
          $errorMsg = 'terraform not found in PATH'
        }
        else {
          try {
            Push-Location $wd
            terraform init -input=false | Out-Host
            terraform validate | Out-Host
            terraform plan -input=false | Out-Host
            $executed = $true
          }
          catch { $errorMsg = $_.Exception.Message }
          finally { Pop-Location }
        }
      }

      $Result = [ordered]@{
        action        = $Action
        ok            = ($null -eq $errorMsg)
        whatIf        = [bool]$WhatIf
        nonInteractive = [bool]$NonInteractive
        correlationId = if ($intent -and $intent.PSObject.Properties['correlationId']) { $intent.correlationId } else { $null }
        startedAt     = $now
        finishedAt    = (Get-Date).ToUniversalTime().ToString('o')
        output        = [ordered]@{
          workdir  = $wd
          executed = $executed
          hint     = 'Apply non implementato: usare pipeline con approvazioni Human_Governance_Approval.'
        }
        error         = $errorMsg
      }
      $Result.contractId      = 'action-result'
      $Result.contractVersion = '1.0'
    }

    'infra:drift-check' {
      if ([string]::IsNullOrWhiteSpace($Query)) { throw "Query required for infra:drift-check" }

      # Load Invoke-LLMWithRAG skill
      $ragSkill = Join-Path $PSScriptRoot '..\..\agents\skills\retrieval\Invoke-LLMWithRAG.ps1'
      if (-not (Test-Path $ragSkill)) { throw "Skill not found: $ragSkill" }
      . $ragSkill

      # Read system prompt
      $promptPath = Join-Path $PSScriptRoot '..\..\agents\agent_infra\PROMPTS.md'
      $systemPrompt = if (Test-Path $promptPath) {
        Get-Content $promptPath -Raw -Encoding UTF8
      }
      else {
        "You are Agent Infra. Analyze infrastructure drift and classify severity."
      }

      Write-Verbose "[agent_infra] Invoking drift-check via LLM+RAG (model=$Model)..."

      $llmResult = Invoke-LLMWithRAG `
        -Query        $Query `
        -AgentId      'agent_infra' `
        -SystemPrompt $systemPrompt `
        -Model        $Model `
        -Temperature  0.0 `
        -MaxTokens    1000 `
        -TopK         5 `
        -SecureMode

      if (-not $llmResult.Success) {
        throw "LLM call failed: $($llmResult.Error)"
      }

      $Result = [ordered]@{
        action        = $Action
        ok            = $true
        startedAt     = $now
        finishedAt    = (Get-Date).ToUniversalTime().ToString('o')
        assessment    = $llmResult.Answer
        metadata      = [ordered]@{
          provider    = $Provider
          model       = $llmResult.Model
          ragChunks   = $llmResult.RAGChunks
          tokensIn    = $llmResult.TokensIn
          tokensOut   = $llmResult.TokensOut
          costUSD     = $llmResult.CostUSD
          durationSec = $llmResult.DurationSec
        }
      }
      $Result.contractId      = 'action-result'
      $Result.contractVersion = '1.0'
    }

    default { throw "Action '$Action' not implemented." }
  }

  $output = @{
    success = $true
    agent   = 'agent_infra'
    result  = $Result
  }
  Write-AgentLog -EventData $output
  Out-Result $Result

}
catch {
  $errorMsg = $_.Exception.Message
  Write-Error "Infra Error: $errorMsg"
  Write-AgentLog -EventData @{ success = $false; error = $errorMsg }
  exit 1
}
