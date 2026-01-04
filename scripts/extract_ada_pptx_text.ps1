param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$PptxPath = $null,
  [string]$OutFile = 'ADA_Reference_Architecture_text.txt'
)

$ErrorActionPreference = 'Stop'

if (-not $PptxPath) { $PptxPath = Join-Path $RepoRoot 'ADA Reference Architecture.pptx' }
$outPath = Join-Path $RepoRoot $OutFile

if (-not (Test-Path -LiteralPath $PptxPath)) {
  throw "PPTX not found: $PptxPath"
}

$ppt = New-Object -ComObject PowerPoint.Application
try {
  $pres = $ppt.Presentations.Open($PptxPath, $false, $false, $false)
  $sbs = New-Object System.Text.StringBuilder
  foreach ($s in $pres.Slides) {
    $sbs.AppendLine("---- Slide $($s.SlideNumber) ----") | Out-Null
    foreach ($sh in $s.Shapes) {
      if ($sh -and $sh.HasTextFrame -eq $true -and $sh.TextFrame.HasText -eq $true) {
        $text = $sh.TextFrame.TextRange.Text
        $sbs.AppendLine($text) | Out-Null
      }
    }
  }
  [System.IO.File]::WriteAllText($outPath, $sbs.ToString())
} finally {
  if ($pres) { $pres.Close() }
  if ($ppt) { $ppt.Quit() }
}

Write-Output "Extraction complete. Output file: $outPath"
