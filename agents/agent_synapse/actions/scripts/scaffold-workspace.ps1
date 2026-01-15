param(
    [string]$TargetDir,
    [switch]$Force
)

# Auto-detect workspace if not provided
if (-not $TargetDir) {
    if (Test-Path "WorkSpaceSynapse") { $TargetDir = (Resolve-Path "WorkSpaceSynapse").Path }
    elseif (Test-Path "../WorkSpaceSynapse") { $TargetDir = (Resolve-Path "../WorkSpaceSynapse").Path }
    else {
        return @{ status = "error"; message = "Cannot find WorkSpaceSynapse directory. Please specify -TargetDir." }
    }
}

if (-not (Test-Path $TargetDir)) {
    return @{ status = "error"; message = "Target directory not found: $TargetDir" }
}

$standardFolders = @("pipelines", "notebooks", "sqlscript", "linkedService", "dataset", "trigger", "managedVirtualNetwork")
$created = @()

foreach ($folder in $standardFolders) {
    $path = Join-Path $TargetDir $folder
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        $created += $folder
    }
}

# Create README if missing
$readmePath = Join-Path $TargetDir "README.md"
if (-not (Test-Path $readmePath)) {
    $content = @"
# Synapse Workspace

This workspace is managed by **Axet Agent_Synapse**.

## Structure
- **pipelines/**: Orchestration pipelines (JSON)
- **notebooks/**: PySpark/Scala notebooks
- **sqlscript/**: Serverless/Dedicated SQL scripts
- **linkedService/**: Connection definitions
- **dataset/**: Data schematics

## Usage
Use `axctl --intent synapse` to manage artifacts.
"@
    Set-Content -Path $readmePath -Value $content
    $created += "README.md"
}

if ($created.Count -eq 0) {
    return @{ status = "ok"; message = "Workspace is already compliant (nothing created)." }
}
else {
    return @{ status = "ok"; message = "Scaffolded: " + ($created -join ", ") }
}
