#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Agent per sincronizzazione e validazione documentazione

.DESCRIPTION
  Mantiene allineamento tra documentazione (.md) e codice (.ps1).
  Valida metadata tags, verifica cross-references, genera report.

.METADATA
  category: governance
  domain: docs
  tags: docs, sync, validation, metadata
  safe-to-auto-run: true
  related-docs:
    - Rules/DOCS_INDEX.yaml
    - Rules/RULES_MASTER.md

.PARAMETER Action
  Azione da eseguire: check, validate, report, sync

.PARAMETER Scope
  Scope del check: all, ado, wiki, governance

.PARAMETER Path
  Path specifico file da validare

.PARAMETER ChangedFile
  File cambiato che ha triggered il sync

.PARAMETER Format
  Formato output report: console, markdown, json

.EXAMPLE
  pwsh agent-docs-sync.ps1 -Action check
  Check allineamento completo

.EXAMPLE
  pwsh agent-docs-sync.ps1 -Action validate -Path Rules/ADO_EXPORT_GUIDE.md
  Valida singolo file

.EXAMPLE
  pwsh agent-docs-sync.ps1 -Action report -Format markdown
  Report in markdown
#>

Param(
    [ValidateSet('check', 'validate', 'report', 'sync')]
    [string]$Action = 'check',
    
    [ValidateSet('all', 'ado', 'wiki', 'governance', 'tools')]
    [string]$Scope = 'all',
    
    [string]$Path,
    [string]$ChangedFile,
    
    [ValidateSet('console', 'markdown', 'json')]
    [string]$Format = 'console'
)

$ErrorActionPreference = 'Stop'
$rootDir = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$agentDir = Join-Path $rootDir "Rules.Vault\agents\agent_docs_sync"

# Import helpers
. "$agentDir\parse-metadata.ps1"
. "$agentDir\validate-cross-refs.ps1"

Write-Host "==> Agent Docs Sync - Action: $Action" -ForegroundColor Cyan

switch ($Action) {
    'check' {
        Write-Host "Checking documentation alignment (scope: $Scope)..." -ForegroundColor Yellow
        
        # Get all docs and scripts based on scope
        $docs = @()
        $scripts = @()
        
        if ($Scope -eq 'all' -or $Scope -eq 'ado') {
            $docs += Get-ChildItem "$rootDir\Rules" -Filter "*ADO*.md" -ErrorAction SilentlyContinue
            $scripts += Get-ChildItem "$rootDir\Rules.Vault\scripts\ps" -Filter "*ado*.ps1" -ErrorAction SilentlyContinue
        }
        
        if ($Scope -eq 'all' -or $Scope -eq 'wiki') {
            $docs += Get-ChildItem "$rootDir\Rules" -Filter "*WIKI*.md" -ErrorAction SilentlyContinue
            $scripts += Get-ChildItem "$rootDir\Rules.Vault\agents\agent_docs_review" -Filter "*.ps1" -ErrorAction SilentlyContinue
        }
        
        if ($Scope -eq 'all') {
            $docs += Get-ChildItem "$rootDir\Rules" -Filter "*.md" -ErrorAction SilentlyContinue
        }
        
        $misalignments = 0
        $checked = 0
        
        foreach ($doc in $docs) {
            $docMeta = Get-MarkdownMetadata $doc.FullName
            if ($docMeta.'script-refs') {
                foreach ($scriptRef in $docMeta.'script-refs') {
                    $scriptPath = Get-ChildItem $rootDir -Filter $scriptRef -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($scriptPath) {
                        $alignment = Test-DocScriptAlignment -DocPath $doc.FullName -ScriptPath $scriptPath.FullName
                        $checked++
                        if (-not $alignment.Aligned) {
                            $misalignments++
                            Write-Host "  ❌ Misaligned: $($doc.Name) ↔ $($scriptPath.Name)" -ForegroundColor Red
                            $alignment.Issues | ForEach-Object { Write-Host "     - $_" -ForegroundColor Gray }
                        }
                        else {
                            Write-Host "  ✅ Aligned: $($doc.Name) ↔ $($scriptPath.Name)" -ForegroundColor Green
                        }
                    }
                }
            }
        }
        
        Write-Host "`n==> Check Complete" -ForegroundColor Cyan
        Write-Host "  Checked: $checked pairs" -ForegroundColor White
        Write-Host "  Misalignments: $misalignments" -ForegroundColor $(if ($misalignments -eq 0) { 'Green' } else { 'Yellow' })
        
        if ($misalignments -gt 0) {
            Write-Host "`n💡 Run 'docs:sync' to fix misalignments" -ForegroundColor Cyan
        }
    }
    
    'validate' {
        Write-Host "Validating metadata..." -ForegroundColor Yellow
        
        $files = if ($Path) { 
            @(Get-Item $Path) 
        }
        else { 
            Get-ChildItem "$rootDir\Rules" -Filter "*.md" -ErrorAction SilentlyContinue
        }
        
        $errors = 0
        foreach ($file in $files) {
            $meta = Get-MarkdownMetadata $file.FullName
            
            # Validate required fields
            $required = @('category', 'domain', 'tags')
            foreach ($field in $required) {
                if (-not $meta.$field) {
                    Write-Host "  ❌ Missing $field in $($file.Name)" -ForegroundColor Red
                    $errors++
                }
            }
            
            # Validate category values
            $validCategories = @('core', 'ado', 'wiki', 'governance', 'tools', 'troubleshoot')
            if ($meta.category -and $meta.category -notin $validCategories) {
                Write-Host "  ⚠️  Invalid category '$($meta.category)' in $($file.Name)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`n==> Validation Complete" -ForegroundColor Cyan
        Write-Host "  Files: $($files.Count)" -ForegroundColor White
        Write-Host "  Errors: $errors" -ForegroundColor $(if ($errors -eq 0) { 'Green' } else { 'Red' })
    }
    
    'report' {
        Write-Host "Generating documentation report..." -ForegroundColor Yellow
        
        # TODO: Implement full report
        Write-Host "  Report format: $Format" -ForegroundColor Gray
        Write-Host "  ℹ️  Full report implementation coming soon" -ForegroundColor Cyan
    }
    
    'sync' {
        Write-Host "Syncing documentation..." -ForegroundColor Yellow
        
        if ($ChangedFile) {
            Write-Host "  Changed file: $ChangedFile" -ForegroundColor Gray
        }
        
        Write-Host "  ℹ️  Sync implementation coming soon" -ForegroundColor Cyan
        Write-Host "  Will generate PR with suggested doc updates" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Done`n" -ForegroundColor Green
