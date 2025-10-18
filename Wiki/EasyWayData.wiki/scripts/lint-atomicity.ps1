[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

if (-not $ReportPath) {
  $ts = (Get-Date).ToString('yyyyMMddHHmmss')
  $ReportPath = Join-Path $Root ("logs/reports/atomicity-${ts}.md")
}

function Has-FrontMatterKeys {
  param([string]$Text)
  if ($Text -notmatch '(?s)^---\s*\n.*?\n---\s*\n') { return $false }
  $needed = @('id:','title:','summary:','owner:','tags:','llm:','entities:')
  foreach($k in $needed){ if ($Text -notmatch [regex]::Escape($k)) { return $false } }
  return $true
}

function Has-QA {
  param([string]$Text)
  return ($Text -match '(?m)^##\s+Domande a cui risponde\s*$')
}

function QA-Count {
  param([string]$Text)
  $lines = $Text -split "\r?\n"
  $hit = $lines | Select-String -SimpleMatch '## Domande a cui risponde' | Select-Object -First 1
  if (-not $hit) { return 0 }
  $start = $hit.LineNumber
  $count = 0
  for($i=$start; $i -lt $lines.Count; $i++){
    $line = $lines[$i]
    if ($i -ne $start -and $line -match '^#'){ break }
    if ($line -match '^\s*[-*]\s+.+$'){ $count++ }
  }
  return $count
}

function CodeFences-Checks {
  param([string]$Text, [string[]]$Allowed)
  $missing = New-Object System.Collections.Generic.List[int]
  $bad = New-Object System.Collections.Generic.List[string]
  $lines = $Text -split "\r?\n"
  $inFence = $false
  for($i=0; $i -lt $lines.Count; $i++){
    $l = $lines[$i]
    if ($l -match '^```(.*)$'){
      $rest = $Matches[1].Trim()
      if (-not $inFence){
        # opening fence
        if (-not $rest){ $missing.Add($i+1) | Out-Null }
        elseif ($Allowed -and ($rest -notin $Allowed)){ $bad.Add(("{0}:{1}" -f ($i+1), $rest)) | Out-Null }
        $inFence = $true
      } else {
        # closing fence: ignore language check
        $inFence = $false
      }
    }
  }
  return @{ missing = $missing; bad = $bad }
}

$rows = New-Object System.Collections.Generic.List[object]
$files = Get-ChildItem -Path $Root -Recurse -File -Filter *.md
foreach($f in $files){
  if ($f.FullName -match '\\logs\\reports\\' -or $f.FullName -match '\\.attachments\\') { continue }
  $rel = [System.IO.Path]::GetRelativePath($Root, $f.FullName) -replace '\\','/'
  $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $fm = Has-FrontMatterKeys -Text $text
  $qa = Has-QA -Text $text
  $qaCount = QA-Count -Text $text
  $allowed = @('sql','sh','bash','powershell','json','text','js','ts','tsx','typescript','python','yaml','yml')
  $cf = CodeFences-Checks -Text $text -Allowed $allowed
  # Whitelist Q&A/front matter for index/log files
  if ($rel -match '^(INDEX\.md|EasyWay_WebApp/.+/index\.md)$') { $qa = $true }
  if ($rel -eq 'ACTIVITY_LOG.md') { $qa = $true }
  # Allow missing front matter for generated indices
  if ($rel -match '^(INDEX\.md|EasyWay_WebApp/.+/index\.md)$') { $fm = $true }
  $hasMissing = ($cf.missing -and $cf.missing.Count -gt 0)
  $hasBad = ($cf.bad -and $cf.bad.Count -gt 0)
  $qaMinOk = ($qaCount -ge 3)
  if (-not $fm -or -not $qa -or -not $qaMinOk -or $hasMissing -or $hasBad){
    $rows.Add([pscustomobject]@{
      path = $f.FullName
      front_matter = $fm
      qa_section = $qa
      qa_count = $qaCount
      qa_min_ok = $qaMinOk
      code_fences_missing_lang = ($(if($cf.missing){ ($cf.missing -join ';') } else { '' }))
      code_fences_bad_lang = ($(if($cf.bad){ ($cf.bad -join ';') } else { '' }))
    }) | Out-Null
  }
}

$sb = New-Object System.Text.StringBuilder
if ($rows.Count -eq 0){
  $null = $sb.AppendLine('# Atomicity Lint')
  $null = $sb.AppendLine()
  $null = $sb.AppendLine('Nessun problema trovato.')
} else {
  $null = $sb.AppendLine('# Atomicity Lint')
  $null = $sb.AppendLine()
  $null = $sb.AppendLine('| path | front_matter | qa_section | qa_count | qa_min_ok | code_fences_missing_lang | code_fences_bad_lang |')
  $null = $sb.AppendLine('|---|---|---|---|---|---|---|')
  foreach($r in $rows){
    $rel = [System.IO.Path]::GetRelativePath($Root, $r.path) -replace '\\','/'
    $null = $sb.AppendLine("| $rel | $($r.front_matter) | $($r.qa_section) | $($r.qa_count) | $($r.qa_min_ok) | $($r.code_fences_missing_lang) | $($r.code_fences_bad_lang) |")
  }
}

New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($ReportPath)) | Out-Null
Set-Content -LiteralPath $ReportPath -Value $sb.ToString() -Encoding UTF8
Write-Host "Generato: $ReportPath"
