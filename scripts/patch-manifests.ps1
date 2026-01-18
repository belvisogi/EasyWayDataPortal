
$docsSyncManifest = "agents/agent_docs_sync/manifest.json"
if (Test-Path $docsSyncManifest) {
    $content = Get-Content $docsSyncManifest -Raw
    # Fix scripts/ps -> scripts/pwsh
    $newContent = $content -replace 'scripts/ps/', 'scripts/pwsh/'
    if ($content -ne $newContent) {
        Set-Content -Path $docsSyncManifest -Value $newContent -Encoding UTF8
        Write-Host "Fixed agent_docs_sync manifest." -ForegroundColor Green
    }
}

$synapseManifest = "agents/agent_synapse/manifest.json"
if (Test-Path $synapseManifest) {
    $content = Get-Content $synapseManifest -Raw
    # Fix actions/scripts/pwsh -> actions/scripts (Revert incorrect regex match)
    $newContent = $content -replace 'actions/scripts/pwsh/', 'actions/scripts/'
    if ($content -ne $newContent) {
        Set-Content -Path $synapseManifest -Value $newContent -Encoding UTF8
        Write-Host "Fixed agent_synapse manifest (Revert local script path)." -ForegroundColor Green
    }
}
