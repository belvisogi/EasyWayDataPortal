<#!
.SYNOPSIS
  Reusable helpers for reviewing and maintaining the EasyWay wiki.

.DESCRIPTION
  Collection of PowerShell functions used to:
  - Check kebab-case/snake_case compliance (slug/file/path)
  - Add minimal front matter if missing
  - Bulk update markdown links from a mapping
  - Extract headings H1–H3 to bootstrap indices
  - Rename files/folders from a mapping (with -WhatIf)
  - Append activity entries using scripts/add-log.ps1
  - Generate a simple INDEX.md for a folder

.NOTES
  Keep this file updated. When new review snippets are created or improved,
  add them here so we always have a single entrypoint.

.EXAMPLE
  # List non-conforming names under the wiki
  Get-NameCompliance -Root 'EasyWayData.wiki' -Mode kebab | Out-Host

.EXAMPLE
  # Add front matter to a page if missing
  Add-FrontMatterIfMissing -Path 'EasyWayData.wiki/README.md' -Id 'ew-readme' -Title 'Readme' -Tags 'layer/how-to'

.EXAMPLE
  # Update links repo-wide from a hashtable
  $map = @{ 'old-name.md'='new-name.md' }
  Update-MdLinks -Root 'EasyWayData.wiki' -Map $map

.EXAMPLE
  # Rename items from a mapping (safely try with -WhatIf first)
  $ren = @(
    @{ old='a/old.md'; new='a/new.md' },
    @{ old='b/Old%2DDir'; new='b/old-dir' }
  )
  Rename-ItemsFromMap -Map $ren -WhatIf

.EXAMPLE
  # Log an action to master and monthly split
  Write-Activity -Type 'LINT' -Scope 'wiki' -Status 'success' -Owner 'team-docs' -Message 'Naming check eseguito' -Split monthly
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

function Get-NameCompliance {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [ValidateSet('kebab','snake','both')][string]$Mode = 'kebab',
    [string[]]$Extensions = @('md','yml','yaml','json','sql','ps1')
  )
  $slugRxK = '^[a-z0-9]+(?:-[a-z0-9]+)*$'
  $fileRxK = '^[a-z0-9]+(?:-[a-z0-9]+)*\.(EXT)$'
  $pathRxK = '^(?:[a-z0-9]+(?:-[a-z0-9]+)*/)*[a-z0-9]+(?:-[a-z0-9]+)*\.(EXT)$'
  $slugRxS = '^[a-z0-9]+(?:_[a-z0-9]+)*$'
  $fileRxS = '^[a-z0-9]+(?:_[a-z0-9]+)*\.(EXT)$'
  $pathRxS = '^(?:[a-z0-9]+(?:_[a-z0-9]+)*/)*[a-z0-9]+(?:_[a-z0-9]+)*\.(EXT)$'
  $extGroup = '?:' + ($Extensions -join '|')
  $fileRxK = $fileRxK -replace 'EXT', $extGroup
  $pathRxK = $pathRxK -replace 'EXT', $extGroup
  $fileRxS = $fileRxS -replace 'EXT', $extGroup
  $pathRxS = $pathRxS -replace 'EXT', $extGroup

  Get-ChildItem -Path $Root -Recurse -File | ForEach-Object {
    $name = $_.Name
    $slug = [IO.Path]::GetFileNameWithoutExtension($name)
    $path = ($_.FullName -replace '\\','/')
    $rel = ($path -replace '^.+?/EasyWayData\.wiki/','')
    # Whitelist/exclusions
    $ext = ([IO.Path]::GetExtension($name)).TrimStart('.')
    if ($Extensions -and ($Extensions -notcontains $ext)) { return }
    if ($name -eq '.gitignore') { return }
    if ($name -eq '.order') { return }
    if ($rel -like '.attachments/*') { return }
    if ($rel -match '^EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/STEP-') { return }
    if ($rel -in @('ACTIVITY_LOG.md','DOCS_CONVENTIONS.md','LLM_READINESS_CHECKLIST.md','TODO_CHECKLIST.md','INDEX.md')) { return }
    $issues = [System.Collections.Generic.List[string]]::new()
    if ($name -cmatch '[A-Z]') { $issues.Add('uppercase') }
    if ($name -match '%[0-9A-Fa-f]{2}') { $issues.Add('percent-encoded') }
    if ($name -match '[`"\'']') { $issues.Add('quotes/backticks') }
    if ($name -match '�') { $issues.Add('encoding-char') }
    if ($Mode -in @('kebab','both')) {
      if ($slug -notmatch $slugRxK) { $issues.Add('slug(kebab)') }
      if ($name -notmatch $fileRxK) { $issues.Add('file(kebab)') }
      $checkPath = $true
      if ($rel -match '^(EasyWay_WebApp|01_database_architecture|01b_schema_structure)/') { $checkPath = $false }
      if ($checkPath -and $rel -notmatch $pathRxK) { $issues.Add('path(kebab)') }
    }
    if ($Mode -in @('snake','both')) {
      if ($slug -notmatch $slugRxS) { $issues.Add('slug(snake)') }
      if ($name -notmatch $fileRxS) { $issues.Add('file(snake)') }
      $checkPathS = $true
      if ($rel -match '^(EasyWay_WebApp|01_database_architecture|01b_schema_structure)/') { $checkPathS = $false }
      if ($checkPathS -and $rel -notmatch $pathRxS) { $issues.Add('path(snake)') }
    }
    if ($issues.Count) { [pscustomobject]@{ Path=$path; Issues=$issues -join ',' } }
  }
}

function Add-FrontMatterIfMissing {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Id,
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Tags,
    [string]$Owner = 'team-docs',
    [string]$Summary = 'Breve descrizione del documento.'
  )
  if (!(Test-Path -LiteralPath $Path)) { return }
  $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ($content -match '(?s)^---\s*\n') { return }
  $fm = @(
    '---',
    "id: $Id",
    "title: $Title",
    "summary: $Summary",
    'status: draft',
    "owner: $Owner",
    "created: '2025-01-01'",
    "updated: '2025-01-01'",
    'tags:',
    "  - $Tags",
    '  - privacy/internal',
    '  - language/it',
    'llm:',
    '  include: true',
    '  pii: none',
    '  chunk_hint: 400-600',
    '  redaction: [email, phone]',
    'entities: []',
    '---',
    ''
  ) -join "`n"
  Set-Content -LiteralPath $Path -Value ($fm + $content) -Encoding UTF8
}

function Update-MdLinks {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][hashtable]$Map
  )
  Get-ChildItem -Path $Root -Recurse -File -Filter *.md | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    $orig = $c
    foreach($k in $Map.Keys){ $c = $c -replace [regex]::Escape($k), $Map[$k] }
    if($c -ne $orig){ Set-Content -LiteralPath $_.FullName -Value $c -NoNewline -Encoding UTF8 }
  }
}

function Rename-ItemsFromMap {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory=$true)]$Map # array of @{old=''; new=''} or path to CSV with old,new
  )
  $rows = @()
  if ($Map -is [string]) {
    $rows = Import-Csv -Path $Map
  } elseif ($Map -is [System.Collections.IEnumerable]) {
    $rows = $Map
  } else { throw 'Map must be CSV path or array of @{old=;new=}' }
  foreach($m in $rows){
    $old = $m.old; $new = $m.new
    if (Test-Path -LiteralPath $old) {
      if ($PSCmdlet.ShouldProcess($old, "Move to $new")) {
        $dir = Split-Path -Parent $new
        if ($dir -and !(Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        Move-Item -LiteralPath $old -Destination $new -Force
      }
    }
  }
}

function Get-MdHeadings {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [int[]]$Levels = @(1,2,3)
  )
  $rx = '^(' + (($Levels | ForEach-Object { '#' * $_ }) -join '|') + ')\s+'
  Get-ChildItem -Path $Root -Recurse -File -Filter *.md | ForEach-Object {
    $rel = (Resolve-Path -Relative $_.FullName)
    Get-Content -LiteralPath $_.FullName -Encoding UTF8 | Where-Object { $_ -match $rx } | ForEach-Object {
      '{0}`t{1}' -f $rel, $_
    }
  }
}

function Write-Activity {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Type,
    [Parameter(Mandatory=$true)][string]$Scope,
    [Parameter(Mandatory=$true)][ValidateSet('success','warn','error')][string]$Status,
    [Parameter(Mandatory=$true)][string]$Owner,
    [Parameter(Mandatory=$true)][string]$Message,
    [ValidateSet('none','monthly','scope')][string]$Split = 'none',
    [bool]$MirrorToMaster = $true
  )
  $script = Join-Path $PSScriptRoot 'add-log.ps1'
  & $script -Type $Type -Scope $Scope -Status $Status -Owner $Owner -Message $Message -Split $Split -MirrorToMaster:$MirrorToMaster | Out-Host
}

function New-FolderIndex {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Folder,
    [string]$Output = 'index.md'
  )
  $items = Get-ChildItem -LiteralPath $Folder -File -Filter *.md | Sort-Object Name
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('# Indice') | Out-Null
  foreach($f in $items){
    if ($f.Name -match '^STEP-') { continue }
    $h1 = (Select-String -Path $f.FullName -Pattern '^[#]+\s+(.+)$' -Encoding utf8 -List | Select-Object -First 1)
    $title = if ($h1) { $h1.Matches[0].Groups[1].Value } else { [IO.Path]::GetFileNameWithoutExtension($f.Name) }
    $lines.Add("- [$($f.Name)](./$($f.Name)) - $title") | Out-Null
  }
  Set-Content -LiteralPath (Join-Path $Folder $Output) -Value ($lines -join "`n") -Encoding UTF8
}

function New-RootIndex {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [string]$Output = (Join-Path $Root 'INDEX.md')
  )
  $mds = Get-ChildItem -Path $Root -Recurse -File -Filter *.md | Sort-Object FullName
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('# Indice Globale') | Out-Null
  $lines.Add('') | Out-Null
  foreach($f in $mds){
    if ($f.Name -match '^STEP-') { continue }
    $relFull = $f.FullName
    $href = [System.IO.Path]::GetRelativePath($Root, $relFull) -replace '\\','/'
    $h1 = (Select-String -Path $f.FullName -Pattern '^[#]+\s+(.+)$' -Encoding utf8 -List | Select-Object -First 1)
    $title = if ($h1) { $h1.Matches[0].Groups[1].Value } else { [IO.Path]::GetFileNameWithoutExtension($f.Name) }
    $lines.Add("- [$href](./$href) - $title") | Out-Null
    # Extract up to first 3 H2 headings for quick glance
    $h2s = Select-String -Path $f.FullName -Pattern '^##\s+(.+)$' -Encoding utf8 | Select-Object -First 3
    foreach($h2 in $h2s){
      $h2title = $h2.Matches[0].Groups[1].Value
      $lines.Add("  - H2: $h2title") | Out-Null
    }
  }
  Set-Content -LiteralPath $Output -Value ($lines -join "`n") -Encoding UTF8
}

Write-Verbose 'review-examples.ps1 loaded.'

function Get-AnchorIssues {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Root
  )
  function Slug([string]$t){
    if ($null -eq $t) { return '' }
    $s = $t.ToLower()
    $s = $s -replace "[`*_~]", ''
    $s = $s -replace "\s+", '-'
    $s = $s -replace "[^a-z0-9\-]", ''
    $s = $s -replace "-+", '-'
    $s = $s -replace "^-|-$", ''
    return $s
  }
  function Headings([string]$file){
    $heads = @{}
    Get-Content -LiteralPath $file -Encoding UTF8 | ForEach-Object {
      if ($_ -match '^(#+)\s+(.+)$'){
        $slug = Slug $Matches[2]
        if ($slug){ $heads[$slug] = $true }
      }
    }
    return $heads
  }
  $files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md
  $issues = New-Object System.Collections.Generic.List[object]
  foreach($f in $files){
    $dir = Split-Path -Parent $f.FullName
    $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    $matches = [regex]::Matches($content, "\[[^\]]*\]\(([^\)]+)\)")
    foreach($m in $matches){
      $raw = $m.Groups[1].Value.Trim()
      if ($raw -match '^(https?:|mailto:|data:|#)'){ # external or local-only anchor handled below
        if ($raw.StartsWith('#')){
          $anc = $raw.Substring(1)
          $slug = Slug $anc
          $heads = Headings $f.FullName
          if (-not $heads.ContainsKey($slug)){
            $issues.Add([pscustomobject]@{ File=(Resolve-Path -Relative $f.FullName); Link=$raw; Issue='missing-local-anchor' })
          }
        }
        continue
      }
      $target = $raw
      $anchor = $null
      if ($target.Contains('#')){ $anchor = $target.Substring($target.IndexOf('#')+1); $target = $target.Substring(0, $target.IndexOf('#')) }
      $tpath = if ([IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $dir $target }
      if (-not (Test-Path -LiteralPath $tpath)){
        $issues.Add([pscustomobject]@{ File=(Resolve-Path -Relative $f.FullName); Link=$raw; Issue='missing-file' })
        continue
      }
      if ($anchor){
        $slug = Slug $anchor
        $heads = Headings $tpath
        if (-not $heads.ContainsKey($slug)){
          $issues.Add([pscustomobject]@{ File=(Resolve-Path -Relative $f.FullName); Link=$raw; Issue='missing-anchor' })
        }
      }
    }
  }
  return $issues
}
