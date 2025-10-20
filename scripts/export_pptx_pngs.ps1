$ErrorActionPreference = 'Stop'
$pptxPath = 'C:\Users\EBELVIGLS\OneDrive - NTT DATA EMEAL\Documents\EasyWayDataPortal\ADA Reference Architecture.pptx'
$outDir = Join-Path (Get-Location) 'ADA_PPTX_PNG'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$ppt = New-Object -ComObject PowerPoint.Application
# Attempt to run PowerPoint without showing UI and suppress alerts; add logging to help diagnose hangs.
try {
    # Try to make the COM instance invisible and suppress alerts (some properties may not be available on all setups)
    try { $ppt.Visible = $false } catch {}
    try { $ppt.DisplayAlerts = 0 } catch {}

    Write-Output "Opening presentation: $pptxPath"
    $pres = $ppt.Presentations.Open($pptxPath, $false, $false, $false)
    Write-Output "Presentation opened. Slide count: $($pres.Slides.Count)"

    foreach ($s in $pres.Slides) {
        $file = Join-Path $outDir ("slide_{0}.png" -f $s.SlideNumber)
        Write-Output "Exporting slide $($s.SlideNumber) -> $file"
        $s.Export($file, 'PNG', 1280, 720) | Out-Null
    }
    Write-Output "Export complete. Files in: $outDir"
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
