<#
.SYNOPSIS
    Agent Security: Defense & Secrets Management (Portable Brain Standard)
.DESCRIPTION
    Manages security operations, secrets (KeyVault), and AI-driven threat analysis.
    Capabilities:
    - security:analyze (AI Threat Assessment)
    - kv-secret:set (Manage Secrets)
    - kv-secret:reference (Get References)
    - access-registry:propose (Document Access)
#>
[CmdletBinding()]
Param(
  # --- Standard Input ---
  [Parameter(Mandatory = $false)]
  [ValidateSet('security:analyze', 'kv-secret:set', 'kv-secret:reference', 'access-registry:propose')]
  [string]$Action,

  [Parameter(Mandatory = $false)] [string]$Query,       # Analysis Context
  [Parameter(Mandatory = $false)] [string]$IntentPath,

  # --- Portable Brain Config (Standard) ---
  [ValidateSet("Ollama", "DeepSeek", "OpenAI", "AzureOpenAI")]
  [string]$Provider = "Ollama",

  [string]$Model = "deepseek-r1:7b",
  [string]$ApiKey = $env:EASYWAY_LLM_KEY,
  [string]$ApiEndpoint = "https://api.deepseek.com/chat/completions",

  # --- Agent Specific ---
  [string]$VaultName,
  [string]$SecretName,
  [string]$SecretValue,
  [hashtable]$Tags,
  [string]$Version,
  [pscustomobject]$Access,

  # --- Flags ---
  [switch]$NonInteractive,
  [switch]$WhatIf,
  [switch]$LogEvent = $true,
  [switch]$JsonOutput
)

$ErrorActionPreference = 'Stop'

# --- 1. HELPER FUNCTIONS (Portable Brain) ---

function Get-LLMResponse {
  param($Prompt, $SystemPrompt)
  Write-Verbose "🧠 Thinking with Provider: $Provider (Model: $Model)..."
  if ($Provider -eq "Ollama") {
    $body = @{ model = $Model; prompt = $Prompt; stream = $false }
    if ($SystemPrompt) { $body["system"] = $SystemPrompt }
    try { return (Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json").response } 
    catch { throw "Ollama Error: $($_.Exception.Message)" }
  }
  elseif ($Provider -in @("DeepSeek", "OpenAI")) {
    if (-not $ApiKey) { throw "ApiKey required" }
    $messages = @(@{ role = "user"; content = $Prompt })
    if ($SystemPrompt) { $messages = @(@{ role = "system"; content = $SystemPrompt }) + $messages }
    $body = @{ model = $Model; messages = $messages; temperature = 0.1 }
    try { 
      return (Invoke-RestMethod -Uri $ApiEndpoint -Method Post -Headers @{Authorization = "Bearer $ApiKey" } -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 120).choices[0].message.content
    }
    catch { throw "API Error: $($_.Exception.Message)" }
  }
}

function Write-AgentLog {
  param($EventData)
  if (-not $LogEvent) { return }
  $logDir = Join-Path $PSScriptRoot "../../logs/agents"
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
  $entry = [ordered]@{ timestamp = (Get-Date).ToString("o"); agent = "agent_security"; provider = $Provider; data = $EventData }
  ($entry | ConvertTo-Json -Depth 5) | Out-File (Join-Path $logDir "agent-history.jsonl") -Append
}

function Out-Result($obj) { 
  if ($JsonOutput) { $obj | ConvertTo-Json -Depth 10 | Write-Output }
  else { Write-Output ($obj | ConvertTo-Json -Depth 5) }
}

# --- 2. EXISTING HELPERS ---

function Read-Intent($path) {
  if (-not $path) { return $null }
  if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
  (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Build-SecretUri([string]$vaultName, [string]$secretName, [string]$version) {
  $base = "https://$vaultName.vault.azure.net/secrets/$secretName"
  if ($version) { return "$base/$version" }
  return $base
}

function KeyVault-Reference([string]$secretUri) {
  return "@Microsoft.KeyVault(SecretUri=$secretUri)"
}

# --- 3. INIT LOGIC ---

$intent = Read-Intent $IntentPath
$p = if ($intent) { $intent.params } else { @{} }

# Map standard params from intent or cli
if ($IntentPath) {
  if (-not $Action) { $Action = $intent.action }
  if (-not $Query) { $Query = $intent.query }
  # Map internal params
  if (-not $VaultName) { $VaultName = $p.vaultName }
  if (-not $SecretName) { $SecretName = $p.secretName }
  if (-not $SecretValue) { $SecretValue = $p.secretValue }
  if (-not $Tags) { $Tags = $p.tags }
  if (-not $Version) { $Version = $p.version }
  if (-not $Access) { $Access = $p.access }
}

if (-not $Action) { Write-Error "Action required"; exit 1 }

$now = (Get-Date).ToUniversalTime().ToString('o')

# --- 4. EXECUTION ---

try {
  $Result = $null
    
  switch ($Action) {
    'security:analyze' {
      # NEW AI ACTION
      if (-not $Query) { throw "Query (Context) is required for analysis." }
            
      $sysPrompt = "You are Agent Security. Analyze the provided context for security risks (OWASP Top 10, Secrets Exposure, Misconfiguration). Return a JSON risk assessment."
      $analysis = Get-LLMResponse -Prompt $Query -SystemPrompt $sysPrompt
            
      $Result = [ordered]@{
        action     = $Action
        ok         = $true
        assessment = $analysis
      }
    }

    'kv-secret:set' {
      if ([string]::IsNullOrWhiteSpace($VaultName) -or [string]::IsNullOrWhiteSpace($SecretName) -or [string]::IsNullOrWhiteSpace($SecretValue)) {
        throw 'vaultName/secretName/secretValue required'
      }

      $executed = $false
      $secretUri = Build-SecretUri -vaultName $VaultName -secretName $SecretName -version $null
      $ref = KeyVault-Reference -secretUri $secretUri

      if (-not $WhatIf) {
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
          throw 'az CLI not found in PATH'
        }
        else {
          $args = @('keyvault', 'secret', 'set', '--vault-name', $VaultName, '--name', $SecretName, '--value', $SecretValue)
          if ($Tags) {
            foreach ($k in $Tags.Keys) { $args += @('--tags', ("{0}={1}" -f $k, $Tags[$k])) }
          }
          & az @args | Out-Null
          if ($LASTEXITCODE -ne 0) { throw "az keyvault secret set failed with exit $LASTEXITCODE" }
          $executed = $true
        }
      }

      $Result = [ordered]@{
        action = $Action; ok = $true; whatIf = [bool]$WhatIf;
        output = [ordered]@{
          vaultName = $VaultName; secretName = $SecretName; executed = $executed; secretUri = $secretUri; appSettingReference = $ref;
          note = 'Secret value hidden.'
        }
      }
    }

    'kv-secret:reference' {
      if ([string]::IsNullOrWhiteSpace($VaultName) -or [string]::IsNullOrWhiteSpace($SecretName)) { throw 'vaultName/secretName required' }
      $secretUri = Build-SecretUri -vaultName $VaultName -secretName $SecretName -version $Version
      $ref = KeyVault-Reference -secretUri $secretUri
      $Result = [ordered]@{ action = $Action; ok = $true; output = [ordered]@{ vaultName = $VaultName; secretName = $SecretName; secretUri = $secretUri; appSettingReference = $ref } }
    }

    'access-registry:propose' {
      if (-not $Access) { throw 'Access object required' }
      $Result = [ordered]@{
        action = $Action; ok = $true;
        output = [ordered]@{ proposedAccess = $Access; targets = [ordered]@{ wiki = 'Wiki/EasyWayData.wiki/security/segreti-e-accessi.md' } }
      }
    }
        
    default { throw "Action '$Action' not implemented." }
  }

  $Output = @{ success = $true; agent = "agent_security"; result = $Result; metadata = @{ provider = $Provider } }
  Write-AgentLog -EventData $Output
  Out-Result $Result

}
catch {
  $ErrorMsg = $_.Exception.Message
  Write-Error "Security Error: $ErrorMsg"
  Write-AgentLog -EventData @{ success = $false; error = $ErrorMsg }
  exit 1
}
