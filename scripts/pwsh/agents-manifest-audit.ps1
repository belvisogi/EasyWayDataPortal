Param(
  [string]$AgentsDir = 'agents',
  [string]$OutJson = 'out/docs/agents-manifest-audit.json',
  [string]$OutMarkdown = 'out/docs/agents-manifest-audit.md',
  [switch]$FailOnError
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$path) {
  $dir = Split-Path -Parent $path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

function Read-Json([string]$path) {
  try { return (Get-Content -Raw -Path $path) | ConvertFrom-Json } catch { return $null }
}

function Add-Issue([ref]$issues, [string]$severity, [string]$code, [string]$message, [string]$hint) {
  $issues.Value += [ordered]@{
    severity = $severity
    code = $code
    message = $message
    hint = $hint
  }
}

if (-not (Test-Path $AgentsDir)) { throw "AgentsDir not found: $AgentsDir" }

$agentDirs = Get-ChildItem $AgentsDir -Directory | Where-Object { $_.Name -notin @('kb','logs','core','config','skills','templates','tests') } | Sort-Object Name
$results = @()
$hasErrors = $false

foreach ($dir in $agentDirs) {
  $issues = @()
  $manifestPath = Join-Path $dir.FullName 'manifest.json'
  $readmePath = Join-Path $dir.FullName 'README.md'
  $hasManifest = Test-Path $manifestPath

  $manifest = $null
  if ($hasManifest) { $manifest = Read-Json $manifestPath }

  if (-not $hasManifest) {
    Add-Issue ([ref]$issues) 'error' 'missing_manifest' "Missing manifest.json in $($dir.Name)" 'Create agents/<agent>/manifest.json (WHAT-first: role/description/allowed_paths/allowed_tools/required_gates/knowledge_sources/actions).'
    $hasErrors = $true
  } elseif (-not $manifest) {
    Add-Issue ([ref]$issues) 'error' 'invalid_manifest_json' "manifest.json is not parseable in $($dir.Name)" 'Fix JSON syntax; gates require parseable manifests.'
    $hasErrors = $true
  } else {
    $hasDesc = $false
    if ($manifest.description -or $manifest.role -or $manifest.name) { $hasDesc = $true }
    if (-not $hasDesc) {
      Add-Issue ([ref]$issues) 'error' 'missing_description' "$($dir.Name): missing description/role/name in manifest" 'Add at least description (human+RAG) and role/id (machine).'
      $hasErrors = $true
    }

    # allowed_paths: support both array (legacy) and object with read/write (template)
    $allowedPathsOk = $false
    if ($manifest.allowed_paths) {
      if ($manifest.allowed_paths -is [System.Collections.IEnumerable] -and -not ($manifest.allowed_paths.PSObject.Properties.Name -contains 'read')) { $allowedPathsOk = $true }
      if ($manifest.allowed_paths.read -or $manifest.allowed_paths.write) { $allowedPathsOk = $true }
    }
    if (-not $allowedPathsOk) {
      Add-Issue ([ref]$issues) 'warning' 'missing_allowed_paths' "$($dir.Name): allowed_paths missing or empty" 'Define allowed_paths to enforce scope; required for Enforcer guardrail.'
    }

    if (-not $manifest.allowed_tools) {
      Add-Issue ([ref]$issues) 'warning' 'missing_allowed_tools' "$($dir.Name): allowed_tools missing" 'Declare allowed_tools (pwsh/git/az/npm/flyway) to document capabilities and reduce ambiguity.'
    }

    if (-not $manifest.required_gates) {
      Add-Issue ([ref]$issues) 'warning' 'missing_required_gates' "$($dir.Name): required_gates missing" 'Declare required_gates to make governance explicit.'
    }

    if (-not $manifest.knowledge_sources) {
      Add-Issue ([ref]$issues) 'warning' 'missing_knowledge_sources' "$($dir.Name): knowledge_sources missing" 'Add canonical Wiki/KB pages used by the agent (RAG-ready).'
    }

    $hasActions = $false
    if ($manifest.actions -and $manifest.actions.Count -gt 0) { $hasActions = $true }
    if (-not $hasActions -and $manifest.actions -is [System.Collections.IDictionary]) { $hasActions = $true }
    if (-not $hasActions) {
      Add-Issue ([ref]$issues) 'warning' 'missing_actions' "$($dir.Name): actions not declared in manifest" 'Add actions[] with name/description/params so n8n.dispatch can validate and route reliably.'
    } else {
        # Deep Audit: Verify script paths
        foreach ($act in $manifest.actions) {
            if ($act.script) {
                # Resolve relative path from manifest location
                $scriptPath = Join-Path $dir.FullName $act.script
                # Normalize path (resolve ..)
                try {
                    $normPath = [System.IO.Path]::GetFullPath($scriptPath)
                    if (-not (Test-Path $normPath)) {
                        Add-Issue ([ref]$issues) 'error' 'broken_script_link' "$($dir.Name): action '$($act.name)' links to missing script" "Path not found: $($act.script) (Resolved: $normPath)"
                        $hasErrors = $true
                    }
                } catch {
                     Add-Issue ([ref]$issues) 'error' 'invalid_script_path' "$($dir.Name): action '$($act.name)' has invalid path" "Path: $($act.script)"
                     $hasErrors = $true
                }
            }
        }
    }
  }

  if (-not (Test-Path $readmePath)) {
    Add-Issue ([ref]$issues) 'warning' 'missing_readme' "$($dir.Name): missing README.md" 'Add a short README with purpose, entrypoint, examples and references.'
  }

  $templatesDir = Join-Path $dir.FullName 'templates'
  if (-not (Test-Path $templatesDir)) {
    Add-Issue ([ref]$issues) 'advisory' 'missing_templates' "$($dir.Name): missing templates/ folder" 'Optional but recommended: include sample intents and templates for non-experts.'
  }

  $results += [ordered]@{
    agent = $dir.Name
    manifest = if ($hasManifest) { "agents/$($dir.Name)/manifest.json" } else { $null }
    readme = if (Test-Path $readmePath) { "agents/$($dir.Name)/README.md" } else { $null }
    issues = $issues
  }
}

$summary = [ordered]@{
  ok = (-not $hasErrors)
  agentsCount = $results.Count
  errorsCount = ($results | ForEach-Object { $_.issues } | Where-Object { $_.severity -eq 'error' } | Measure-Object).Count
  warningsCount = ($results | ForEach-Object { $_.issues } | Where-Object { $_.severity -eq 'warning' } | Measure-Object).Count
  generatedAt = (Get-Date).ToUniversalTime().ToString('o')
  output = [ordered]@{
    json = $OutJson
    markdown = $OutMarkdown
  }
}

$report = [ordered]@{
  summary = $summary
  agents = $results
}

Ensure-Dir $OutJson
($report | ConvertTo-Json -Depth 10) | Set-Content -Path $OutJson -Encoding UTF8

Ensure-Dir $OutMarkdown
$md = New-Object System.Text.StringBuilder
$null = $md.AppendLine("# Agents Manifest Audit")
$null = $md.AppendLine()
$null = $md.AppendLine(("Generated: {0}" -f $summary.generatedAt))
$null = $md.AppendLine(("OK: {0} | errors={1} warnings={2}" -f $summary.ok, $summary.errorsCount, $summary.warningsCount))
$null = $md.AppendLine()
foreach ($a in $results) {
  $null = $md.AppendLine(("## {0}" -f $a.agent))
  if ($a.manifest) { $null = $md.AppendLine(('- manifest: `{0}`' -f $a.manifest)) }
  if ($a.readme) { $null = $md.AppendLine(('- readme: `{0}`' -f $a.readme)) }
  if (-not $a.issues -or $a.issues.Count -eq 0) {
    $null = $md.AppendLine("- issues: none")
    $null = $md.AppendLine()
    continue
  }
  foreach ($i in $a.issues) {
    $null = $md.AppendLine(("- [{0}] {1} ({2})" -f $i.severity, $i.message, $i.code))
    if ($i.hint) { $null = $md.AppendLine(("  - hint: {0}" -f $i.hint)) }
  }
  $null = $md.AppendLine()
}

$md.ToString() | Set-Content -Path $OutMarkdown -Encoding UTF8

Write-Output ($summary | ConvertTo-Json -Depth 6)
if ($FailOnError -and $hasErrors) { exit 2 }
