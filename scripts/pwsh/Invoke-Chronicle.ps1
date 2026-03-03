<#
.SYNOPSIS
    Invoke-Chronicle — Record milestones in the EasyWay chronicles.
.DESCRIPTION
    Creates structured chronicle entries under Wiki/EasyWayData.wiki/chronicles/.
    Each entry captures: What happened, Why it matters, Related artifacts, Lessons learned.
    Optionally uses DeepSeek LLM to enrich the narrative.

    Actions:
      chronicle:record   — Record a milestone event
      chronicle:snapshot  — Auto-generate a project snapshot from git state
.EXAMPLE
    pwsh scripts/pwsh/Invoke-Chronicle.ps1 -Title "La Fabbrica" -Category milestone -Description "Polyrepo migration begins"
    pwsh scripts/pwsh/Invoke-Chronicle.ps1 -Action chronicle:snapshot -Title "Pre-Migration Snapshot"
#>
[CmdletBinding()]
param(
    [ValidateSet('chronicle:record', 'chronicle:snapshot')]
    [string]$Action = 'chronicle:record',

    [Parameter(Mandatory)]
    [string]$Title,

    [string]$Description,

    [ValidateSet('milestone', 'innovation', 'lesson-learned', 'team-achievement')]
    [string]$Category = 'milestone',

    [string[]]$Artifacts,

    [string]$Lesson,

    [string]$SessionId,

    # LLM enrichment
    [switch]$Enrich,
    [string]$ApiKey = $env:DEEPSEEK_API_KEY,

    # Output
    [switch]$Json,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# --- Paths ---
$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$ChroniclesDir = Join-Path $RepoRoot "Wiki/EasyWayData.wiki/chronicles"
$IndexFile = Join-Path $ChroniclesDir "_index.md"
$DateStr = (Get-Date).ToString("yyyy-MM-dd")
$TimeStr = (Get-Date).ToString("HH:mm")
$Slug = ($Title -replace '[^a-zA-Z0-9\-]', '-' -replace '-+', '-' -replace '^-|-$', '').ToLower()
$FileName = "$DateStr-$Slug.md"
$FilePath = Join-Path $ChroniclesDir $FileName

# --- Ensure chronicles dir ---
if (-not (Test-Path $ChroniclesDir)) {
    New-Item -ItemType Directory -Path $ChroniclesDir -Force | Out-Null
}

# --- Snapshot: gather git state ---
function Get-ProjectSnapshot {
    $stats = @{}
    try {
        $stats.branch = (git -C $RepoRoot branch --show-current 2>$null) ?? "detached"
        $stats.commit = (git -C $RepoRoot rev-parse --short HEAD 2>$null) ?? "unknown"
        $stats.commitCount = [int](git -C $RepoRoot rev-list --count HEAD 2>$null)

        # File counts by area
        $tracked = git -C $RepoRoot ls-files 2>$null
        $stats.totalFiles = ($tracked | Measure-Object).Count
        $stats.wikiFiles = ($tracked | Where-Object { $_ -like 'Wiki/*' } | Measure-Object).Count
        $stats.agentFiles = ($tracked | Where-Object { $_ -like 'agents/*' } | Measure-Object).Count
        $stats.portalFiles = ($tracked | Where-Object { $_ -like 'portal-api/*' } | Measure-Object).Count
        $stats.scriptFiles = ($tracked | Where-Object { $_ -like 'scripts/*' } | Measure-Object).Count

        # Agent count
        $agentDirs = Get-ChildItem (Join-Path $RepoRoot "agents") -Directory -Filter "agent_*" -ErrorAction SilentlyContinue
        $stats.agentCount = ($agentDirs | Measure-Object).Count

        # Recent PRs (last 5 from git log)
        $stats.recentTags = (git -C $RepoRoot tag --sort=-creatordate 2>$null | Select-Object -First 5) -join ", "
    }
    catch {
        Write-Warning "Snapshot partial: $($_.Exception.Message)"
    }
    return $stats
}

# --- LLM Enrichment ---
function Invoke-Enrich {
    param([string]$RawContent)
    if (-not $ApiKey) {
        Write-Warning "No DEEPSEEK_API_KEY — skipping LLM enrichment"
        return $null
    }
    $sysPrompt = @"
You are The Bard, the EasyWay project historian. Given a raw milestone entry,
enrich it with narrative prose in Italian. Keep the same structure but make
the 'Cosa e Successo' and 'Perche Conta' sections vivid and meaningful.
Be concise but evocative. Max 300 words total.
"@
    $body = @{
        model    = "deepseek-chat"
        messages = @(
            @{ role = "system"; content = $sysPrompt }
            @{ role = "user"; content = $RawContent }
        )
        temperature = 0.7
        max_tokens  = 800
    } | ConvertTo-Json -Depth 5

    try {
        $resp = Invoke-RestMethod -Uri "https://api.deepseek.com/chat/completions" `
            -Method Post -Headers @{ Authorization = "Bearer $ApiKey" } `
            -Body $body -ContentType "application/json" -TimeoutSec 30
        return $resp.choices[0].message.content
    }
    catch {
        Write-Warning "LLM enrichment failed: $($_.Exception.Message)"
        return $null
    }
}

# --- Build chronicle entry ---
$snapshot = $null
if ($Action -eq 'chronicle:snapshot') {
    $snapshot = Get-ProjectSnapshot
    if (-not $Description) {
        $Description = @"
Snapshot del progetto al $DateStr.
- Branch: $($snapshot.branch) @ $($snapshot.commit)
- Commit totali: $($snapshot.commitCount)
- File tracciati: $($snapshot.totalFiles) (Wiki: $($snapshot.wikiFiles), Agents: $($snapshot.agentFiles), Portal: $($snapshot.portalFiles), Scripts: $($snapshot.scriptFiles))
- Agenti attivi: $($snapshot.agentCount)
"@
    }
}

$sessionLine = if ($SessionId) { "`n**Session**: $SessionId" } else { "" }
$artifactLines = if ($Artifacts) {
    ($Artifacts | ForEach-Object { "- $_" }) -join "`n"
} else { "- (nessuno)" }
$lessonBlock = if ($Lesson) { $Lesson } else { "_(nessuna)_" }

$content = @"
---
title: "$Title"
date: $DateStr
category: $Category
session: "$SessionId"
tags: [chronicle, $Category]
---

## Cronaca

### Evento: $Title
### Data: $DateStr $TimeStr$sessionLine
### Categoria: $Category

### Cosa e' Successo
$Description

### Perche' Conta
_(Da compilare — perche' questo momento e' significativo per il progetto)_

### Artefatti Correlati
$artifactLines

### Lezione Appresa
$lessonBlock
"@

# --- LLM Enrichment ---
if ($Enrich) {
    $enriched = Invoke-Enrich -RawContent $content
    if ($enriched) { $content = $enriched }
}

# --- WhatIf ---
if ($WhatIf) {
    Write-Host "=== WHAT-IF: Would create $FilePath ===" -ForegroundColor Cyan
    Write-Host $content
    if ($Json) {
        @{ whatif = $true; file = $FilePath; category = $Category; title = $Title } | ConvertTo-Json
    }
    return
}

# --- Write file ---
Set-Content -Path $FilePath -Value $content -Encoding UTF8
Write-Host "Chronicle recorded: $FilePath" -ForegroundColor Green

# --- Update index ---
$indexEntry = "| $DateStr | [$Title]($FileName) | $Category | $SessionId |"
if (-not (Test-Path $IndexFile)) {
    $indexHeader = @"
---
title: "Chronicles Index"
date: $DateStr
tags: [chronicle, index]
---

# Chronicles — Indice Cronologico

> La storia del progetto EasyWay, pietra miliare dopo pietra miliare.

| Data | Evento | Categoria | Session |
|------|--------|-----------|---------|
$indexEntry
"@
    Set-Content -Path $IndexFile -Value $indexHeader -Encoding UTF8
}
else {
    Add-Content -Path $IndexFile -Value $indexEntry -Encoding UTF8
}

Write-Host "Index updated: $IndexFile" -ForegroundColor Green

# --- JSON output ---
if ($Json) {
    @{
        success  = $true
        file     = $FilePath
        index    = $IndexFile
        category = $Category
        title    = $Title
        snapshot = $snapshot
    } | ConvertTo-Json -Depth 5
}
