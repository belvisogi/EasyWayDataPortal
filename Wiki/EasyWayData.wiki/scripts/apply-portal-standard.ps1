<#!
.SYNOPSIS
  Apply standard sections (Scopo, Schema/DDL, Vincoli/Indici, Esempi Query, Q&A, Collegamenti)
  to PORTAL docs under 01b_schema_structure, preserving existing content.

.DESCRIPTION
  Iterates all .md files under the PORTAL folder and appends missing standard sections
  as placeholders. Does NOT overwrite existing sections. Optionally dry-runs.

.PARAMETER Root
  Base folder for PORTAL (default: EasyWayData.wiki/.../PORTAL)

.PARAMETER WhatIf
  Preview changes without writing.

.EXAMPLE
  ./apply-portal-standard.ps1

.EXAMPLE
  ./apply-portal-standard.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Root = 'EasyWayData.wiki/EasyWay_WebApp/01_database_architecture/01b_schema_structure/PORTAL'
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

function Ensure-Section {
  param(
    [string]$Body,
    [string]$Header,
    [string]$Block
  )
  if ($Body -notmatch "(?m)^##\s*" + [regex]::Escape($Header)) {
    return ($Body.TrimEnd() + "`n`n## $Header`n" + $Block.Trim() + "`n")
  }
  return $Body
}

function Process-File {
  param([string]$Path)
  $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $fmEnd = 0
  if ($content -match '(?s)^---\s*\n(.*?)\n---\s*\n') { $fmEnd = $Matches[0].Length }
  $head = if ($fmEnd -gt 0) { $content.Substring(0,$fmEnd) } else { '' }
  $body = if ($fmEnd -gt 0) { $content.Substring($fmEnd) } else { $content }

  $body = Ensure-Section $body 'Scopo' @"
Breve descrizione dello scopo del documento.
"@
  $body = Ensure-Section $body 'Schema/DDL' @"
<!-- Inserire DDL idempotente (IF NOT EXISTS ... CREATE ...) -->
```sql
-- Esempio DDL idempotente
```
"@
  $body = Ensure-Section $body 'Vincoli e Indici' @"
<!-- Elencare PK, FK, IDX, CHECK, DEFAULT -->
"@
  $body = Ensure-Section $body 'Esempi Query' @"
```sql
-- SELECT ... FROM ...
```
"@
  $body = Ensure-Section $body 'Domande a cui risponde' @"
- Cosa fa?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?
"@
  $body = Ensure-Section $body 'Collegamenti' @"
- [Entities Index](../../../../entities-index.md)
"@

  $new = if ($head) { $head + $body } else { $body }
  if ($new -ne $content) {
    if ($PSCmdlet.ShouldProcess($Path, 'Apply standard sections')) {
      Set-Content -LiteralPath $Path -Value $new -Encoding UTF8
      Write-Host "Updated: $Path"
    }
  }
}

if (!(Test-Path -LiteralPath $Root)) { Write-Warning "PORTAL root not found: $Root"; exit }
Get-ChildItem -Path $Root -Recurse -File -Filter *.md | ForEach-Object { Process-File -Path $_.FullName }
Write-Host 'Done.'

