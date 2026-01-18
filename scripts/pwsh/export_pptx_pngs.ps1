param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$PptxPath = $null,
  [string]$OutDir = $null
)

$ErrorActionPreference = 'Stop'

if (-not $PptxPath) { $PptxPath = Join-Path $RepoRoot 'ADA Reference Architecture.pptx' }
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'ADA_PPTX_PNG' }

if (-not (Test-Path -LiteralPath $PptxPath)) {
  throw "PPTX not found: $PptxPath"
}

if (-not (Test-Path -LiteralPath $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$ppt = New-Object -ComObject PowerPoint.Application
# Attempt to run PowerPoint without showing UI and suppress alerts; add logging to help diagnose hangs.
try {
  # Try to make the COM instance invisible and suppress alerts (some properties may not be available on all setups)
  try { $ppt.Visible = $false } catch {}
  try { $ppt.DisplayAlerts = 0 } catch {}

  Write-Output "Opening presentation: $PptxPath"
  $pres = $ppt.Presentations.Open($PptxPath, $false, $false, $false)
  Write-Output "Presentation opened. Slide count: $($pres.Slides.Count)"

  foreach ($s in $pres.Slides) {
    $file = Join-Path $OutDir ("slide_{0}.png" -f $s.SlideNumber)
    Write-Output "Exporting slide $($s.SlideNumber) -> $file"
    $s.Export($file, 'PNG', 1280, 720) | Out-Null
  }

  Write-Output "Export complete. Files in: $OutDir"
} catch {
  Write-Error "Error during export: $_"
} finally {
  if ($pres) { 
    try { $pres.Close() } catch {}
  }
  if ($ppt) { 
    try { $ppt.Quit() } catch {}
  }
}
