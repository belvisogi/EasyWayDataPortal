$ErrorActionPreference = 'Stop'
$path = "C:\Users\EBELVIGLS\OneDrive - NTT DATA EMEAL\Documents\EasyWayDataPortal\ADA Reference Architecture.pptx"
$out = "ADA_Reference_Architecture_text.txt"
$ppt = New-Object -ComObject PowerPoint.Application
try {
    $pres = $ppt.Presentations.Open($path, $false, $false, $false)
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
    $outPath = Join-Path (Get-Location) $out
    [System.IO.File]::WriteAllText($outPath, $sbs.ToString())
} finally {
    if ($pres) { $pres.Close() }
    if ($ppt) { $ppt.Quit() }
}
Write-Output "Extraction complete. Output file: $out"
