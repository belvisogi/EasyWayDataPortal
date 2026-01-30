<#
.SYNOPSIS
    Deploys N8N workflows from a Git repository (Source Folder) to the running Docker Appliance.
.DESCRIPTION
    Iterates through all .json files in the SourcePath, copies them to the container, and imports them via CLI.
.EXAMPLE
    .\deploy-n8n-workflows.ps1 -SourcePath "C:\old\Work-space-n8n"
#>

param (
    [string]$SourcePath = "..\Work-space-n8n",
    [string]$ContainerName = "easyway-orchestrator"
)

$ErrorActionPreference = "Stop"

Write-Host "🏭 N8N GitOps Deployer starting..." -ForegroundColor Cyan

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path '$SourcePath' does not exist."
}

# 1. Get all workflow JSONs
$workflows = Get-ChildItem -Path $SourcePath -Filter "*.json" -Recurse

if ($workflows.Count -eq 0) {
    Write-Warning "No .json workflows found in $SourcePath."
    exit
}

Write-Host "Found $($workflows.Count) workflows to deploy." -ForegroundColor Yellow

foreach ($wf in $workflows) {
    $wfName = $wf.Name
    $wfFullPath = $wf.FullName
    $targetPath = "/home/node/workflows/$wfName"
    
    Write-Host "   Deploying '$wfName'..." -NoNewline

    try {
        # Copy file to container (using pipe to docker exec is tricky on Windows, simpler to cp)
        # Verify container exists
        docker ps -q -f name=$ContainerName | Out-Null
        
        # We use 'docker cp' to push the file
        docker cp "$wfFullPath" "$ContainerName`:$targetPath"
        
        # Import command
        # n8n import:workflow --input=/home/node/workflows/filename.json
        $cmd = "n8n import:workflow --input=$targetPath"
        docker exec -u node $ContainerName $cmd | Out-Null
        
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

Write-Host "✅ Deployment Complete." -ForegroundColor Cyan
