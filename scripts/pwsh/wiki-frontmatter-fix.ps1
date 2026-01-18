param(
  [string]$ScopeName,
  [string]$WikiPath = "Wiki/EasyWayData.wiki",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Get-Title {
    param($Content, $FileName)
    if ($Content -match '(?m)^#\s+(.+)$') { return $Matches[1].Trim() }
    return ($FileName -replace '\.md$','' -replace '-',' ' | Get-Culture).TextInfo.ToTitleCase(($FileName -replace '\.md$','' -replace '-',' '))
}

# 1. Run Lint to get targets
Write-Host "🔍 Analyzing Scope: $ScopeName..." -ForegroundColor Cyan
$tmpJson = New-TemporaryFile
pwsh scripts/wiki-frontmatter-lint.ps1 -Path $WikiPath -ScopeName $ScopeName -IncludeFullPath -SummaryOut $tmpJson | Out-Null
$lintData = Get-Content $tmpJson | ConvertFrom-Json
Remove-Item $tmpJson

$failures = $lintData.results | Where-Object { -not $_.ok }

if ($failures.Count -eq 0) {
    Write-Host "✅ No issues found in $ScopeName" -ForegroundColor Green
    exit
}

Write-Host "🛠️  Fixing $($failures.Count) files..." -ForegroundColor Yellow

foreach ($fail in $failures) {
    $path = $fail.fullPath
    if (-not (Test-Path $path)) { continue }
    
    $content = Get-Content -LiteralPath $path -Raw
    $fixedContent = $content
    $status = "Modified"

    # Case A: Missing Yaml Front Matter entirely
    if ($fail.error -eq 'missing_yaml_front_matter' -or $fail.error -eq 'unterminated_front_matter') {
        $title = Get-Title -Content $content -FileName (Split-Path $path -Leaf)
        $id = (Split-Path $path -Leaf) -replace '\.md$',''
        
        $fm = @"
---
id: $id
title: $title
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  include: true
  chunk_hint: 5000
---

"@
        $fixedContent = $fm + $content
        $status = "Created FM"
    }
    # Case B: Incomplete FM (Usually missing LLM entries)
    elseif ($fail.missing) {
        # Check if missing LLM stuff
        if ($fail.missing -contains 'llm_include' -or $fail.missing -contains 'llm_chunk') {
             # Naive injection: Find the closing '---' of the first block
             # and insert llm block before it.
             # We assume standard formatting: starts with ---, ends with ---
             
             # Locate first --- (start) and second --- (end)
             $startIdx = $content.IndexOf("---")
             if ($startIdx -ge 0) {
                 $endIdx = $content.IndexOf("---", $startIdx + 3)
                 if ($endIdx -gt 0) {
                     $injection = "`nllm:`n  include: true`n  chunk_hint: 5000"
                     $fixedContent = $content.Insert($endIdx, $injection)
                     $status = "Injected LLM block"
                 }
             }
        }
    }

    if ($fixedContent -ne $content) {
        if ($DryRun) {
            Write-Host "[$ScopeName] [DRY RUN] Would fix: $($fail.file) ($status)" -ForegroundColor Gray
        } else {
            Set-Content -LiteralPath $path -Value $fixedContent
            Write-Host "[$ScopeName] Fixed: $($fail.file) ($status)" -ForegroundColor Green
        }
    } else {
        Write-Host "[$ScopeName] Skipped (Could not apply fix): $($fail.file)" -ForegroundColor Red
    }
}
