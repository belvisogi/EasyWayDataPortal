<#
.SYNOPSIS
  [DB] Native Database Module.
  Executes Stored Procedures directly via ADO.NET (Zero NPM Dependency).
#>

function Get-SqlConnectionString {
    # Tries to find connection string from env vars or .env.local
    if ($env:DB_CONN_STRING) { return $env:DB_CONN_STRING }
    # Simplified fallback for PoC
    return $null
}

# --- 1. Diagnosis (Check) ---
function Get-EwctlDiagnosis {
    $results = @()
    $connStr = Get-SqlConnectionString

    if (-not $connStr) {
        $results += [PSCustomObject]@{ Status = "Warn"; Message = "No DB Connection String found (Env: DB_CONN_STRING)"; Context = "DB" }
        return $results
    }

    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
        $conn.Open()
        
        # Simple Check: Can we query?
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT 1"
        $res = $cmd.ExecuteScalar()
        
        $conn.Close()
        $results += [PSCustomObject]@{ Status = "Ok"; Message = "DB Connection Healthy"; Context = "DB" }
    }
    catch {
        $results += [PSCustomObject]@{ Status = "Error"; Message = "DB Connection Failed: $($_.Exception.Message)"; Context = "DB" }
    }

    return $results
}

# --- 2. Prescription (Plan) ---
function Get-EwctlPrescription {
    return @()
}

# --- 3. Treatment (Fix) ---
function Invoke-EwctlTreatment {
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    $report = @()
    $connStr = Get-SqlConnectionString
    
    if (-not $connStr) { Write-Error "No DB Connection"; return $report }

    # Example: Execute a theoretical 'sp_Maintenance_FixAll'
    # In a real scenario, we might map specific issues to specific SPs.
    if ($PSCmdlet.ShouldProcess("Database", "EXEC sp_Maintenance_FixAll")) {
        try {
            $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
            $conn.Open()
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "EXEC sp_Maintenance_FixAll" # Hypothetical fix SP
            # $cmd.ExecuteNonQuery() # Commmented out for safety in this demo
            $conn.Close()
            $report += "Executed sp_Maintenance_FixAll (Simulated)"
        }
        catch {
            $report += "Failed to execute SP: $($_.Exception.Message)"
        }
    }
    return $report
}

Export-ModuleMember -Function Get-EwctlDiagnosis, Get-EwctlPrescription, Invoke-EwctlTreatment
