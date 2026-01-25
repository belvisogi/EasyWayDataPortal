# sync-agents-to-db.ps1
# Sync all agent manifests to the management database

param(
    [Parameter(Mandatory = $true)]
    [string]$ConnectionString,
    
    [Parameter(Mandatory = $false)]
    [string]$AgentsPath = "..\..\agents"
)

$ErrorActionPreference = 'Stop'

Write-Host "🔄 Syncing agents to management database..." -ForegroundColor Cyan

# Load configuration
$configPath = Join-Path $PSScriptRoot '..\..\\.config\paths.json'
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $AgentsPath = Join-Path $config.paths.projectRoot 'agents'
}

# Find all manifest files
$manifests = Get-ChildItem -Path $AgentsPath -Filter "manifest.json" -Recurse | Where-Object {
    $_.FullName -notmatch '\\core\\' -and $_.FullName -notmatch '\\memory\\'
}

Write-Host "Found $($manifests.Count) agent manifests" -ForegroundColor Yellow

$conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$conn.Open()

$syncedCount = 0
$errorCount = 0

foreach ($manifestFile in $manifests) {
    try {
        $manifestJson = Get-Content $manifestFile.FullName -Raw
        $manifest = $manifestJson | ConvertFrom-Json
        
        $agentId = $manifest.id
        if (-not $agentId) {
            Write-Warning "Skipping $($manifestFile.FullName) - no agent ID"
            continue
        }
        
        Write-Host "  📦 Syncing $agentId..." -NoNewline
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandText = "AGENT_MGMT.sp_sync_agent_from_manifest"
        
        $cmd.Parameters.AddWithValue("@AgentId", $agentId) | Out-Null
        $cmd.Parameters.AddWithValue("@ManifestJson", $manifestJson) | Out-Null
        
        $cmd.ExecuteNonQuery() | Out-Null
        
        Write-Host " ✅" -ForegroundColor Green
        $syncedCount++
        
        # Sync capabilities
        if ($manifest.capabilities) {
            foreach ($capability in $manifest.capabilities) {
                $capCmd = $conn.CreateCommand()
                $capCmd.CommandText = @"
                    MERGE AGENT_MGMT.agent_capabilities AS target
                    USING (SELECT @AgentId AS agent_id, @CapabilityName AS capability_name) AS source
                    ON target.agent_id = source.agent_id AND target.capability_name = source.capability_name
                    WHEN NOT MATCHED THEN
                        INSERT (agent_id, capability_name)
                        VALUES (@AgentId, @CapabilityName);
"@
                $capCmd.Parameters.AddWithValue("@AgentId", $agentId) | Out-Null
                $capCmd.Parameters.AddWithValue("@CapabilityName", $capability) | Out-Null
                $capCmd.ExecuteNonQuery() | Out-Null
            }
        }
        
        # Sync triggers
        if ($manifest.triggers) {
            foreach ($triggerProp in $manifest.triggers.PSObject.Properties) {
                $triggerName = $triggerProp.Name
                $triggerConfig = $triggerProp.Value
                
                $trigCmd = $conn.CreateCommand()
                $trigCmd.CommandText = @"
                    MERGE AGENT_MGMT.agent_triggers AS target
                    USING (SELECT @AgentId AS agent_id, @TriggerName AS trigger_name) AS source
                    ON target.agent_id = source.agent_id AND target.trigger_name = source.trigger_name
                    WHEN MATCHED THEN
                        UPDATE SET is_enabled = @IsEnabled, trigger_description = @Description
                    WHEN NOT MATCHED THEN
                        INSERT (agent_id, trigger_name, is_enabled, trigger_description)
                        VALUES (@AgentId, @TriggerName, @IsEnabled, @Description);
"@
                $trigCmd.Parameters.AddWithValue("@AgentId", $agentId) | Out-Null
                $trigCmd.Parameters.AddWithValue("@TriggerName", $triggerName) | Out-Null
                $trigCmd.Parameters.AddWithValue("@IsEnabled", [bool]$triggerConfig.enabled) | Out-Null
                $trigCmd.Parameters.AddWithValue("@Description", $triggerConfig.description) | Out-Null
                $trigCmd.ExecuteNonQuery() | Out-Null
            }
        }
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Warning "Error syncing $agentId: $_"
        $errorCount++
    }
}

$conn.Close()

Write-Host ""
Write-Host "✅ Sync complete!" -ForegroundColor Green
Write-Host "   Synced: $syncedCount agents" -ForegroundColor Cyan
if ($errorCount -gt 0) {
    Write-Host "   Errors: $errorCount agents" -ForegroundColor Red
}
