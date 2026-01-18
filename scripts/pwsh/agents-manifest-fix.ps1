param(
    [string]$AgentsDir = 'agents',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 Analyzing Agents in $AgentsDir..." -ForegroundColor Cyan

$agentDirs = Get-ChildItem $AgentsDir -Directory | Where-Object { $_.Name -notin @('kb','logs','core') }

foreach ($dir in $agentDirs) {
    $manifestPath = Join-Path $dir.FullName 'manifest.json'
    if (-not (Test-Path $manifestPath)) { continue }

    $jsonContent = Get-Content -Raw $manifestPath
    $manifest = $jsonContent | ConvertFrom-Json
    $modified = $false

    # Fix 1: allowed_tools
    if (-not $manifest.PSObject.Properties.Match('allowed_tools').Count) {
        $manifest | Add-Member -MemberType NoteProperty -Name 'allowed_tools' -Value @('pwsh', 'git')
        $modified = $true
        Write-Host "  [$($dir.Name)] + allowed_tools (pwsh, git)"
    }

    # Fix 2: required_gates (Default to minimal set)
    if (-not $manifest.PSObject.Properties.Match('required_gates').Count) {
        $manifest | Add-Member -MemberType NoteProperty -Name 'required_gates' -Value @('doc_alignment')
        $modified = $true
        Write-Host "  [$($dir.Name)] + required_gates (doc_alignment)"
    }

    # Fix 3: knowledge_sources (Default to Wiki root)
    if (-not $manifest.PSObject.Properties.Match('knowledge_sources').Count) {
        $manifest | Add-Member -MemberType NoteProperty -Name 'knowledge_sources' -Value @(
            @{ type="document"; path="Wiki/EasyWayData.wiki/home.md"; priority="low" }
        )
        $modified = $true
        Write-Host "  [$($dir.Name)] + knowledge_sources (default)"
    }

    if ($modified) {
        if ($DryRun) {
            Write-Host "  [$($dir.Name)] [DRY RUN] Would save changes." -ForegroundColor Gray
        } else {
            $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8
            Write-Host "  [$($dir.Name)] ✅ Saved." -ForegroundColor Green
        }
    }
}
Write-Host "Done." -ForegroundColor Cyan
