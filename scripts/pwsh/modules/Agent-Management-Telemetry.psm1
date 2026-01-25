# Agent-Management-Telemetry.psm1
# PowerShell module for agent telemetry and management console integration

<#
.SYNOPSIS
    PowerShell module for tracking agent execution metrics and status
    
.DESCRIPTION
    Provides functions to:
    - Start/stop agent execution tracking
    - Record token consumption and timing
    - Update execution status (TODO → ONGOING → DONE)
    - Send metrics to database
#>

# =====================================================
# CONFIGURATION
# =====================================================
$script:ConnectionString = $null
$script:CurrentExecutionId = $null

function Initialize-AgentTelemetry {
    <#
    .SYNOPSIS
        Initialize telemetry module with database connection
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )
    
    $script:ConnectionString = $ConnectionString
    Write-Verbose "Agent telemetry initialized"
}

function Start-AgentExecution {
    <#
    .SYNOPSIS
        Start tracking a new agent execution
        
    .EXAMPLE
        $execId = Start-AgentExecution -AgentId "agent_gedi" -ActionName "gedi:ooda.loop" -TriggeredBy "user"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $false)]
        [string]$ActionName,
        
        [Parameter(Mandatory = $false)]
        [string]$IntentId,
        
        [Parameter(Mandatory = $false)]
        [string]$TriggeredBy = "system"
    )
    
    if (-not $script:ConnectionString) {
        Write-Warning "Telemetry not initialized. Call Initialize-AgentTelemetry first."
        return $null
    }
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($script:ConnectionString)
        $conn.Open()
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandText = "AGENT_MGMT.sp_start_execution"
        
        $cmd.Parameters.AddWithValue("@AgentId", $AgentId) | Out-Null
        $cmd.Parameters.AddWithValue("@ActionName", [System.DBNull]::Value) | Out-Null
        if ($ActionName) { $cmd.Parameters["@ActionName"].Value = $ActionName }
        
        $cmd.Parameters.AddWithValue("@IntentId", [System.DBNull]::Value) | Out-Null
        if ($IntentId) { $cmd.Parameters["@IntentId"].Value = $IntentId }
        
        $cmd.Parameters.AddWithValue("@TriggeredBy", $TriggeredBy) | Out-Null
        
        $outParam = New-Object System.Data.SqlClient.SqlParameter("@ExecutionId", [System.Data.SqlDbType]::BigInt)
        $outParam.Direction = [System.Data.ParameterDirection]::Output
        $cmd.Parameters.Add($outParam) | Out-Null
        
        $cmd.ExecuteNonQuery() | Out-Null
        
        $script:CurrentExecutionId = $outParam.Value
        
        $conn.Close()
        
        Write-Verbose "Started execution $script:CurrentExecutionId for agent $AgentId"
        return $script:CurrentExecutionId
    }
    catch {
        Write-Error "Failed to start execution: $_"
        return $null
    }
}

function Update-AgentExecutionStatus {
    <#
    .SYNOPSIS
        Update execution status (TODO → ONGOING → DONE/FAILED)
        
    .EXAMPLE
        Update-AgentExecutionStatus -ExecutionId $execId -Status "ONGOING"
        Update-AgentExecutionStatus -ExecutionId $execId -Status "DONE" -TokensConsumed 1500
    #>
    param(
        [Parameter(Mandatory = $false)]
        [long]$ExecutionId = $script:CurrentExecutionId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("TODO", "ONGOING", "DONE", "FAILED", "CANCELLED")]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [string]$StatusMessage,
        
        [Parameter(Mandatory = $false)]
        [int]$TokensConsumed,
        
        [Parameter(Mandatory = $false)]
        [int]$TokensPrompt,
        
        [Parameter(Mandatory = $false)]
        [int]$TokensCompletion,
        
        [Parameter(Mandatory = $false)]
        [int]$ApiCallsCount
    )
    
    if (-not $ExecutionId) {
        Write-Warning "No execution ID provided and no current execution tracked"
        return
    }
    
    if (-not $script:ConnectionString) {
        Write-Warning "Telemetry not initialized"
        return
    }
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($script:ConnectionString)
        $conn.Open()
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandText = "AGENT_MGMT.sp_update_execution_status"
        
        $cmd.Parameters.AddWithValue("@ExecutionId", $ExecutionId) | Out-Null
        $cmd.Parameters.AddWithValue("@Status", $Status) | Out-Null
        
        $cmd.Parameters.AddWithValue("@StatusMessage", [System.DBNull]::Value) | Out-Null
        if ($StatusMessage) { $cmd.Parameters["@StatusMessage"].Value = $StatusMessage }
        
        $cmd.Parameters.AddWithValue("@TokensConsumed", [System.DBNull]::Value) | Out-Null
        if ($TokensConsumed) { $cmd.Parameters["@TokensConsumed"].Value = $TokensConsumed }
        
        $cmd.Parameters.AddWithValue("@TokensPrompt", [System.DBNull]::Value) | Out-Null
        if ($TokensPrompt) { $cmd.Parameters["@TokensPrompt"].Value = $TokensPrompt }
        
        $cmd.Parameters.AddWithValue("@TokensCompletion", [System.DBNull]::Value) | Out-Null
        if ($TokensCompletion) { $cmd.Parameters["@TokensCompletion"].Value = $TokensCompletion }
        
        $cmd.Parameters.AddWithValue("@ApiCallsCount", [System.DBNull]::Value) | Out-Null
        if ($ApiCallsCount) { $cmd.Parameters["@ApiCallsCount"].Value = $ApiCallsCount }
        
        $cmd.ExecuteNonQuery() | Out-Null
        
        $conn.Close()
        
        Write-Verbose "Updated execution $ExecutionId to status $Status"
        
        # Clear current execution if completed
        if ($Status -in @("DONE", "FAILED", "CANCELLED") -and $ExecutionId -eq $script:CurrentExecutionId) {
            $script:CurrentExecutionId = $null
        }
    }
    catch {
        Write-Error "Failed to update execution status: $_"
    }
}

function Invoke-AgentWithTelemetry {
    <#
    .SYNOPSIS
        Wrapper to execute agent script with automatic telemetry
        
    .EXAMPLE
        Invoke-AgentWithTelemetry -AgentId "agent_gedi" -ScriptBlock {
            # Your agent logic here
            Write-Host "Agent executing..."
        }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string]$ActionName,
        
        [Parameter(Mandatory = $false)]
        [string]$IntentId
    )
    
    # Start tracking
    $execId = Start-AgentExecution -AgentId $AgentId -ActionName $ActionName -IntentId $IntentId
    
    if (-not $execId) {
        Write-Warning "Telemetry not available, executing without tracking"
        & $ScriptBlock
        return
    }
    
    try {
        # Update to ONGOING
        Update-AgentExecutionStatus -ExecutionId $execId -Status "ONGOING" -StatusMessage "Agent started"
        
        # Execute agent logic
        $result = & $ScriptBlock
        
        # Update to DONE
        Update-AgentExecutionStatus -ExecutionId $execId -Status "DONE" -StatusMessage "Agent completed successfully"
        
        return $result
    }
    catch {
        # Update to FAILED
        Update-AgentExecutionStatus -ExecutionId $execId -Status "FAILED" -StatusMessage "Error: $_"
        throw
    }
}

function Get-AgentDashboard {
    <#
    .SYNOPSIS
        Get current agent dashboard data
    #>
    param()
    
    if (-not $script:ConnectionString) {
        Write-Warning "Telemetry not initialized"
        return $null
    }
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($script:ConnectionString)
        $conn.Open()
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandText = "AGENT_MGMT.sp_get_agent_dashboard"
        
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        
        $conn.Close()
        
        return $dataset.Tables[0]
    }
    catch {
        Write-Error "Failed to get dashboard: $_"
        return $null
    }
}

function Set-AgentEnabled {
    <#
    .SYNOPSIS
        Enable or disable an agent
        
    .EXAMPLE
        Set-AgentEnabled -AgentId "agent_gedi" -Enabled $true
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AgentId,
        
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )
    
    if (-not $script:ConnectionString) {
        Write-Warning "Telemetry not initialized"
        return
    }
    
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($script:ConnectionString)
        $conn.Open()
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandText = "AGENT_MGMT.sp_toggle_agent_status"
        
        $cmd.Parameters.AddWithValue("@AgentId", $AgentId) | Out-Null
        $cmd.Parameters.AddWithValue("@IsEnabled", $Enabled) | Out-Null
        
        $cmd.ExecuteNonQuery() | Out-Null
        
        $conn.Close()
        
        $status = if ($Enabled) { "enabled" } else { "disabled" }
        Write-Host "✅ Agent $AgentId $status" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to toggle agent status: $_"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-AgentTelemetry',
    'Start-AgentExecution',
    'Update-AgentExecutionStatus',
    'Invoke-AgentWithTelemetry',
    'Get-AgentDashboard',
    'Set-AgentEnabled'
)
