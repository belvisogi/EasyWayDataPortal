$RootPath = Get-Location
$TempDir = Join-Path $env:TEMP "easyway-test-deploy"
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

$AppsSource = "$RootPath\apps"
Write-Host "Scanning $AppsSource..."

$Files = Get-ChildItem $AppsSource -Recurse | Where-Object { 
    $_.FullName -notmatch "node_modules|dist|\.git|tests|coverage"
}

Write-Host "Found $($Files.Count) items."

$Files | ForEach-Object {
    $RelativePath = [System.IO.Path]::GetRelativePath($RootPath.Path, $_.FullName)
    # Write-Host "Copying: $RelativePath"
    $Dest = Join-Path $TempDir $RelativePath
    
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    }
    else {
        Copy-Item $_.FullName -Destination $Dest -Force
    }
}

Write-Host "Total Size in Temp: $(Get-ChildItem $TempDir -Recurse | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum) bytes"
